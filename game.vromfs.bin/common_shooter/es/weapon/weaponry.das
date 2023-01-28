require ecs
require ecs.common
require app
require player
require math
require math.base
require game.es.events
require game.es.smoke_occluders_common
require game.es.riextra_damage_common
require game.events_game
require common_shooter.events_common_shooter
require common_shooter.es.human_weap_common
require common_shooter.es.weapon.weaponry_fx_common
require enlisted.events_enlisted
require dm
require DaWeapons
require DaWeaponProps
require Dacoll
require DagorDataBlock
require DagorSystem
require DagorRandom
require DagorMath
require DagorMathUtils
require EnlistedHuman
require EnlistedWeapon
require EnlistedNet
require EnlistedActor
require EnlistedPhysObj
require EnlistedPhys
require EnlistedDm
require Ballistics
require BallisticsProps
require GeomNodeTree
require HumanPhys
require GamePhys
require GridCollision
require CollisionTraces
require PhysObj
require PhysMat
require AnimV20
require RendInst
require common_shooter.es.human.human_gun_common

// When the client throws the grenade, the action starts immediately.
// But the throw action on the server is delayed proportionaly to the client-server RTT.
// To compensate the delay, the server "moves the grenade to the future".
// Moving the grenade to the future by N ms is the same as pretending the grenade was actually thrown N ms ago.
// Compensation should be caped by the maximum allowed ping (around 750 ms by the time of the change).
[es(tag=server, tag=net, on_appear)]
def compensate_shell_throw_lag_es(evt : Event;
                                  shell__launchAtTime : float;
                                  shell__owner : EntityId;
                                  var phys_obj_net_phys : PhysObjActor)
  if shell__launchAtTime > 0.0
    let dt = base_phys_actor_getDefTimeStepByTickrateType(PhysTickRateType Normal)

    let maxTickDelta = int(ceil(PHYS_MAX_CONTROLS_TICKS_DELTA_SEC / dt))
    var tickDelta = 0
    query(shell__owner) <| $ [es] (possessedByPlr : EntityId)
      query(possessedByPlr) <| $ [es] (var player : Player)
        tickDelta = player |> calcControlsTickDelta(PhysTickRateType Normal, /*interp*/ false)
    tickDelta = clamp(tickDelta, PHYS_MIN_INTERP_DELAY_TICKS, maxTickDelta)
    // TODO: reconsider, explain and maybe abstract away the compensation formula
    // the server compensates the controls lag and forward-compensates the AAS lag, hence the times 2 part
    var tickCompensation = tickDelta * 2

    while tickCompensation > 0 && !phys_obj_net_phys.phys.currentState.hadContact
      let atTime = shell__launchAtTime - float(tickCompensation) * dt
      phys_obj_net_phys.phys |> updatePhys(atTime, dt, true)
      --tickCompensation


[es]
def launch_shell_es(evt : CmdLaunchShell;// e.g. grenade
                    eid : EntityId;
                    animchar : AnimcharBaseComponent;
                    trajectory__startNodeIdx : int;
                    human_weap__throwMode : bool;
                    human_net_phys : HumanActor const?;
                    var human_weap__localProjectileEid : EntityId?;
                    var human_weap__lastShotGunEid : EntityId?;
                    var human_weap__lastShotAtTime : float?)
  assume launchDesc = evt.launchDesc
  let gunEid = evt.gunEid
  shell_entity_get_props(int(launchDesc.shellId.shellId)) <| $(entProps : ShellEntityTypeProps)
    let entPropsPhysTemplName = entProps.physTemplName

    let projectileEntity = obtain_owned_projectile_entity(eid, HUWeaponSlots EWS_NUM)
    if human_weap__lastShotAtTime != null
      *human_weap__lastShotAtTime = get_sync_time()
    if human_weap__lastShotGunEid != null
      *human_weap__lastShotGunEid = gunEid

    var explTime = 0.f
    var grenadeOwner = eid
    var grenadeRethrower = INVALID_ENTITY_ID

    // projectileEntity contains the server-side projectile, only the server can destroy it
    if projectileEntity != INVALID_ENTITY_ID
      query(projectileEntity) <| $ [es] (shell__owner : EntityId const?;
                                         shell__rethrower : EntityId const?;
                                         shell__explTime : float const?)
        if shell__owner != null
          grenadeOwner = *shell__owner
        if shell__rethrower != null
          grenadeRethrower = *shell__rethrower
        if shell__explTime != null
          explTime = *shell__explTime

      if is_server()
        destroyEntity(projectileEntity)
      elif human_weap__localProjectileEid != null
        destroyEntity(*human_weap__localProjectileEid)
        *human_weap__localProjectileEid = INVALID_ENTITY_ID

    var launchTm = launchDesc.tm

    if human_weap__throwMode && human_net_phys != null
      assume curState = human_net_phys.phys.currentState
      let throwPoint = human_net_phys.phys |> human_phys_calcGunPos(PrecomputedPresetMode FPV,
                                                                    curState.location |> location_makeTM(),
                                                                    curState.gunAngles.y,
                                                                    curState.leanPosition,
                                                                    curState.height)

      let inBodyPoint = *animchar.nodeTree |> geomtree_getNodeWpos(trajectory__startNodeIdx)

      let throwPointOffset = throwPoint - inBodyPoint
      var offsetLength = length(throwPointOffset)
      let throwDir = throwPointOffset * safeinv(offsetLength)
      // Expand the collision detection vector forward by 10cm
      offsetLength += 0.1
      var norm = float3()
      traceray_normalized(inBodyPoint, throwDir, offsetLength, norm, ETF_RI)
      // Then, shrink it by 10cm. If there is a collision, the collision point moves 10cm closer to the inBodyPoint
      // If there no collision point, nothing changes.
      offsetLength -= 0.1

      launchTm[3] = inBodyPoint + throwDir * offsetLength

    if is_server()
      if explTime == 0.f
        // this logic is coupled with the launcher_add_timer_es, which adds explTimeAdd to some shells, like flares, rifle grenades or else
        explTime = launchDesc.atTime

      create_shell_entity(entPropsPhysTemplName, launchTm, launchDesc.vel, grenadeOwner, launchDesc.shellId, int(launchDesc.gunPropsId),
                          launchDesc.atTime, explTime, /*active*/ true, /*clientSide*/ false, grenadeRethrower)
    // Only doing client-side prediction for localy-controlled player
    // A projectile without a phys_obj_net_phys currently can't be lag-compensated on the server, so it's not client-side predicted
    else
      let physTemp = getTemplateByName(entPropsPhysTemplName)
      if (human_net_phys != null && human_net_phys.isLocalControl &&
          physTemp != null && templateHasComponent(*physTemp, "phys_obj_net_phys"))
        // The owner stores the eid of local projectile. If the owner doesn't exist, skip projectile client-side prediction (for simplicity)
        query(grenadeOwner) <| $ [es] (var human_weap__localProjectilePhysEid : EntityId&)
          // The human_weap__localProjectilePhysEid is properly destroyed and not overwritten by the new value
          destroyEntity(human_weap__localProjectilePhysEid)

          // explTime may not have valid value on the client yet. Setting 1s, so the grenade won't disappear immediately.
          if explTime == 0.f
            explTime = launchDesc.atTime + 1.f

          if explTime > launchDesc.atTime
            human_weap__localProjectilePhysEid = create_shell_entity(entPropsPhysTemplName, launchTm, launchDesc.vel,
                                                                    grenadeOwner, launchDesc.shellId, int(launchDesc.gunPropsId),
                                                                    launchDesc.atTime, explTime, /*active*/ true, /*clientSide*/ true,
                                                                    grenadeRethrower)
          else
            human_weap__localProjectilePhysEid = INVALID_ENTITY_ID

