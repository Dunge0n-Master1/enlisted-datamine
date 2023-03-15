require ecs
require app
require DagorMathUtils
require math.base
require BallisticsProps
require PhysObj
require EnlistedPhysObj
require DaWeaponProps
require turrets
require common_shooter.es.forestall_common
require common_shooter.events_common_shooter
require human_sounds_net.modules.human_sounds_net_events
require game.utils.team
require walkerai
require EnlistedNet
require AnimV20
require GeomNodeTree

struct AiGunnerTarget
  pos : float3 = float3(0, 0, 0)
  active : bool = false

def get_forestall_or(owner_pos, owner_vel, target_pos, target_vel : float3; gun_eid : EntityId; default_val : float3)
  var res = default_val
  query(gun_eid) <| $ [es] (gun__curShellId : ShellPropIds)
    projectile_get_props(int(gun__curShellId.ballisticsId)) <| $(ballisticsProps : ProjectileProps)
      shell_start_get_props(int(gun__curShellId.shellId)) <| $(shellStartProps : ShellStartProps)
        let muzzleVelocity = shellStartProps.speed
        let forestall = get_forestall_pos(owner_pos, owner_vel, ballisticsProps, muzzleVelocity, target_pos, target_vel)
        if forestall.valid
          res = forestall.pos
  return res

def find_target(ignore_eid : EntityId;
                owner_team : int;
                turret_itm : float3x4;
                min_dist : float;
                max_dist : float;
                limit_angles_deg : float4) : EntityId
  var target = INVALID_ENTITY_ID
  var minDistanceToTargetSq = square(max_dist)
  let minDistanceSq = square(min_dist)
  let limits = deg_to_rad(limit_angles_deg)

  query() <| $ [es(REQUIRE=ai_target__targetForAiGunner)] (eid : EntityId; team : int; ai_target : Target; isInVehicleHidden : bool = false)
    if ignore_eid == eid || !ai_target.isAlive || team == TEAM_UNASSIGNED || is_teams_friendly(owner_team, team) || isInVehicleHidden
      return

    let localDirToTarget = turret_itm * ai_target.targetPos
    let distanceToTargetSq = length_sq(localDirToTarget)
    if distanceToTargetSq > minDistanceToTargetSq || distanceToTargetSq < minDistanceSq
      return

    let angles = dir_to_angles(localDirToTarget)
    let yaw = angles.x
    let pitch = angles.y

    if yaw < limits[0] || yaw > limits[1] || pitch < limits[2] || pitch > limits[3]
      return

    minDistanceToTargetSq = distanceToTargetSq
    target = eid

  return target

def find_atack_target(ignore_eid : EntityId;
                      owner_team : int;
                      turret_itm : float3x4;
                      min_dist : float;
                      max_dist : float;
                      limit_angles_deg : float4) : EntityId
  return find_target(ignore_eid, owner_team, turret_itm, min_dist, max_dist, limit_angles_deg)

def find_chase_target(ignore_eid : EntityId;
                      turret_itm : float3x4;
                      min_dist : float;
                      max_dist : float;
                      limit_angles_deg : float4) : EntityId
  let owner_team = TEAM_UNASSIGNED
  return find_target(ignore_eid, owner_team, turret_itm, min_dist, max_dist, limit_angles_deg)

def get_target_pos(owner_pos, owner_vel : float3; gun_eid, target_eid : EntityId)
  var target = AiGunnerTarget()
  query(target_eid) <| $ [es] (ai_target : Target)
    if !ai_target.isAlive
      return
    target.active = true
    target.pos = ai_target.targetPos
    let targetVel = ai_target.velocity
    if length_sq(targetVel) > 1.0
      target.pos = get_forestall_or(owner_pos, owner_vel, target.pos, targetVel, gun_eid, target.pos)
  return target

