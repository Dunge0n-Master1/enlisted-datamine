require ecs
require ecs.common
require app
require EnlistedNet
require math
require math.base
require game.utils.team
require game.utils.animchar
require game.es.events
require game.vehicle
require game.events_game
require vehicle
require common_shooter.events_common_shooter
require DagorMath
require DagorSystem
require HumanPhys
require EnlistedDm
require EnlistedHuman
require EnlistedPhysObj
require EnlistedShip
require PhysObj
require RendInst
require Ship

require daslib/array_boost


def push_entity(eid : EntityId;
                beh_tree__enabled : bool;
                dir : float3;
                add_rot : quat;
                radius : float;
                speed : float;
                distance_power : float;
                distance_power_scale_limits : float2;
                enemy_effect_template : das_string const?;
                enemy_effect_template_ttl : float;
                immunity_amount : float;
                hit_tag_power_mult : float;
                ai_distance_power_mult : float)
  let invRadius = safeinv(radius)
  let dirLen = length(dir)
  let dirN = dir * safeinv(dirLen)
  let limits = distance_power_scale_limits
  var power = clamp(pow(1.0 - dirLen * invRadius, distance_power), limits.x, limits.y)
  if beh_tree__enabled
    power *= ai_distance_power_mult
  let pushDir = add_rot * dirN
  let vel = pushDir * speed * power
  let push_immunity = immunity_amount * speed
  sendEvent(eid, [[CmdPushPhys vel=vel, push_immunity=push_immunity]])

  if hit_tag_power_mult > 0.0
    sendEventImmediate(eid, [[CmdHumanHitTagging powerMult=hit_tag_power_mult]])

  if enemy_effect_template != null
    createEntity((*enemy_effect_template) |> string()) <| $(var init : ComponentsInitializer)
      init |> set("game_effect__attachedTo", eid)
      init |> set("game_effect__destroyAt", get_sync_time() + enemy_effect_template_ttl)


def push_around(transform : float3x4;
                radius : float;
                speed : float;
                distance_power : float;
                distance_power_scale_limits : float2;
                pitch : float;
                enemy_effect_template : das_string const?;
                vehicle_energy_scale : float;
                vehicle_point_offset : float3;
                enemy_effect_template_ttl : float;
                enemy_damage : float;
                immunity_amount : float;
                hit_tag_power_mult : float;
                ai_distance_power_mult : float;
                main_actor_eid : EntityId)
  let centerPos = transform[3]
  let radiusSq = radius * radius
  var quatRes : quat
  euler_to_quat(0.0, deg_to_rad(pitch), 0.0, quatRes)

  query() <| $ [es(REQUIRE=human_net_phys)] (eid : EntityId;
                                             transform : float3x4;
                                             team : int = int(TEAM_UNASSIGNED);
                                             beh_tree__enabled : bool = false;
                                             game_effect__invisible : bool = false)
    push_human_around(transform, centerPos,
                      eid, main_actor_eid,
                      quatRes,
                      radius, speed, distance_power,
                      distance_power_scale_limits,
                      enemy_effect_template,
                      enemy_effect_template_ttl,
                      immunity_amount, hit_tag_power_mult, ai_distance_power_mult,
                      enemy_damage,
                      team,
                      beh_tree__enabled, game_effect__invisible)

  query() <| $ [es(REQUIRE=npysPushable)] (eid : EntityId;
                                           transform : float3x4;
                                           team : int = int(TEAM_UNASSIGNED);
                                           beh_tree__enabled : bool = false;
                                           game_effect__invisible : bool = false)
    push_human_around(transform, centerPos,
                      eid, main_actor_eid,
                      quatRes,
                      radius, speed, distance_power,
                      distance_power_scale_limits,
                      enemy_effect_template,
                      enemy_effect_template_ttl,
                      immunity_amount, hit_tag_power_mult, ai_distance_power_mult,
                      enemy_damage,
                      team,
                      beh_tree__enabled, game_effect__invisible)

  query() <| $ [es(REQUIRE=phys_obj_net_phys)] (eid : EntityId;
                                                transform : float3x4)
    let dir = transform[3] - centerPos
    if length_sq(dir) < radiusSq
      push_entity(eid, false, dir, quatRes, radius, speed,
                  distance_power, distance_power_scale_limits,
                  null, enemy_effect_template_ttl,
                  immunity_amount, 0.0, ai_distance_power_mult)

  let orig_tm = transform
  query() <| $ [es] (eid : EntityId;
                     transform : float3x4;
                     vehicle_net_phys : VehiclePhysActor)
    let dir = transform[3] - centerPos

    if length_sq(dir) < radiusSq && empty(vehicle_net_phys.phys.explosionDamageImpulses)
      var originateTm = orig_tm
      originateTm[3] = orig_tm * vehicle_point_offset
      let pushDir = normalize(transform[3] - originateTm[3])
      let energyScale = cvt(length(dir), 0.0, radius, vehicle_energy_scale, 0.0)
      let energyScaledDir = pushDir * energyScale
      let arm = transform[3] - normalize(dir)
      sendEvent(eid, [[CmdVehiclePushPhys energyScaledDir=energyScaledDir, arm=arm, duration=0.0]])


