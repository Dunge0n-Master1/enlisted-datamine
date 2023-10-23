module flamethrower_common shared

require ecs
require app
require DngNet
require DngDm
require math.base
require game.es.events
require game.es.riextra_damage_common
require game.events_game
require Dacoll
require Grid
require GridCollision
require CollisionTraces
require AnimV20
require GeomNodeTree
require DagorMath
require DagorMathUtils
require game.es.node_attach_common
require CollRes
require game.utils.team
require DagorRandom
require RendInst
require enlisted.events_enlisted

struct DropletSpread
  yaw : float
  pitchMin : float
  pitchMax : float
  maxLength : float
  normalOffset : float

struct FlameDamage
  offender : EntityId
  offenderTeam : int
  streamDamage : float
  cloudDamage : float
  friendlyStreamDamage : float
  friendlyCloudDamage : float
  shouldSetFriendlyOnFire : bool
  gunPropsId : int = -1

struct FireCastResult
  isHit : bool = false
  isFireCreated : bool = false
  pos : float3 = float3()
  attachedToEid : EntityId = INVALID_ENTITY_ID
  norm : float3

def deal_fire_damage(eid : EntityId; damage : FlameDamage; isStream : bool = true) : bool
  var found = false
  query(eid) <| $ [es] (var burning__isBurning : bool&;
                        var burning__offender : EntityId&;
                        var burning__force : float&;
                        var burning__offenderGunPropsId : int&;
                        burning__maxForce : float;
                        transform : float3x4;
                        team : int = TEAM_UNASSIGNED)
    let friendlyFire = is_teams_friendly(damage.offenderTeam, team)
    if !friendlyFire || damage.shouldSetFriendlyOnFire
      burning__isBurning = true
      burning__force = burning__maxForce
      burning__offender = damage.offender
      burning__offenderGunPropsId = damage.gunPropsId
    let streamDamage = friendlyFire ? damage.friendlyStreamDamage : damage.streamDamage
    let cloudDamage = friendlyFire ? damage.friendlyCloudDamage : damage.cloudDamage
    let dmg = isStream ? streamDamage : cloudDamage
    if dmg > 0.0
      var damageDesc = DamageDesc(DamageType DM_FIRE, dmg, transform[3])
      damageDesc.gunPropsId = int16(damage.gunPropsId)
      damage_entity(eid, damage.offender, damageDesc)
      if friendlyFire
        sendEvent(eid, [[OnFlamethrowerFriendlyFire offender=damage.offender, gunPropsId=damage.gunPropsId]])
    found = true
  return found

def deal_fire_damage_ri(riex_handle : riex_handle_t; pos : float3; damage : FlameDamage; isStream : bool = true)
  if !is_ri_extra_can_be_damaged_by_team(riex_handle, damage.offenderTeam)
    return
  let dmg = isStream ? damage.streamDamage : damage.cloudDamage
  send_net_event(damage.offender, [[RequestRendinstDamage handle=riex_handle, damage=dmg, pos=pos, impulse=float3(), time=get_sync_time()]])

def reignite_if_close(pos_a, pos_b : float3;
                      min_distance_sq : float;
                      var fire_source__startTime : float&;
                      var fire_source__fullForceTime : float&;
                      fire_source__maxFullForceTime : float;
                      fire_source__spreadTime : float;
                      add_fire_time : float)
  if distance_sq(pos_a, pos_b) > min_distance_sq
    return false
  fire_source__fullForceTime = min(fire_source__fullForceTime + add_fire_time, fire_source__maxFullForceTime)
  fire_source__startTime = get_sync_time() - fire_source__spreadTime
  return true

def reignite_old_fires_if_exist(pos : float3; min_distance_between_sq : float; add_fire_time : float; max_fires_to_reignite)
  var nerbyFireCount = 0
  find_query() <| $ [es(REQUIRE=fire_source, REQUIRE_NOT=node_attached__entity)] (transform : float3x4;
                                                                                  var fire_source__startTime : float&;
                                                                                  var fire_source__fullForceTime : float&;
                                                                                  fire_source__maxFullForceTime : float;
                                                                                  fire_source__spreadTime : float = 0.0)
    if !reignite_if_close(pos, transform[3], min_distance_between_sq, fire_source__startTime, fire_source__fullForceTime, fire_source__maxFullForceTime, fire_source__spreadTime, add_fire_time)
      return false
    return ++nerbyFireCount >= max_fires_to_reignite
  return nerbyFireCount > 0