[es(tag=server, before=before_net_phys_sync, REQUIRE=controlledByAiGunner)]
def ai_gunner_find_target(info : UpdateStageInfoAct;
                          gun__owner : EntityId;
                          turret__owner : EntityId;
                          turret__aimNodeId : int;
                          turret_ai__targetCheckInterval : float;
                          turret_ai__identDist : float;
                          turret_ai__atackDist : float;
                          turret_ai__atackMinDist : float = 0.f;
                          turret__limit : float4 = float4(-180, 180, -180, 180);
                          turret_ai__limitAngles : float4 const?;
                          var turret_aim__target : EntityId&;
                          var turret_ai__atackTarget : EntityId&;
                          var turret_ai__chaseTarget : EntityId&;
                          var turret_ai__nextTargetCheckAtTime : float&)
  query(gun__owner) <| $ [es(REQUIRE_NOT=deadEntity)] (team : int)
    if info.curTime < turret_ai__nextTargetCheckAtTime || turret__aimNodeId < 0
      return

    turret_ai__nextTargetCheckAtTime = info.curTime + turret_ai__targetCheckInterval

    query(turret__owner) <| $ [es] (animchar : AnimcharBaseComponent)
      let parNodeId = geomtree_getParentNodeIdx(*animchar.nodeTree, turret__aimNodeId)
      if parNodeId >= 0
        var tm : float3x4
        var wt : float3x4

        *animchar.originalNodeTree |> geomtree_getNodeTmScalar(turret__aimNodeId, tm)
        *animchar.nodeTree |> geomtree_getNodeWtmScalar(parNodeId, wt)

        let turretItm = inverse(wt * tm)

        let limit = turret_ai__limitAngles ?? turret__limit

        turret_ai__atackTarget = find_atack_target(turret__owner, team, turretItm, turret_ai__atackMinDist, turret_ai__atackDist, limit)
        turret_ai__chaseTarget = INVALID_ENTITY_ID
        turret_aim__target = turret_ai__atackTarget

        if !turret_ai__atackTarget
          turret_ai__chaseTarget = find_atack_target(turret__owner, team, turretItm, turret_ai__atackMinDist, turret_ai__identDist, limit)

        if !turret_ai__chaseTarget
          turret_ai__chaseTarget = find_chase_target(turret__owner, turretItm, turret_ai__atackMinDist, turret_ai__identDist, limit)

[es(tag=server, after=ai_gunner_find_target, before=before_net_phys_sync)]
def ai_gunner_activate_turret_target(info : UpdateStageInfoAct)
  query() <| $ [es(REQUIRE=team__score)] (team__id : int)
    var maxActiveTurrets = 8
    query() <| $ [es(REQUIRE=controlledByAiGunner)] (turret_ai__atackTarget : EntityId;
                                                     gun__owner : EntityId)
      query(gun__owner) <| $ [es] (eid : EntityId;
                                   team : int;
                                   var phys_obj_net_phys : PhysObjActor;
                                   phys__isAsleep : bool;
                                   disableUpdate : Tag const?)
        if team__id != team
          return
        if (!turret_ai__atackTarget || maxActiveTurrets <= 0) && disableUpdate == null
          if !phys__isAsleep
            return
          let templateName = getEntityFutureTemplateName(eid)
          let newTemplate = add_sub_template_name(templateName, "disable_update")
          remote_recreate_entity_from(eid, newTemplate)
          return
        if maxActiveTurrets <= 0
          return
        if !!turret_ai__atackTarget
          if disableUpdate != null
            let templateName = getEntityFutureTemplateName(eid)
            let newTemplate = remove_sub_template_name(templateName, "disable_update")
            remote_recreate_entity_from(eid, newTemplate)
          phys_obj_net_phys.phys |> wakeUp()
          maxActiveTurrets--

[es(tag=server, track=turret_ai__atackTarget)]
def ai_gunner_sound_atack_target(evt : Event;
                                 gun__owner : EntityId;
                                 turret_ai__atackTarget : EntityId)
  if turret_ai__atackTarget != INVALID_ENTITY_ID
    sendEvent(gun__owner, [[CmdRequestHumanSpeech phrase="confirmResponse"]])

[es(tag=server, track=turret_ai__chaseTarget)]
def ai_gunner_sound_chase_target(evt : Event;
                                 gun__owner : EntityId;
                                 turret_ai__chaseTarget : EntityId)
  if turret_ai__chaseTarget != INVALID_ENTITY_ID
    sendEvent(gun__owner, [[CmdRequestHumanSpeech phrase="confirmResponse"]])