def push_human_around(transform : float3x4;
                      centerPos : float3;
                      eid, main_actor_eid : EntityId;
                      quatRes : quat;
                      radius, speed, distance_power : float;
                      distance_power_scale_limits : float2;
                      enemy_effect_template : das_string const?;
                      enemy_effect_template_ttl : float;
                      immunity_amount, hit_tag_power_mult, ai_distance_power_mult : float;
                      enemy_damage : float;
                      team : int;
                      beh_tree__enabled, game_effect__invisible : bool)
  if game_effect__invisible
    return

  let dir = transform[3] - centerPos
  let dirLenSq = length_sq(dir)

  if main_actor_eid != eid && dirLenSq < square(radius)
    push_entity(eid, beh_tree__enabled, dir, quatRes, radius, speed,
                distance_power, distance_power_scale_limits,
                enemy_effect_template, enemy_effect_template_ttl,
                immunity_amount, hit_tag_power_mult, ai_distance_power_mult)

    if enemy_damage > FLT_EPSILON
      let mainActorTeam = get_int(main_actor_eid, "team") ?? int(TEAM_UNASSIGNED)
      if !is_teams_friendly(team, mainActorTeam)
        var power = pow(1.0 - sqrt(dirLenSq) * safeinv(radius), distance_power)
        power = clamp(power, distance_power_scale_limits.x, distance_power_scale_limits.y)
        let dmg = enemy_damage * power
        if dmg > FLT_EPSILON
          let damage = DamageDesc(DamageType DM_EXPLOSION, dmg, transform[3])
          damage_entity(eid, main_actor_eid, damage)


[es(tag=server)]
def push_around_es(evt : EventEntityCreated;
                   eid : EntityId;
                   transform : float3x4;
                   push_around__radius : float;
                   push_around__speed : float;
                   push_around__distancePower : float;
                   push_around__distancePowerScaleLimits : float2;
                   push_around__pitch : float;
                   push_around__enemyEffectTemplate : das_string const?;
                   push_around__vehicleEnergyScale : float;
                   push_around__vehiclePointOffset : float3;
                   game_effect__attachedTo : EntityId = INVALID_ENTITY_ID;
                   push_around__enemyDamage : float = 0.0;
                   push_around__enemyEffectTemplateTtl : float = 2.0;
                   push_around__immunityAmount : float = 2.0;
                   push_around__hitTagPowerMult : float = 0.5;
                   push_around__aiDistancePowerMult : float = 2.0)
  push_around(transform, push_around__radius, push_around__speed,
              push_around__distancePower, push_around__distancePowerScaleLimits,
              push_around__pitch, push_around__enemyEffectTemplate,
              push_around__vehicleEnergyScale, push_around__vehiclePointOffset,
              push_around__enemyEffectTemplateTtl, push_around__enemyDamage,
              push_around__immunityAmount, push_around__hitTagPowerMult,
              push_around__aiDistancePowerMult,
              (game_effect__attachedTo != INVALID_ENTITY_ID) ? game_effect__attachedTo : eid)
  destroyEntity(eid)


def riex_should_damage(eid : EntityId; team : int; riex_handle : riex_handle_t)
  let heid = find_ri_extra_eid(riex_handle)
  return should_shell_damage(heid, eid, team)