def reignite_old_attached_fires_if_exist(bind_to_eid : EntityId; pos : float3; min_distance_between_sq : float; add_fire_time : float; max_fires_to_reignite)
  var nerbyFireCount = 0
  find_query() <| $ [es(REQUIRE=fire_source)] (transform : float3x4;
                                               node_attached__entity : EntityId;
                                               var fire_source__startTime : float&;
                                               var fire_source__fullForceTime : float&;
                                               fire_source__maxFullForceTime : float;
                                               fire_source__spreadTime : float = 0.0)
    if node_attached__entity != bind_to_eid || !reignite_if_close(pos, transform[3], min_distance_between_sq, fire_source__startTime, fire_source__fullForceTime, fire_source__maxFullForceTime, fire_source__spreadTime, add_fire_time)
      return false
    return ++nerbyFireCount >= max_fires_to_reignite
  return nerbyFireCount > 0

def create_fire_impl(pos : float3; norm : float3; fire_template : string; offender : EntityId; gun_props_id : int)
  var posTm = IDENT_TM
  posTm[3] = pos

  return createEntity(fire_template) <| $(var init : ComponentsInitializer)
    set(init, "transform", posTm)
    set(init, "fire_effect__norm", norm)
    set(init, "dmgzone__offender", offender)
    set(init, "dmgzone__gunPropsId", gun_props_id)

def is_too_close_to_created_fire(pos : float3; cast_result : FireCastResult; min_distance_between_sq)
  return cast_result.isFireCreated && distance_sq(cast_result.pos, pos) < min_distance_between_sq

def attach_fire(pos : float3;
                bind_to_eid : ecs::EntityId;
                coll_node_id : int;
                fire_template : string;
                offender : EntityId;
                gun_props_id : int;
                min_distance_between_sq : float;
                add_fire_time : float;
                max_fires_to_reignite : int;
                cast_result : FireCastResult)
  if reignite_old_attached_fires_if_exist(bind_to_eid, pos, min_distance_between_sq, add_fire_time, max_fires_to_reignite)
    return INVALID_ENTITY_ID
  if cast_result.attachedToEid == bind_to_eid && is_too_close_to_created_fire(pos, cast_result, min_distance_between_sq)
    return INVALID_ENTITY_ID

  var localPos = pos
  var nodeId = 0
  query(bind_to_eid) <| $ [es] (animchar : AnimcharBaseComponent;
                                collres : CollisionResource;
                                fire_attach_excludes__nodeIds : IntList)
    for coll_whell_id in fire_attach_excludes__nodeIds
      if coll_whell_id == coll_node_id
        return
    let node = collres_get_node(collres, coll_node_id)
    nodeId = uint(node.geomNodeId) < uint(animchar.nodeTree.nodeCount) ? int(node.geomNodeId) : 0
  if !get_node_local_pos(bind_to_eid, nodeId, localPos)
    return INVALID_ENTITY_ID

  let createdFireEid = create_fire_impl(pos, float3(0., 1., 0.), fire_template, offender, gun_props_id)
  attach_to_node_pos(createdFireEid, bind_to_eid, nodeId, localPos)
  return createdFireEid

def deal_damage_or_attach_fire(pos : float3;
                               eid : ecs::EntityId;
                               node_id : int;
                               fire_template : string;
                               damage : FlameDamage;
                               min_distance_between_sq : float;
                               add_fire_time : float;
                               max_fires_to_reignite : int;
                               cast_result : FireCastResult)
  if deal_fire_damage(eid, damage)
    return INVALID_ENTITY_ID
  return attach_fire(pos, eid, node_id, fire_template, damage.offender, damage.gunPropsId, min_distance_between_sq, add_fire_time, max_fires_to_reignite, cast_result)

def create_fire(pos : float3; norm : float3; fire_template : string; offender : EntityId; gun_props_id : int; min_distance_between_sq : float; add_fire_time : float; max_fires_to_reignite : int; cast_result : FireCastResult)
  if !cast_result.attachedToEid && is_too_close_to_created_fire(pos, cast_result, min_distance_between_sq)
    return INVALID_ENTITY_ID
  if reignite_old_fires_if_exist(pos, min_distance_between_sq, add_fire_time, max_fires_to_reignite)
    return INVALID_ENTITY_ID
  return create_fire_impl(pos, norm, fire_template, offender, gun_props_id)

def apply_fire_cloud_damage(from, dir : float3; len, radius : float; damage : FlameDamage)
  for_each_entity_in_grid(ecs_hash("humans"), from, dir, len, radius, GridEntCheck BOUNDING) <| $(victimEid : EntityId)
    deal_fire_damage(victimEid, damage, false)