def calc_distribution(t : float;
                      amp : float;
                      per : float;
                      min : float;
                      max : float)
  let val = amp * cos(per * t)
  let mid = 0.5 * (max + min)

  return (val <= max && val >= mid) ? max : (val >= min && val <= mid) ? min : val

[es(tag=server, REQUIRE=turret_control__hasAiGunners, after=vehicle_input_turret_es, before=turret_aim_pos_to_wish_dir_es)]
def turret_ai_gunner_aim(evt : CmdTurretsUpdate;
                         transform : float3x4;
                         turret_control__gunEids : EidList;
                         net_phys__currentStateVelocity : float3 = float3())
  let shooterVel = net_phys__currentStateVelocity
  let shooterPos = transform[3]

  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=controlledByAiGunner)] (turret_state : TurretState;
                                                           turret_ai__atackTarget : EntityId;
                                                           turret_ai__attackTimerr : float;
                                                           turret_ai__pauseTimer : float;
                                                           turret_ai__sleepTimer : float;
                                                           turret_ai__distrTimer : float;
                                                           turret_ai__amplitude : float2;
                                                           turret_ai__period : float2;
                                                           turret_ai__minWindow : float2;
                                                           turret_ai__maxWindow : float2;
                                                           var turret_ai__distrTime : float&;
                                                           var turret_ai__attackTimer : float&;
                                                           var turret_ai__pauseTime : float&;
                                                           var turret_ai__sleepTime : float&;
                                                           var turret_ai__distrStartTime : float&;
                                                           var turret_aim__shootToPos : float3&;
                                                           var turret_aim__shootFlag : bool&;
                                                           turret_ai__shootAngleCos : float = 0.9)
      if turret_ai__sleepTime >= 0.
        turret_ai__sleepTime -= evt.dt

      if turret_ai__distrTime <= 0.
        turret_ai__distrStartTime = get_sync_time()

      if turret_ai__attackTimer >= turret_ai__attackTimerr
        turret_ai__attackTimer = 0.
        turret_ai__sleepTime = turret_ai__sleepTimer

      if turret_ai__atackTarget != INVALID_ENTITY_ID
        let target = get_target_pos(shooterPos, shooterVel, gunEid, turret_ai__atackTarget)

        if target.active
          let aimDir3D = normalize(target.pos - turret_state.shoot.pos)
          let aimDir2D = normalize(aimDir3D.xz)

          let shootDir = turret_state.shoot.dir

          let timeDiff = get_sync_time() - turret_ai__distrStartTime

          turret_aim__shootToPos  = target.pos
          turret_aim__shootToPos += calc_distribution(timeDiff, turret_ai__amplitude.x, turret_ai__period.x, turret_ai__minWindow.x, turret_ai__maxWindow.x) * float3(aimDir2D.y, 0., -aimDir2D.x)
          turret_aim__shootToPos += calc_distribution(timeDiff, turret_ai__amplitude.y, turret_ai__period.y, turret_ai__minWindow.y, turret_ai__maxWindow.y) * float3(0., 1., 0.)

          if turret_ai__sleepTime <= 0. && turret_ai__shootAngleCos <= dot(aimDir3D, shootDir)
            turret_ai__pauseTime  = 0.
            turret_aim__shootFlag = true
            turret_ai__attackTimer  = turret_ai__attackTimer + evt.dt
            turret_ai__distrTime  = turret_ai__distrTimer

            return

      turret_aim__shootFlag = false
      turret_ai__pauseTime  = turret_ai__pauseTime + evt.dt
      turret_ai__distrTime  = turret_ai__distrTime - evt.dt

      if turret_ai__pauseTimer <= turret_ai__pauseTime
        turret_ai__pauseTime = 0.
        turret_ai__attackTimer = 0.