def riex_set_offender(riex_handle : riex_handle_t; offenderEid : EntityId)
  let riexEid = find_ri_extra_eid(riex_handle)
  var riOffender = getRW_Eid(riexEid, "riOffender")
  if riOffender != null
    *riOffender = offenderEid


[es]
def human_phys_push_es(evt : CmdPushPhys;
                       eid : EntityId;
                       var human_net_phys : HumanActor)
  let pushVel = evt.vel
  let pushIgnoreAmount = evt.push_immunity
  let pushSpd = length(pushVel)
  var pushDir = pushVel * safeinv(pushSpd)
  let dirToNormalDot = dot(pushDir, human_net_phys.phys.currentState.walkNormal)
  if dirToNormalDot < 0.0
    pushDir = pushDir - 2.0 * dirToNormalDot * human_net_phys.phys.currentState.walkNormal
  let curProj = dot(human_net_phys.phys.currentState.velocity, pushDir)
  if curProj < pushSpd
    human_net_phys.phys.currentState.velocity += pushDir * (pushSpd - max(curProj, 0.0))
    human_net_phys.phys.currentState.isInAirHistory = uint8(int(human_net_phys.phys.currentState.isInAirHistory) | 15)
    human_net_phys.phys.currentState.deltaVelIgnoreAmount += pushIgnoreAmount
    let knockBackTimer = 0.6 // TODO: move value to human_net_phys.phys and add something like phys.knockback() function which do just this?
    human_net_phys.phys.currentState.knockBackTimer = knockBackTimer
    human_net_phys.phys |> human_phys_wakeUp()
    human_net_phys.phys |> human_phys_rescheduleAuthorityApprovedSend()
    sendEvent(eid, [[CmdDetachAttachedGun]])


[es]
def physobj_push_es(evt : CmdPushPhys;
                    var phys_obj_net_phys : PhysObjActor)
  let pushVel = evt.vel
  let pushSpd = length(pushVel)
  let pushDir = pushVel * safeinv(pushSpd)
  let curProj = dot(phys_obj_net_phys.phys.currentState.velocity, pushDir)
  phys_obj_net_phys.phys.currentState.velocity += pushDir * (pushSpd - max(curProj, 0.0))
  phys_obj_net_phys.phys |> wakeUp()
  phys_obj_net_phys.phys |> phys_obj_rescheduleAuthorityApprovedSend()


[es]
def vehicle_phys_push_es(evt : CmdVehiclePushPhys;
                         var vehicle_net_phys : VehiclePhysActor)
  if !empty(vehicle_net_phys.phys.explosionDamageImpulses)
    return

  let energyScaledDir = evt.energyScaledDir
  let arm = evt.arm
  let duration = evt.duration
  let mass = vehicle_net_phys.phys.getMass
  let impulse = energyScaledDir * sqrt(mass)
  let endTime = double(get_sync_time() + duration)

  vehicle_net_phys.phys.explosionDamageImpulses |> emplace(
    [[VehiclePhysExplosionDamageImpulse endTime=endTime,
                                        impulse=impulse,
                                        arm=arm]])
  vehicle_net_phys.phys |> wakeUp()


[es]
def ship_phys_push_es(evt : CmdVehiclePushPhys;
                      transform : float3x4;
                      var ship_net_phys : ShipActor;
                      var auto_anchor__nextAnchorTime : float?)
  if !empty(ship_net_phys.phys.explosionDamageImpulses)
    return

  let energyScaledDir = evt.energyScaledDir
  let arm = evt.arm
  let duration = evt.duration
  ship_net_phys.phys |> ship_phys_set_anchor(false)
  let itm = inverse(transform)
  let mass = ship_net_phys.phys.getMass
  let dir = rotate(itm, (energyScaledDir * sqrt(mass)))
  let impulse = dir * ship_net_phys.phys.timeStep
  let endTime = double(get_sync_time() + duration)

  ship_net_phys.phys.explosionDamageImpulses |> emplace(
    [[ShipPhysExplosionDamageImpulse endTime=endTime,
                                     impulse=impulse,
                                     arm=(itm * arm)]])
  ship_net_phys.phys |> ship_phys_wake_up()

  if auto_anchor__nextAnchorTime != null
    *auto_anchor__nextAnchorTime = 0.0