[es(tag=netClient, on_appear)]
def destroy_client_side_projectile_es(evt : Event;
                                      eid : EntityId;
                                      shell__owner : EntityId;
                                      var phys_obj_net_phys aka server_phys_obj_net_phys : PhysObjActor)
  let serverProjectileEid = eid
  // The local and the server projectiles must have the same owner
  query(shell__owner) <| $ [es] (var human_weap__localProjectilePhysEid : EntityId&)
    // If there are two projectiles (local and server's) with the same owner, the local should be destroyed
    if human_weap__localProjectilePhysEid != INVALID_ENTITY_ID && serverProjectileEid != human_weap__localProjectilePhysEid

      var delayedDestroy = false
      query(human_weap__localProjectilePhysEid) <| $ [es] (phys_obj_net_phys : PhysObjActor;
                                                           client_side_delayed_destroy : Tag const?)
        delayedDestroy = client_side_delayed_destroy != null
        // This makes the transition from local to the server projectile a bit smoother for the first few frames
        server_phys_obj_net_phys.phys.previousState.location = phys_obj_net_phys.phys.previousState.location
        server_phys_obj_net_phys.phys.previousState.velocity = phys_obj_net_phys.phys.previousState.velocity
        server_phys_obj_net_phys.phys.currentState.location = phys_obj_net_phys.phys.currentState.location
        server_phys_obj_net_phys.phys.currentState.velocity = phys_obj_net_phys.phys.currentState.velocity

      if delayedDestroy
        // sometimes we dont want to destroy client sided projectile instantly as the player might notice
        // it changing position in front of him. Most noticable on mortars with low ping, as the projectile
        // has no time to fly away before getting replaced. In this case, just disable render on the server sided
        // projectile and reenable it some time later, when actually destroying client side projectile
        addSubTemplate(human_weap__localProjectilePhysEid, "client_side_delayed_destroy") <| $(var init)
          init |> set("client_side_delayed_destroy__unhideEid", serverProjectileEid)
      else
        destroyEntity(human_weap__localProjectilePhysEid)
        human_weap__localProjectilePhysEid = INVALID_ENTITY_ID


[es(tag=netClient, no_order)]
def client_side_projectile_delayed_destroy(info : ParallelUpdateFrameDelayed;
                                           eid : EntityId;
                                           client_side_delayed_destroy__destroyAfter : float)
  if client_side_delayed_destroy__destroyAfter > 0.0 && client_side_delayed_destroy__destroyAfter < info.curTime
    destroyEntity(eid)


[es(tag=netClient, on_appear)]
def client_side_projectile_delayed_destroy_init(evt : Event;
                                                client_side_delayed_destroy__unhideEid : EntityId;
                                                client_side_delayed_destroy__delay : float;
                                                var client_side_delayed_destroy__destroyAfter : float&)
  client_side_delayed_destroy__destroyAfter = get_sync_time() + client_side_delayed_destroy__delay
  query(client_side_delayed_destroy__unhideEid) <| $ [es] (var animchar_render__enabled : bool&)
    animchar_render__enabled = false