def burn_grid_objects(start : float3;
                      hit_dir : float3;
                      hit_dist : float;
                      fire_template : string;
                      damage : FlameDamage;
                      min_between_fire_dist_sq : float;
                      add_fire_time : float;
                      max_fires_to_reignite : int;
                      cast_result : FireCastResult;
                      additional_check_length : float = 0.0;
                      excludeDamageEid = INVALID_ENTITY_ID) : FireCastResult
  var res = FireCastResult()
  using() <| $(var intersections : IntersectedEntities)
    var t1 = hit_dist + additional_check_length
    var t2 = t1
    trace_entities_in_grid(ecs_hash("humans"), start, hit_dir, t1, excludeDamageEid, intersections, SortIntersections NO)
    trace_entities_in_grid(ecs_hash("vehicles"), start, hit_dir, t2, excludeDamageEid, intersections, SortIntersections YES)
    for it in intersections
      if it.depth <= 0
        res.isFireCreated = !!deal_damage_or_attach_fire(it.pos, it.eid, it.collNodeId, fire_template, damage, min_between_fire_dist_sq, add_fire_time, max_fires_to_reignite, cast_result)
        res.isHit = true
        res.pos = it.pos
        res.attachedToEid = it.eid
        res.norm = it.norm
        break
  return res

def burn_static_objects(start : float3;
                        hit_dir : float3;
                        hit_dist : float;
                        fire_template : string;
                        damage : FlameDamage;
                        min_between_fire_dist_sq : float;
                        add_fire_time : float;
                        max_fires_to_reignite : int;
                        cast_result : FireCastResult;
                        additional_check_length : float = 0.0) : FireCastResult
  var norm : float3
  var pmid = -1
  var riDesc = RendInstDesc()
  var dist = hit_dist + additional_check_length
  let isRayHit = traceray_normalized(start, hit_dir, dist, pmid, norm, ETF_ALL, riDesc, -1)
  if isRayHit
    let hitPos = start + hit_dir * dist
    if riDesc.isValid
      deal_fire_damage_ri(riDesc.riExtraHandle, hitPos, damage, true)
    let isFireCreated = !!create_fire(hitPos, norm, fire_template, damage.offender, damage.gunPropsId, min_between_fire_dist_sq, add_fire_time, max_fires_to_reignite, cast_result)
    if isFireCreated
      broadcast_net_event([[CmdSpawnCharredArea pos=hitPos, normal=norm]])
    return [[FireCastResult isHit=true, isFireCreated=isFireCreated, pos=hitPos, norm=norm]]
  return FireCastResult()

def get_droplet_spread_dir(stream_dir, hit_norm : float3; spread : DropletSpread)
  var dir = reflect(stream_dir, hit_norm)
  dir.y = min(0.0, dir.y) + rnd_float(spread.pitchMin, spread.pitchMax)
  dir.x += rnd_float(-spread.yaw, spread.yaw)
  dir.z += rnd_float(-spread.yaw, spread.yaw)
  return normalize(dir)

def cast_droplets(hit_pos : float3;
                  hit_norm : float3;
                  stream_dir : float3;
                  fire_template : string;
                  damage : FlameDamage;
                  min_between_fire_dist_sq : float;
                  spread : DropletSpread;
                  add_fire_time : float;
                  max_fires_to_reignite : int;
                  cast_result : FireCastResult)
  let dir = get_droplet_spread_dir(stream_dir, hit_norm, spread)
  let start = hit_pos + hit_norm * spread.normalOffset

  if !burn_grid_objects(start, dir, spread.maxLength, fire_template, damage, min_between_fire_dist_sq, add_fire_time, max_fires_to_reignite, cast_result).isHit
    burn_static_objects(start, dir, spread.maxLength, fire_template, damage, min_between_fire_dist_sq, add_fire_time, max_fires_to_reignite, cast_result)

struct FlameTraceResult
  hit : bool
  pos : float3
  norm : float3
  len : float