[es(tag=server, REQUIRE=turret_control__hasAiGunners, after=vehicle_input_turret_es, before=turret_aim_pos_to_wish_dir_es)]
def ai_gunner_idle(evt : CmdTurretsUpdate;
                   net_phys__currentStatePosition : float3&;
                   turret_control__gunEids : EidList)
  let aimDistance  = 1000.0

  let shootFromPos = net_phys__currentStatePosition + float3(0.0, 2.0, 0.0)

  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=controlledByAiGunner)] (gun__owner : EntityId;
                                                           turret_ai__atackTarget : EntityId;
                                                           turret_ai__chaseTarget : EntityId;
                                                           var turret_aim__shootToPos : float3&)
      if turret_ai__atackTarget != INVALID_ENTITY_ID || turret_ai__chaseTarget != INVALID_ENTITY_ID
        return

      query(gun__owner) <| $ [es] (transform : float3x4)
        turret_aim__shootToPos = shootFromPos + transform[0] * aimDistance

[es(tag=server, REQUIRE=(turret_control__hasAiGunners, turret_control__chaseTargets), after=vehicle_input_turret_es, before=turret_aim_pos_to_wish_dir_es)]
def ai_gunner_chase_target(evt : CmdTurretsUpdate;
                           transform : float3x4;
                           turret_control__gunEids : EidList;
                           net_phys__currentStateVelocity : float3 = float3())
  let shooterVel = net_phys__currentStateVelocity
  let shooterPos = transform[3]

  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=controlledByAiGunner)] (turret_ai__atackTarget : EntityId;
                                                           turret_ai__chaseTarget : EntityId;
                                                           var turret_aim__shootToPos : float3&)
      if turret_ai__atackTarget != INVALID_ENTITY_ID || turret_ai__chaseTarget == INVALID_ENTITY_ID
        return

      let target = get_target_pos(shooterPos, shooterVel, gunEid, turret_ai__chaseTarget)
      if target.active
        turret_aim__shootToPos = target.pos

[es(tag=server, REQUIRE=turret_ai__automatic, on_appear)]
def turret_ai_automatic_set_owner(evt : Event; turret__owner : EntityId; var gun__owner : EntityId&)
  gun__owner = turret__owner

[es(tag=server, before=launch_projectile_es)]
def turret_ai_set_time_fuze(evt : CmdLaunchProjectile; transform : float3x4; net_phys__currentStateVelocity : float3 = float3())
  query(evt.gunEid) <| $ [es] (turret_aim__target : EntityId; var gun__fuzeDistance : float&)
    if !!turret_aim__target
      let target = get_target_pos(transform[3], net_phys__currentStateVelocity, evt.gunEid, turret_aim__target)
      if target.active
        gun__fuzeDistance = distance(target.pos, evt.launchDesc.tm[3])

[es(tag=server, REQUIRE=turret_control__hasAiGunners, after=turret_ai_gunner_aim, before=turret_aim_pos_to_wish_dir_es)]
def turret_ai_trigger_group(evt : CmdTurretsUpdate;
                            turret_control__gunEids : EidList)
  for aiGunEid in turret_control__gunEids
    query(aiGunEid) <| $ [es(REQUIRE=(resolvedTurret, controlledByAiGunner), REQUIRE_NOT=turret__ignoreGroupTrigger)] (turret__groupHash aka ai_turret__groupHash : int;
                                                                                                                       turret_aim__shootToPos aka ai_turret_aim__shootToPos : float3;
                                                                                                                       turret_aim__shootFlag aka ai_turret_aim__shootFlag : bool;
                                                                                                                       turret_aim__target aka ai_turret_aim__target : EntityId)
      for gunEid in turret_control__gunEids
        query(gunEid) <| $ [es(REQUIRE=resolvedTurret, REQUIRE_NOT=controlledByAiGunner)] (turret__groupHash : int;
                                                                                           var turret_aim__shootToPos : float3&;
                                                                                           var turret_aim__shootFlag : bool&;
                                                                                           var turret_aim__target : EntityId&)
          if turret__groupHash == ai_turret__groupHash
            turret_aim__shootToPos = ai_turret_aim__shootToPos
            turret_aim__shootFlag = ai_turret_aim__shootFlag
            turret_aim__target = ai_turret_aim__target