[es(tag=netClient, on_disappear)]
def client_side_projectile_delayed_destroy_unhide(evt : Event;
                                                  eid : EntityId;
                                                  client_side_delayed_destroy__unhideEid : EntityId)
  query(client_side_delayed_destroy__unhideEid) <| $ [es] (shell__owner : EntityId;
                                                           var animchar_render__enabled : bool&)
    animchar_render__enabled = true
    query(shell__owner) <| $ [es] (var human_weap__localProjectilePhysEid : EntityId&)
      // only reset localProjectilePhysEid if it's this projectile
      // it's possible that it will contain new client side projectile eid when this on_disappear ES gets called
      // and we dont want to clear it in this case, otherwise that new client side projectile wont get replaced
      // by replicated server projectile
      if eid == human_weap__localProjectilePhysEid
        human_weap__localProjectilePhysEid = INVALID_ENTITY_ID


[es(tag=netClient, on_disappear)]
def destroy_orphaned_projectile_es_event_handler(evt : Event;
                                                 var human_weap__localProjectilePhysEid : EntityId&)
  // Destroying the grenade, when the human_weap is destroyed
  destroyEntity(human_weap__localProjectilePhysEid)
  human_weap__localProjectilePhysEid = INVALID_ENTITY_ID


[es(tag=(server, net), no_order, REQUIRE=projectile__inactive)]
def destroy_inactive_projectile_by_deadline(info : ParallelUpdateFrameDelayed; eid : EntityId; var projectile__timeToDestroy : float&)
  // After being stopped, the projectiles still lives for a little while, so the projectile state can be used to verify client-side shot
  projectile__timeToDestroy -= info.dt
  if projectile__timeToDestroy <= 0.f
    destroyEntity(eid)