def private do_sphere_trace(start, dir : float3; trace_len, radius : float; num_traces : int; rayMatId : int)
  var res : FlameTraceResult
  var transform : float3x4
  identity(transform)
  transform[0] = dir
  if abs(dir.y) > 0.707 // more than 45 degrees up/down, choose another basis
    transform[2] = normalize(cross(dir, float3(1, 0, 0)))
  else
    transform[2] = normalize(cross(dir, float3(0, 1, 0)))

  transform[1] = normalize(cross(dir, transform[2]))
  let invNumCasts = safeinv(float(num_traces))
  var minT = trace_len
  for i in 0 .. num_traces
    let from = start + rotate(transform, float3(0., cos(TWOPI * invNumCasts * float(i)), sin(TWOPI * invNumCasts * float(i)))) * radius
    var norm : float3
    var outT = trace_len
    var pmid : int
    var riDesc = RendInstDesc()
    if traceray_normalized(from, dir, outT, pmid, norm, ETF_DEFAULT, riDesc, rayMatId)
      if outT < minT
        minT = outT
        res.pos = from + dir * outT
        res.norm = norm
        res.len = outT
        res.hit = true

  return res

def private do_trace(start, dir : float3; trace_len, radius, min_radius_sphere_cast : float; sphere_cast_num_traces : int; rayMatId : int)
  var res : FlameTraceResult
  res.len = trace_len
  res.pos = start + dir * trace_len
  var pmid : int
  var riDesc = RendInstDesc()
  if traceray_normalized(start, dir, res.len, pmid, res.norm, ETF_DEFAULT, riDesc, rayMatId)
    res.pos = start + dir * res.len
    res.hit = true
  if radius >= min_radius_sphere_cast
    let sphereResult = do_sphere_trace(start, dir, res.len, radius, sphere_cast_num_traces, rayMatId)
    if sphereResult.hit
      return sphereResult
  return res

def shoot_fire(dt : float;
               gunPos : float3;
               gunDir : float3;
               fire_template : string;
               radius : float;
               cloud_radius : float;
               min_between_fire_dist : float;
               additional_check_length : float;
               damage : FlameDamage;
               flamethrower__flameStartOffset : float;
               flamethrower__cloudStartOffset : float;
               flamethrower__maxFlameLength : float;
               flamethrower__flameSpeed : float;
               droplets_spread : DropletSpread;
               flamethrower__addFullForceTimePerSec : float;
               flamethrower__maxFiresToReignite : int;
               var flamethrower__flameCurrentLength : float&;
               var flamethrower__hitAnything : bool?;
               excludeDamageEid = INVALID_ENTITY_ID;
               flamethrower__minRadiusForSphereCast : float = 0.011;
               flamethrower__numTracesSphereCast : int = 5;
               gun__projectileRayMatId : int = -1)
  flamethrower__flameCurrentLength = clamp(flamethrower__flameCurrentLength + flamethrower__flameSpeed * dt, 0.0, flamethrower__maxFlameLength)
  if flamethrower__hitAnything != null
    *flamethrower__hitAnything = false

  let minBetweenFireDistSq = min_between_fire_dist * min_between_fire_dist

  let start = gunPos + gunDir * flamethrower__flameStartOffset

  if (flamethrower__flameCurrentLength > flamethrower__cloudStartOffset)
    let fireCloudStart = start + gunDir * flamethrower__cloudStartOffset
    apply_fire_cloud_damage(fireCloudStart, gunDir, max(0.0, flamethrower__flameCurrentLength - cloud_radius), cloud_radius, damage)

  let out = do_trace(start, gunDir, flamethrower__flameCurrentLength, radius, flamethrower__minRadiusForSphereCast, flamethrower__numTracesSphereCast, gun__projectileRayMatId)

  flamethrower__flameCurrentLength = out.len

  let addFireTime = flamethrower__addFullForceTimePerSec * dt
  let hitPos = out.pos
  let hitDist = length(hitPos - start)
  let hitDir = abs(hitDist) > VERY_SMALL_NUMBER ? (hitPos - start) / hitDist : gunDir

  var castResult = burn_grid_objects(start, hitDir, hitDist, fire_template, damage, minBetweenFireDistSq, addFireTime, flamethrower__maxFiresToReignite, FireCastResult(), additional_check_length, excludeDamageEid)
  if castResult.isHit
    flamethrower__flameCurrentLength = dot(castResult.pos - start, gunDir)
  if flamethrower__hitAnything != null
    *flamethrower__hitAnything = castResult.isHit || out.hit
  if fire_template == ""
    return
  if !castResult.isHit
    let newCastResult = burn_static_objects(start, hitDir, hitDist, fire_template, damage, minBetweenFireDistSq, addFireTime, flamethrower__maxFiresToReignite, castResult, additional_check_length)
    castResult = newCastResult
  if castResult.isHit && !has(castResult.attachedToEid, "burning__absorbsFlameStream")
    cast_droplets(castResult.pos, castResult.norm, gunDir, fire_template, damage, minBetweenFireDistSq, droplets_spread, addFireTime, flamethrower__maxFiresToReignite, castResult)