[es]
def launch_projectile_es(evt : CmdLaunchProjectile;
                         eid : EntityId;
                         redirectProjectileOffender : EntityId = INVALID_ENTITY_ID;
                         var human_weap__lastShotGunEid : EntityId?;
                         var human_weap__lastShotAtTime : float?)
  assume launchDesc = evt.launchDesc
  let gunEid = evt.gunEid
  if (length_sq(launchDesc.tm[3]) < 1e10)
    query(gunEid) <| $ [es] (gun__projectileTemplate : string;
                             gun__projectileDebugTemplate : string = "";
                             gun__projectileDebug : bool = false;
                             gun__chokeSpread : float = 1.0;
                             gun__projectileRayMatId : int = -1)
      let projectileTemplate = gun__projectileDebug ? gun__projectileDebugTemplate : gun__projectileTemplate
      let spawnProps = shell_spawn_try_get_props(int(launchDesc.shellId.shellId))
      if human_weap__lastShotAtTime != null
        *human_weap__lastShotAtTime = get_sync_time()
      if human_weap__lastShotGunEid != null
        *human_weap__lastShotGunEid = gunEid
      let ownerEid = redirectProjectileOffender != INVALID_ENTITY_ID ? redirectProjectileOffender : eid
      if spawnProps == null
        createEntitySync(projectileTemplate) <| $(var init : ComponentsInitializer)
          init |> set("ownerEid", ownerEid)
          init |> set("gunEid", gunEid)
          init |> set("launch_desc", launchDesc)
          init |> set("shell__shell_id__shell_id", int(launchDesc.shellId.shellId))
          init |> set("shell__shell_id__damage_id", int(launchDesc.shellId.damageId))
          init |> set("shell__shell_id__ballistics_id", int(launchDesc.shellId.ballisticsId))
          init |> set("projectile__traceRayMatId", gun__projectileRayMatId)
      else
        let localVel = float3(
          dot(launchDesc.tm[0], launchDesc.vel),
          dot(launchDesc.tm[1], launchDesc.vel),
          dot(launchDesc.tm[2], launchDesc.vel))

        var seed = phys_time_to_seed(launchDesc.atTime)
        let count = _rnd_int(seed, spawnProps.minCount, spawnProps.maxCount)
        let chokeSpread = deg_to_rad(gun__chokeSpread)
        for _i in range(count)
          var sin = 0.0
          var cos = 0.0
          sincos(chokeSpread * _gauss_rnd(seed, 0), sin, cos)
          var newVel = float3(localVel.x * cos - localVel.y * sin, localVel.x * sin + localVel.y * cos, localVel.z)
          sincos(chokeSpread * _gauss_rnd(seed, 0), sin, cos)
          newVel = float3(newVel.x * cos + newVel.z * sin, newVel.y, -newVel.x * sin + newVel.z * cos)

          let vel = rotate(launchDesc.tm, newVel)
          using() <| $(var ldesc : LaunchDesc#)
            ldesc.shellId = launchDesc.shellId
            ldesc.gunPropsId = launchDesc.gunPropsId
            ldesc.atTime = launchDesc.atTime
            ldesc.initialLifeTime = launchDesc.initialLifeTime
            ldesc.tm = launchDesc.tm
            ldesc.vel = vel
            ldesc.firingMode = 0u
            ldesc.bombBayHeight = 0.0

            createEntitySync(projectileTemplate) <| $(var init : ComponentsInitializer)
              init |> set("ownerEid", ownerEid)
              init |> set("gunEid", gunEid)
              init |> set("launch_desc", ldesc)
              init |> set("shell__shell_id__shell_id", int(launchDesc.shellId.shellId))
              init |> set("shell__shell_id__damage_id", int(launchDesc.shellId.damageId))
              init |> set("shell__shell_id__ballistics_id", int(launchDesc.shellId.ballisticsId))
              init |> set("projectile__traceRayMatId", gun__projectileRayMatId)
  else
    logerr("invalid Launch projectile options for eid {eid}<{getEntityTemplateName(eid)}> {launchDesc.tm[3]}
            for gun {gunEid}<{getEntityTemplateName(gunEid)}>")
    destroyEntity(eid)
    return


def projectile_trace_scene(eid : EntityId;
                           bullet_mat_id : int;
                           prev_pos : float3;
                           dir : float3;
                           cur_time : float;
                           var ri_desc : RendInstDesc implicit;
                           var len : float&;
                           var pmid : int&;
                           var norm : float3&;
                           var coll_type : int&;
                           var water_len : float&)
  if bullet_mat_id < 0
    logerr("{eid}<{getEntityTemplateName(eid)}>: bullet traceRayMatId is not set!")
    return false
  var sceneIntersected = traceray_normalized_coll_type(prev_pos, dir, len, pmid, norm,
                                             ETF_ALL, ri_desc, coll_type, bullet_mat_id)
  water_len = len
  let traceEnd = prev_pos + dir * len
  if traceray_water_at_time(prev_pos, traceEnd, cur_time, water_len)
    if !sceneIntersected
      // try additional len
      len += 10.0
      traceray_normalized(prev_pos, dir, len, pmid, norm,
                          ETF_ALL, ri_desc, bullet_mat_id)
    pmid = get_material_id("water3d") // TODO: move it to dacoll, as it could really be different materials
    norm = float3(0.0, 1.0, 0.0)
    sceneIntersected = true
  return sceneIntersected


[es(after=(update_projectile_es, start_async_phys_sim_es), REQUIRE_NOT=projectile__inactive, parallel_for=1)] // after start_async_phys_sim_es to start phys sim job earlier
def trace_scene_after_update_projectile_es(info : ParallelUpdateFrameDelayed;
                                           eid : EntityId;
                                           projectile__traceRayMatId : int;
                                           projectile__stopped : bool;
                                           projectile__prevPos : float3;
                                           dm_projectile_state : ProjectileState;
                                           projectile_ballistics : ProjectileBallistics;
                                           var projectile_trace_info__sceneIntersected : bool&;
                                           var projectile_trace_info__pmid : int&;
                                           var projectile_trace_info__dir : float3&;
                                           var projectile_trace_info__norm : float3&;
                                           var projectile_trace_info__collType : int&;
                                           var projectile_trace_info__prevProjectileDistance : float&;
                                           var projectile_trace_info__waterLen : float&;
                                           var projectile_trace_info__len : float&;
                                           var projectile_trace_info__riDescCellIdx : int&;
                                           var projectile_trace_info__riDescIdx : int&;
                                           var projectile_trace_info__riDescPool : int&;
                                           var projectile_trace_info__riDescOffs : int&;
                                           var projectile_trace_info__riDescLayer : int&)
  if !projectile__stopped
    let prevPos = projectile__prevPos
    let offset = projectile_ballistics.state.pos - prevPos
    projectile_trace_info__len = length(offset)
    if projectile_trace_info__len < FLT_EPSILON
      return
    projectile_trace_info__dir = offset / projectile_trace_info__len
    projectile_trace_info__prevProjectileDistance = dm_projectile_state.distance - projectile_trace_info__len

    if (length_sq(prevPos) < 1e10 && length_sq(projectile_trace_info__dir) < 1e10)
      using() <| $(var riDesc : RendInstDesc#)
        projectile_trace_info__sceneIntersected = projectile_trace_scene(eid, projectile__traceRayMatId,
                                                                         prevPos, projectile_trace_info__dir,
                                                                         info.curTime, riDesc,
                                                                         projectile_trace_info__len,
                                                                         projectile_trace_info__pmid,
                                                                         projectile_trace_info__norm,
                                                                         projectile_trace_info__collType,
                                                                         projectile_trace_info__waterLen)
        projectile_trace_info__riDescCellIdx = riDesc.cellIdx
        projectile_trace_info__riDescIdx = riDesc.idx
        projectile_trace_info__riDescPool = riDesc.pool
        projectile_trace_info__riDescOffs = riDesc.offs
        projectile_trace_info__riDescLayer = riDesc.layer
    else
      logerr("invalid data in projectile info {projectile__prevPos} {projectile_ballistics.state.pos} {eid} {getEntityTemplateName(eid)} {projectile__stopped}")
      destroyEntity(eid)
      return

def is_bullet_stoppable_by_water(launch_desc : LaunchDesc)
  var res = false
  shell_entity_get_props(int(launch_desc.shellId.shellId)) <| $(entProps : ShellEntityTypeProps)
    let bt = entProps.bulletType
    query() <| $ [es] (projectile__bulletTypesStoppableByWater : StringList)
      res = has_value(projectile__bulletTypesStoppableByWater, bt)
  return res


struct ProjectileHitSceneRes
  shouldStop : bool
  smokeTracerStop : bool
  ricochetAngle : float


def projectile_on_hit_scene(pos : float3;
                            pmid : int;
                            norm : float3;
                            hit_water : bool;
                            ldesc : LaunchDesc;
                            ballistics_proj_props : ProjectileProps;
                            scene_hit_ricochet_stability : float;
                            var ballistics : ProjectileBallistics;
                            var proj_state : ProjectileState;
                            var vis_pos : float3&;
                            var is_underwater : bool&)
  var result = [[ProjectileHitSceneRes shouldStop=true, smokeTracerStop=false, ricochetAngle=0.0]]

  if pmid < 0
    return result

  phys_mat_damage_model_get_props(pmid) <| $(dmPhysProps : PhysMatDamageModelProps)
    let projectileSpeedThreshold = 10.0
    let angleThreshold = 0.0872 //~5 degrees
    let derivationShift = 0.7 //0.5 - without derivation
    let thresholdMass = 1.0

    var prevSpeed = length(ballistics.state.vel)
    let prevDir = ballistics.state.vel * safeinv(prevSpeed)

    var penetrationSuccess = false
    if dmPhysProps.armorThickness != 0.0
      penetration_table_get_props(int(ldesc.shellId.shellId)) <| $(penetrationProps : PenetrationTableProps)
        let armorPower = penetrationProps.tbl |> interpolate_tab_float_interpolate(proj_state.penetrationDistance)
        if armorPower >= dmPhysProps.armorThickness
          penetrationSuccess = true
          proj_state.piercingShift = calc_penetration_shift(penetrationProps.tbl,
                                                            armorPower - dmPhysProps.armorThickness,
                                                            proj_state.distance,
                                                            /*scale*/ 1.0, proj_state.piercingShift)
    if penetrationSuccess
      // move projectile forward a bit, so we dont collide with the same surface on the next frame
      // but dont move it too far or we might ignore some collisions by accident
      // (i.e. wooden floor laying on a land mesh)
      let newPos = pos + (prevDir * 0.001)
      ballistics.state.pos = newPos
      if hit_water
        is_underwater = !is_underwater
        let density = is_underwater ? water_density() : atmosphere_density(newPos.y)
        let curTick = ballistics.state.atTick
        ballistics |> projectile_ballistics_setupWithKV(ballistics_proj_props, newPos, ballistics.state.vel, 1.0f, density)
        ballistics.state.atTick = curTick + 1
        result.smokeTracerStop = true
      result.shouldStop = false
      return

    if dmPhysProps.ricochetAngleMult != 0.0 && !is_underwater
      prevSpeed = length(ballistics.state.vel)
      var seed = get_positional_seed(pos, 10.0) ^ phys_time_to_seed(ldesc.atTime)
      let sini = -dot(prevDir, norm)
      let angleMult = dmPhysProps.ricochetAngleMult
      let sinr = sini * (1.0 + (_frnd(seed) * angleMult))
      let newSpeed = (1.0 - sinr) * prevSpeed

      var bulletBrokenProbability : float
      if ballistics_proj_props.mass > thresholdMass && sini > angleThreshold
        bulletBrokenProbability = 1.0
      else
        let speedToBroken = (sini < angleThreshold ? (prevSpeed - newSpeed) : newSpeed * angleMult)
        bulletBrokenProbability = (speedToBroken / dmPhysProps.bulletBrokenThreshold)

      if (_frnd(seed) > bulletBrokenProbability
          && newSpeed > projectileSpeedThreshold
          && sini > 0.0
          && _frnd(seed) > scene_hit_ricochet_stability)
        let shiftPower = ((_frnd(seed) - derivationShift) * square(sinr))
        let sideShift = normalize(cross(prevDir, norm)) * shiftPower
        let newDir = normalize(prevDir + (norm * (sinr * 2.0)) + sideShift)
        vis_pos = pos
        let curTick = ballistics.state.atTick
        let inPos = pos - (prevDir * 0.001)
        let inVel = newDir * newSpeed
        let density = atmosphere_density(inPos.y)
        ballistics |> projectile_ballistics_setupWithKV(ballistics_proj_props, inPos, inVel, 1.0f, density)
        ballistics.state.atTick = curTick + 1

        result.shouldStop = false
        result.ricochetAngle = cvt(sinr, 0.0, 1.0, 90.0, 0.0)
        return

    if hit_water && !is_bullet_stoppable_by_water(ldesc)
      is_underwater = !is_underwater
      let newPos = pos + (prevDir * 0.01)
      let density = is_underwater ? water_density() : atmosphere_density(newPos.y)
      let curTick = ballistics.state.atTick
      ballistics |> projectile_ballistics_setupWithKV(ballistics_proj_props, newPos, ballistics.state.vel, 1.0f, density)
      ballistics.state.atTick = curTick + 1
      result.shouldStop = false
      result.smokeTracerStop = true
      return

  return result


def on_projectile_hit_scene(projectile_eid : EntityId;
                            ri_desc : RendInstDesc implicit;
                            pmid : int;
                            norm : float3;
                            prev_pos : float3;
                            dir : float3;
                            coll_type : int&;
                            len : float;
                            water_len : float;
                            projectile_dist : float;
                            allow_detonation : bool;
                            scene_intersections_count : int;
                            max_allowed_scene_intersections_for_fx : int;
                            add_bullet_hole : bool;
                            var last_damaged_riex_handle : uint64&;
                            var is_underwater : bool&)
  var shouldStop = false
  query(projectile_eid) <| $ [es] (ownerEid : EntityId;
                                   gunEid : EntityId;
                                   launch_desc : LaunchDesc;
                                   projectile_ballistics_props : ProjectileProps;
                                   projectile__prevPos : float3;
                                   projectile__sceneHitRicochetStability : float = 0.0;
                                   var dm_projectile_state : ProjectileState;
                                   var projectile_ballistics : ProjectileBallistics;
                                   var projectile__visualPos : float3&;
                                   var projectile__exploded : bool&)
    var damage = calc_kinetic_damage(int(launch_desc.shellId.shellId), projectile_dist)
    if damage < 1e-6
      let mass = projectile_ballistics_props.mass
      let speed = length(projectile_ballistics.state.vel)
      damage = calc_damage(int(launch_desc.shellId.damageId), mass, speed)
    damage *= get_float(gunEid, "gun__kineticDamageMult") ?? 1.0

    let pos = prev_pos + dir * water_len
    let riHandle = ri_desc.riExtraHandle
    if ri_desc.isValid
      let ownerTeam = get_int(ownerEid, "team") ?? TEAM_UNASSIGNED
      if riHandle != last_damaged_riex_handle && is_ri_extra_can_be_damaged_by_team(riHandle, ownerTeam)
        last_damaged_riex_handle = riHandle
        let impulse = dir * 50.0
        sendEvent(ownerEid, [[CmdRendinstDamage handle=riHandle, damage=damage, pos=pos, impulse=impulse, time=get_sync_time()]])

    if add_bullet_hole
      sendEvent(
        projectile_eid,
        [[CmdRendinstBulletHole
          handle=riHandle, pos=pos,
          norm=norm, pmid=pmid]])

    broadcastEvent([[ProjectileHitShake position=pos, damage=damage]])

    let hitWater = water_len < len
    let res = projectile_on_hit_scene(pos, pmid, norm, hitWater, launch_desc,
                                      projectile_ballistics_props,
                                      projectile__sceneHitRicochetStability,
                                      projectile_ballistics, dm_projectile_state,
                                      projectile__visualPos, is_underwater)

    if res.shouldStop
      if allow_detonation
        sendEvent(projectile_eid, [[CmdDetonateShellServer pos = pos,
                                                             offender = ownerEid,
                                                             prev_pos = projectile__prevPos,
                                                             vel = projectile_ballistics.state.vel,
                                                             ignore_entity = INVALID_ENTITY_ID,
                                                             normal = norm,
                                                             alternative_offender = INVALID_ENTITY_ID]])
        projectile__exploded = true
      projectile_ballistics.state.pos = prev_pos + dir * water_len

    let sceneIntersectionsExceeded = scene_intersections_count >= max_allowed_scene_intersections_for_fx

    sendEventImmediate(
      projectile_eid,
      [[EventProjectileHitScene
        pos=pos,
        shouldStop=res.shouldStop,
        ricochetAngle=res.ricochetAngle,
        smokeTracerStop=res.smokeTracerStop,
        rendinstCellIdx=ri_desc.cellIdx,
        rendinstIdx=ri_desc.idx,
        rendinstPool=ri_desc.pool,
        rendinstOffs=ri_desc.offs,
        rendinstLayer=ri_desc.layer,
        matId=pmid,
        norm=norm,
        allowDetonation=allow_detonation,
        sceneIntersectionsExceeded=sceneIntersectionsExceeded,
        collType=coll_type,
        vel=projectile_ballistics.state.vel]])

    shouldStop = res.shouldStop
  return shouldStop


[es(tag=server)]
def detonate_shell_server_applyer_es(evt : CmdDetonateShellServer; // detonate_shell_server can be called only from main thread.
                                     eid : EntityId;
                                     launch_desc : LaunchDesc)
  detonate_shell_server(eid,
                        launch_desc.shellId,
                        int(launch_desc.gunPropsId),
                        evt.pos,
                        evt.offender,
                        evt.prev_pos,
                        evt.vel,
                        evt.ignore_entity,
                        evt.normal,
                        evt.alternative_offender)

def trace_shootable_objects(from, dir : float3; len : float; ignore_human, ignore_vehicle : EntityId; cb : block<(intersections : IntersectedEntities#) : void>)
  using() <| $(var intersections : IntersectedEntities#)
    var t1 = len; var t2 = len; var t3 = len
    trace_entities_in_grid(ecs_hash("humans"), from, dir, t1, ignore_human, intersections, SortIntersections NO)
    trace_entities_in_grid(ecs_hash("vehicles"), from, dir, t2, ignore_vehicle, intersections, SortIntersections NO)
    trace_entities_in_grid(ecs_hash("interactable"), from, dir, t3, INVALID_ENTITY_ID, intersections, SortIntersections YES)
    invoke(cb, intersections)


[es(after=trace_scene_after_update_projectile_es, before=before_net_phys_sync, REQUIRE_NOT=projectile__inactive)]
def after_update_projectile_es(info : ParallelUpdateFrameDelayed;
                               eid : EntityId;
                               ownerEid : EntityId;
                               gunEid : EntityId;
                               projectile__lifeTime : float;
                               projectile__minLifeTime : float;
                               projectile__maxLifeTime : float;
                               projectile__maxAllowedSceneIntersectionsForFx : int;
                               projectile_ballistics : ProjectileBallistics;
                               dm_projectile_state : ProjectileState;
                               projectile__prevPos : float3;
                               projectile_trace_info__dir : float3;
                               projectile_trace_info__norm : float3;
                               projectile_trace_info__collType : int;
                               projectile_trace_info__waterLen : float;
                               projectile_trace_info__len : float;
                               projectile_trace_info__prevProjectileDistance : float;
                               projectile_trace_info__sceneIntersected : bool;
                               projectile_trace_info__pmid : int;
                               projectile_trace_info__riDescCellIdx : int;
                               projectile_trace_info__riDescIdx : int;
                               projectile_trace_info__riDescPool : int;
                               projectile_trace_info__riDescOffs : int;
                               projectile_trace_info__riDescLayer : int;
                               projectile__addBulletHole : bool = true;
                               projectile__ballisticsUpdated : bool = true;
                               var projectile__exploded : bool&;
                               var projectile__stopped : bool&;
                               var projectile__penetratedEids : EidList;
                               var projectile__lastDamagedRiexHandle : uint64&;
                               var projectile__isUnderwater : bool&;
                               var scene_hit_place__pos : float3&;
                               var scene_hit_place__norm : float3&;
                               var scene_hit_place__matId : int&;
                               var scene_hit_place__collType : int&;
                               var projectile__intersectionCount : int&)
  if projectile__stopped || projectile_trace_info__len < FLT_EPSILON || !projectile__ballisticsUpdated
    return

  let allowDetonation = (projectile__lifeTime > projectile__minLifeTime)
  let prevPos = projectile__prevPos
  let dir = projectile_trace_info__dir
  let norm = projectile_trace_info__norm
  let collType = projectile_trace_info__collType
  let pmid = projectile_trace_info__pmid
  let len = projectile_trace_info__len
  var entitiesIntersected = false
  let vehicleEid = get_Eid(ownerEid, "human_anim__vehicleSelected") ?? INVALID_ENTITY_ID
  let projectileOwnerTeam = get_int(ownerEid, "team") ?? TEAM_UNASSIGNED
  let turretOwnerEid = get_Eid(gunEid, "turret__owner") ?? INVALID_ENTITY_ID
  trace_shootable_objects(prevPos, dir, len, ownerEid, vehicleEid) <| $(sortedIntersectedList : IntersectedEntities#)
    if length(sortedIntersectedList) > 0
      for isect in sortedIntersectedList
        let i = projectile__penetratedEids |> find_index(isect.eid)
        if i >= 0
          continue
        let isectVehicleEid = get_Eid(isect.eid, "human_anim__vehicleSelected") ?? INVALID_ENTITY_ID
        let isIntersectedWithCrew = isectVehicleEid != INVALID_ENTITY_ID && (isectVehicleEid == vehicleEid || isectVehicleEid == turretOwnerEid)

        if (isIntersectedWithCrew || isect.eid == turretOwnerEid)
          continue
        let hitRes = projectile_on_hit_entity(eid, isect, projectileOwnerTeam,
                                              projectile_ballistics.state.vel, prevPos,
                                              dir, projectile_trace_info__waterLen,
                                              info.curTime, projectile_trace_info__prevProjectileDistance,
                                              sortedIntersectedList,
                                              allowDetonation)
        if hitRes == ProjectileHitResult Ignore
          continue
        entitiesIntersected = true
        if hitRes == ProjectileHitResult HitAndContinue
          projectile__penetratedEids |> push(isect.eid)
        else // HitAndDestroyProjectile
          projectile__stopped = true
          if allowDetonation
            projectile__exploded = true
          break

  // Actually correct would be iterate over until we got closest hit. However, we will be using simplified version.
  let maxLen = min(projectile_trace_info__waterLen, len)
  let isLocalOwner = ownerEid |> has("hero")
  broadcastEventImmediate([[EventProjectileFlight prevPos=prevPos, normalizedDir=dir, dist=maxLen, isLocalOwner=isLocalOwner]])

  if projectile_trace_info__sceneIntersected && !entitiesIntersected
    using(projectile_trace_info__riDescCellIdx,
          projectile_trace_info__riDescIdx,
          projectile_trace_info__riDescPool,
          projectile_trace_info__riDescOffs,
          projectile_trace_info__riDescLayer) <| $(var riDesc : RendInstDesc#)
      projectile__intersectionCount += 1
      let projectileDist = projectile_trace_info__prevProjectileDistance + projectile_trace_info__waterLen + dm_projectile_state.piercingShift
      let shouldStop = on_projectile_hit_scene(eid, riDesc, pmid, norm, prevPos, dir,
                                               projectile_trace_info__collType,
                                               projectile_trace_info__len, projectile_trace_info__waterLen,
                                               projectileDist, allowDetonation, projectile__intersectionCount,
                                               projectile__maxAllowedSceneIntersectionsForFx,
                                               projectile__addBulletHole, projectile__lastDamagedRiexHandle,
                                               projectile__isUnderwater)
      if shouldStop
        projectile__stopped = true
        if allowDetonation
          if !projectile__exploded
            logerr("{eid}<{getEntityTemplateName(eid)}>: projectile__exploded should be set inside on_projectile_hit_scene")

  if projectile__stopped
    scene_hit_place__pos = prevPos + dir * projectile_trace_info__waterLen
    if projectile_trace_info__sceneIntersected && !entitiesIntersected
      scene_hit_place__norm = norm
      scene_hit_place__matId = pmid
      scene_hit_place__collType = collType
    else
      scene_hit_place__matId = -1

  // Actually, it is better to check lengthSq(ballistics.state.vel) > threshold
  if projectile__lifeTime > projectile__maxLifeTime || projectile__exploded
    if is_true_net_server()
      // net server needs projectile for client-side shot verification, so the projectile destruction is slightly delayed
      addSubTemplate(eid, "projectile_inactive")
    else
      sendEvent(eid, [[CmdDestoyProjectileEntity]]) // destroy entity via event to properly handle sent events before actual destruction


[es]
def destoy_projectiles_after_stop(Event : CmdDestoyProjectileEntity;
                                  eid : EntityId)
  destroyEntity(eid)


[es(after=update_projectile_es, REQUIRE_NOT=projectile__inactive)]
def after_update_stopped_projectile_es(info : ParallelUpdateFrameDelayed;
                                       eid : EntityId;
                                       ownerEid : EntityId;
                                       projectile__lifeTime : float;
                                       projectile__minLifeTime : float;
                                       projectile__maxLifeTime : float;
                                       projectile__prevPos : float3;
                                       projectile_ballistics : ProjectileBallistics;
                                       scene_hit_place__norm : float3;
                                       projectile__stopped : bool;
                                       var projectile__exploded : bool&;
                                       var projectile__explosionDelayed : int&)
  if projectile__stopped
    if !projectile__exploded && projectile__lifeTime > projectile__minLifeTime
      let shouldDelay : bool = find_query() <| $ [es] (server_explosions__maxProjectilesCount : int;
                                                       server_explosions__maxDelayedFramesCounter : int;
                                                       var server_explosions__projectilesCounter : int&)
        server_explosions__projectilesCounter++
        return (projectile__explosionDelayed < server_explosions__maxDelayedFramesCounter &&
                server_explosions__projectilesCounter > server_explosions__maxProjectilesCount)

      if shouldDelay
        projectile__explosionDelayed++
        return

      sendEvent(eid, [[CmdDetonateShellServer pos = projectile_ballistics.state.pos,
                                                offender = ownerEid,
                                                prev_pos = projectile__prevPos,
                                                vel = projectile_ballistics.state.vel,
                                                ignore_entity = INVALID_ENTITY_ID,
                                                normal = scene_hit_place__norm,
                                                alternative_offender = INVALID_ENTITY_ID]])

      sendEventImmediate(eid, [[CmdShellExplosionFx]])
      projectile__exploded = true

    // Actually, it is better to check lengthSq(ballistics.state.vel) > threshold
    if projectile__lifeTime > projectile__maxLifeTime || projectile__exploded
      if is_true_net_server()
        // net server needs projectile for client-side shot verification, so the projectile destruction is slightly delayed
        addSubTemplate(eid, "projectile_inactive")
      else
        sendEvent(eid, [[CmdDestoyProjectileEntity]]) // destroy entity via event to properly handle sent events before actual destruction

[es(after=after_update_stopped_projectile_es)]
def clear_exploding_projectiles_counter(info : ParallelUpdateFrameDelayed;
                                        var server_explosions__projectilesCounter : int&)
  server_explosions__projectilesCounter = 0

[es(on_appear)]
def init_max_exploding_projectiles(evt : Event;
                                   var server_explosions__maxProjectilesCount : int&;
                                   var server_explosions__maxDelayedFrames : int&)
  dgs_get_settings() |> datablock_get_block("dedicated") <| $(dedBlock)
    server_explosions__maxProjectilesCount = dedBlock |> datablock_getInt("maxExplodingProjectiles", server_explosions__maxProjectilesCount)
    server_explosions__maxDelayedFrames = dedBlock |> datablock_getInt("maxExplosionDelay", server_explosions__maxDelayedFrames)


def create_smoke_occluders_impl(effect_group_name : string;
                                is_bomb : bool;
                                launch_desc : LaunchDesc;
                                mat_id : int;
                                bullet_type_id : int;
                                is_under_water : bool;
                                pos : float3;
                                norm : float3)
  if int(launch_desc.shellId.shellId) < 0
    return
  let fxName = get_projectile_fx_name(effect_group_name, is_bomb, launch_desc, mat_id,
                                      bullet_type_id, is_under_water)
  if fxName == "" || fxName == "-"
    return

  let tm = calc_effect_tm(pos, norm)
  create_smoke_occluders_for_effect(tm, fxName)


[es]
def projectile_create_smoke_occluders_on_hit_scene(evt : EventProjectileHitScene;
                                                   launch_desc : LaunchDesc;
                                                   dm_projectile_state : ProjectileState;
                                                   projectile__effectGroupName : string;
                                                   projectile__isUnderwater : bool;
                                                   projectile__isBomb : bool = false)
  if !evt.sceneIntersectionsExceeded || (evt.shouldStop && evt.allowDetonation)
    create_smoke_occluders_impl(projectile__effectGroupName, projectile__isBomb, launch_desc, evt.matId,
                                dm_projectile_state.projectileTypePropsId, projectile__isUnderwater, evt.pos, evt.norm)


[es]
def projectile_create_smoke_occluders_on_explode(evt : CmdShellExplosionFx;
                                                 scene_hit_place__matId : int;
                                                 scene_hit_place__pos : float3;
                                                 scene_hit_place__norm : float3;
                                                 launch_desc : LaunchDesc;
                                                 dm_projectile_state : ProjectileState;
                                                 projectile__effectGroupName : string;
                                                 projectile__isUnderwater : bool;
                                                 projectile__isBomb : bool = false)
  create_smoke_occluders_impl(projectile__effectGroupName, projectile__isBomb, launch_desc, scene_hit_place__matId,
                              dm_projectile_state.projectileTypePropsId, projectile__isUnderwater,
                              scene_hit_place__pos, scene_hit_place__norm)
