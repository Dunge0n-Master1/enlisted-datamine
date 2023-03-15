require ecs
require ecs.common
require app
require common_shooter.events_common_shooter
require common_shooter.es.weapon.turret_common
require enlisted.events_enlisted
require vehicle
require turrets
require EnlistedNet
require math.base
require math.shooter_phys_common
require game.es.events
require debug.logerr_once
require DagorMathUtils
require EnlistedWeapon
require EnlistedActor
require EnlistedPhys
require Dacoll
require DaWeapons
require GridCollision
require AnimV20
require GeomNodeTree
require GameMath
require DagorMath
require Gun
require BitStream
require game.utils.hero
require EnlistedWeapon
require BallisticsProps
require DaWeaponProps


[es]
def vehicle_input_turret_es(evt : CmdTurretsUpdate;
                            net_phys__currentStatePosition : float3&;
                            turret_control__gunEids : EidList;
                            vehicle__localControls : VehicleControlsState const? = null;
                            vehicle__allAcquiredControls : VehicleControlsState const? = null)
  if vehicle__localControls == null && vehicle__allAcquiredControls == null
    return

  assume controlsState = vehicle__localControls != null ? *vehicle__localControls : *vehicle__allAcquiredControls

  let shootFromPos = net_phys__currentStatePosition + float3(0.0, 2.0, 0.0)

  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (turret__id : int;
                                                     turret_aim__shootAngles : float2&;
                                                     var turret_aim__shootToPos : float3&)
      if !controlsState |> can_control_turret(turret__id)
        return

      let shootDir = angles_to_dir(turret_aim__shootAngles)
      turret_aim__shootToPos = shootFromPos + shootDir * AIM_DISTANCE


[es(after=vehicle_input_turret_es, before=turret_direction_control_es)]
def apply_turret_aim_pos_to_remote_wish_dir_es(evt : CmdTurretsUpdate;
                                               animchar : AnimcharBaseComponent;
                                               turret_control__gunEids : EidList;
                                               net_phys__role : int;
                                               vehicle__localControls : VehicleControlsState const?)
  // r-shadows get it's turret directions from snapshots
  let isValidNetRole = (net_phys__role != int(NetRole ROLE_REMOTELY_CONTROLLED_SHADOW))
  let isCanControlTurrets = (vehicle__localControls != null && vehicle__localControls.canControlTurrets)
  if isValidNetRole || isCanControlTurrets
    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (turret__emitterNodeId : int;
                                                       turret_aim__shootToPos : float3&;
                                                       var turret_state : TurretState)
        if turret__emitterNodeId < 0
          return

        let nwp = *animchar.nodeTree |> geomtree_getNodeWpos(turret__emitterNodeId)
        let gunDir = normalize(turret_aim__shootToPos - nwp)
        turret_state.remote |> remote_state_setWishDirection(gunDir)


[es(tag=server)]
def turret_save_remote_state_es(evt : CmdTurretsUpdate;
                                turret_control__gunEids : EidList)
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (turret_state : TurretState;
                                                     var turret_state_remote : TurretState)
      turret_state_remote = turret_state


def calc_turret_angles(wish_dir : float3&)
  let wishAngles = dir_to_angles(normalize(wish_dir))
  return float2(-wishAngles.x, wishAngles.y) // -x because dir_to_angles uses negative z (for heading, not true rotation)

[es(tag=gameClient, track=gun__curShellId, on_appear)]
def init_projectile_impulse_for_gun(evt : Event;
                                    gun__curShellId : ShellPropIds;
                                    var gun__curShellImpulse : float&)
  if int(gun__curShellId.ballisticsId) >= 0
    projectile_get_props(int(gun__curShellId.ballisticsId)) <| $(ballisticsProps : ProjectileProps)
      gun__curShellImpulse = (ballisticsProps.velRange.y - ballisticsProps.velRange.x) * 0.5f * ballisticsProps.mass

[es(tag=gameClient)]
def turret_direction_control_remote_es(evt : CmdTurretsUpdate;
                                       net_phys__role : int;
                                       turret_control__gunEids : EidList)
  // Even heroVehicle needs to receive remote turret state, if the player doesn't controll the vehicle.
  if net_phys__role == int(NetRole ROLE_REMOTELY_CONTROLLED_SHADOW)
    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=resolvedTurret, REQUIRE_NOT=turretInput)] (turret_state_remote : TurretState;
                                                                                var turret_state : TurretState&)
        let wishDirection = turret_state_remote.remote.wishDirection
        turret_state.wishAngles = calc_turret_angles(wishDirection)


def turret_direction_control(turret_control__gunEids : EidList)
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (var turret_state : TurretState)
      turret_state.wishAngles = calc_turret_angles(turret_state.remote.wishDirection)


[es(tag=server)]
def turret_direction_control_es(evt : CmdTurretsUpdate;
                                turret_control__gunEids : EidList)
  turret_direction_control(turret_control__gunEids)


[es(tag=netClient, REQUIRE=heroVehicle, after=turret_direction_control_es, before=turret_direction_control_remote_es)]
def turret_direction_control_client_es(evt : CmdTurretsUpdate;
                                       turret_control__gunEids : EidList)
  turret_direction_control(turret_control__gunEids)


[es(tag=server, track=phys__lowFreqTickrate, REQUIRE=phys__lowFreqTickrate)]
def turret_weap_on_tickrate_changed_es(evt : Event;
                                       turret_control__gunEids : EidList)
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es] (var turret_controls_history : TurretControlsHistory)
      turret_controls_history.history |> clear()


[es(tag=(netClient, input))]
def turret_input_client_es(info : UpdateStageUpdateInput;
                           net_phys__currentStatePosition : float3;
                           vehicle__localControls : VehicleControlsState;
                           turret_control__gunEids : EidList;
                           turret_state__atTick : int;
                           var turret_input__prevCmdSendTick : int&)
  var controlledHero = INVALID_ENTITY_ID
  query() <| $ [es(REQUIRE=hero)] (eid : EntityId)
    controlledHero = eid
  if !controlledHero
    return

  let curTime = info.curTime
  let curTick = int(curTime * float(PHYS_DEFAULT_TICKRATE))
  if int(vehicle__localControls.turretsMask) == 0 || turret_input__prevCmdSendTick >= curTick
    return

  let conn = get_server_conn()
  if conn == null
    return

  using() <| $(var bs : BitStream)
    var turretCount = uint8(0)
    bs |> Write(turretCount)
    bs |> WriteCompressed(uint(turret_state__atTick))

    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=(resolvedTurret, turretInput))] (eid : EntityId;
                                                                      turret_input__shootFlag : bool;
                                                                      turret_input__aimPos : float3;
                                                                      turret_aim__shootDirWithCorrection : float3;
                                                                      turret_state : TurretState;
                                                                      turret_input__isLocalControlLocked : bool = false;
                                                                      var turret_aim__shootAngles : float2&;
                                                                      var turret_aim__shootFlag : bool&)
        let dir = angles_to_dir(turret_state.angles)
        var tdirp = pack_unit_vec_uint(dir, 30u)

        if turret_input__isLocalControlLocked
          turret_aim__shootFlag = false
          turretCount = uint8(int(turretCount) + 1)
          bs |> Write(eid)
          bs |> Write(tdirp)
          return

        let aimPos = turret_input__aimPos
        let shootFlag = turret_input__shootFlag

        turret_aim__shootAngles = turret_calc_shoot_angles(net_phys__currentStatePosition, aimPos)
        turret_aim__shootFlag = shootFlag

        // Note: 30th bit is free
        tdirp |= shootFlag ? (1u << 31u) : 0u

        turretCount = uint8(int(turretCount) + 1)
        bs |> Write(eid)
        bs |> Write(tdirp)
        if shootFlag
          bs |> Write(turret_aim__shootDirWithCorrection)
          bs |> Write(turret_state.shoot.vel)
          bs |> Write(turret_state.shoot.pos)

    bs |> WriteAt(turretCount, 0u)
    send_turret_controls_msg(controlledHero, bs)
    turret_input__prevCmdSendTick = curTick

def turret_apply_client_input(evt : TurretControlsMsg;
                              net__controlsTickDelta : int;
                              turret_control__gunEids : EidList;
                              seat__ownerControls : VehicleControlsState)
  assume bs = evt.bs

  var turretCount = uint8(0)
  var isOk = bs |> Read(turretCount)

  var turretStateTick = 0u
  isOk = bs |> ReadCompressed(turretStateTick) && isOk

  var tdirp = 0u
  for _i in range(int(turretCount))
    var turretEid = INVALID_ENTITY_ID
    isOk = bs |> Read(turretEid) && isOk
    isOk = bs |> Read(tdirp) && isOk
    let shootFlag = (tdirp >> 31u) != 0u
    var shootDir = float3()
    var shootVel = float3()
    var shootPos = float3()
    if shootFlag
      isOk = bs |> Read(shootDir) && isOk
      isOk = bs |> Read(shootVel) && isOk
      isOk = bs |> Read(shootPos) && isOk

    if !isOk
      break

    if find_index(each(turret_control__gunEids), turretEid) < 0
      continue

    query(turretEid) <| $ [es] (turret__id : int; var turret_controls_history : TurretControlsHistory)
      if !can_control_turret(seat__ownerControls, turret__id)
        return
      assume history = turret_controls_history.history
      var latestIndex = int(length(history)) - 1

      if latestIndex >= 0 && history[latestIndex].atTick - int(turretStateTick) > net__controlsTickDelta * 2
        history |> clear()
        latestIndex = -1

      if latestIndex < 0 || int(turretStateTick) > history[latestIndex].atTick
        let tickDiff = latestIndex != -1 ? min(int(turretStateTick) - history[latestIndex].atTick, length(history)) : 1
        let totalcount = history |> capacity()
        if length(history) + tickDiff > totalcount
          history |> erase(0, tickDiff)

        if tickDiff > 1
          latestIndex = int(length(history)) - 1
          if latestIndex >= 0
            using(history[latestIndex]) <| $(var latest : TurretControlsHistoryState#)
              for j in range(1, tickDiff)
                using(latest) <| $(var forgedState : TurretControlsHistoryState#)
                  forgedState.atTick += j
                  history |> push_clone(forgedState)

        using() <| $(var st : TurretControlsHistoryState#)
          let dir = unpack_unit_vec_uint(tdirp, 30u)
          st.shootAngles = dir_to_angles(dir)
          if shootFlag
            st.shootDir = normalize(shootDir)
            st.shootVel = shootVel
            st.shootPos = shootPos
          else
            st.shootDir = float3()
            st.shootVel = float3()
            st.shootPos = float3()
          st.atTick = int(turretStateTick)
          st.shootFlag = shootFlag
          history |> push_clone(st)
  if !isOk
    logerr_once("turret_weap_on_tickrate_changed_es: deserialization failed")

[es(tag=(server, net), after=vehicle_seats_update_controls)]
def turret_apply_client_input_es(evt : TurretControlsMsg; eid : EntityId; human_anim__vehicleSelected : EntityId)
  query(human_anim__vehicleSelected) <| $ [es] (net__controlsTickDelta : int; vehicle_seats__seatEids : EidList; turret_control__gunEids : EidList)
    var found = false
    for seatEid in vehicle_seats__seatEids
      query(seatEid) <| $ [es] (seat__ownerControls : VehicleControlsState; seat__ownerEid : EntityId)
        if seat__ownerEid != eid
          return
        found = true
        turret_apply_client_input(evt, net__controlsTickDelta, turret_control__gunEids, seat__ownerControls)
      if found
        return

[es(on_appear, REQUIRE=resolvedTurret)]
def turret_init_shoot_node(evt : Event;
                           turret__owner : EntityId;
                           gun__shootNodeName : string;
                           var turret__shootNodeId : int&)
  query(turret__owner) <| $ [es] (animchar : AnimcharBaseComponent)
    turret__shootNodeId = geomtree_findNodeIndex(*animchar.nodeTree, gun__shootNodeName)

def turret_shoot_tm_save(animchar : AnimcharBaseComponent;
                         isAlive : bool;
                         turret_control__gunEids : EidList;
                         net_phys__currentStateVelocity : float3)
  if isAlive
    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (gun : Gun;
                                                       turret__shootNodeId : int = -1;
                                                       turret__aimWithShootNode : Tag const?;
                                                       var turret_state : TurretState)
        var dir = float3(1, 0, 0)
        if turret__aimWithShootNode != null && turret__shootNodeId >= 0
          var tm : float3x4
          *animchar.nodeTree |> geomtree_getNodeWtmRelScalar(turret__shootNodeId, tm)
          dir = tm[0]
        else
          dir = angles_to_dir(turret_state.angles)

        var shootTm = IDENT_TM
        gun.shootNodeData |> gun_shoot_node_data_calcShootTm(dir, shootTm)
        turret_state.shoot.dir = shootTm[0]
        turret_state.shoot.pos = shootTm[3]
        turret_state.shoot.vel = net_phys__currentStateVelocity
        if abs(1.0 - length(turret_state.shoot.dir)) >= 1e-4
          logerr("turret_shoot_tm_save_es: dir={turret_state.shoot.dir}")

[es(tag=server)]
def turret_shoot_tm_save_es(evt : CmdTurretsUpdate;
                            isAlive : bool = true;
                            animchar : AnimcharBaseComponent;
                            turret_control__gunEids : EidList;
                            net_phys__currentStateVelocity : float3)
  turret_shoot_tm_save(animchar, isAlive, turret_control__gunEids, net_phys__currentStateVelocity)

[es(tag=server, REQUIRE_NOT=deadEntity, after=(turret_shoot_tm_save_es, turret_set_angles_es), before=turret_weap_updater_es)]
def turret_server_aim(evt : CmdTurretsUpdate;
                      turret_control__gunEids : EidList)
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=(resolvedTurret, turret_serverAim))] (var turret_state : TurretState; turret__serverCosDeviationThreshold : float = 0.984 /*~10 deg*/)
      let wishDir = angles_to_dir(float2(-turret_state.wishAngles.x, turret_state.wishAngles.y))
      if dot(turret_state.shoot.dir, wishDir) > turret__serverCosDeviationThreshold
        turret_state.shoot.dir = wishDir

[es(tag=netClient, REQUIRE=heroVehicle, after=turret_shoot_tm_save_es, before=turret_weap_drivers_updater_es)]
def turret_shoot_tm_save_client_es(evt : CmdTurretsUpdate;
                                   animchar : AnimcharBaseComponent;
                                   isAlive : bool = true;
                                   turret_control__gunEids : EidList;
                                   net_phys__currentStateVelocity : float3)
  turret_shoot_tm_save(animchar, isAlive, turret_control__gunEids, net_phys__currentStateVelocity)


[es(tag=gameClient, after=turret_shoot_tm_save_es, before=turret_weap_updater_es, REQUIRE=heroVehicle, REQUIRE_NOT=turretsCorrection)]
def turret_shoot_without_correction_es(evt : CmdTurretsUpdate;
                                       isAlive : bool = true;
                                       turret_control__gunEids : EidList)
  if isAlive
    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=(resolvedTurret, turretInput))] (turret_state : TurretState;
                                                                      var turret_aim__shootDirWithCorrection : float3&)
        let turretDir = turret_state.shoot.dir
        turret_aim__shootDirWithCorrection = turretDir


[es(tag=gameClient, after=turret_shoot_tm_save_es, before=turret_weap_updater_es)]
def turret_shoot_correction_non_hero_es(evt : CmdTurretsUpdate;
                                        isAlive : bool = true;
                                        turret_control__gunEids : EidList)
  if isAlive
    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=resolvedTurret, REQUIRE_NOT=turretInput)] (turret_state : TurretState;
                                                                                var turret_aim__shootDirWithCorrection : float3&)
        turret_aim__shootDirWithCorrection = turret_state.shoot.dir


def turret_weap_update(gunEid : EntityId;
                       atTime : float)
  query(gunEid) <| $ [es] (turret_state : TurretState;
                           turret_aim__shootFlag : bool;
                           turret_aim__shootDirWithCorrection : float3 const?;
                           turret_serverAim : Tag const?;
                           turret__isUnderwater : bool;
                           turret__isBroken : bool;
                           gun__timeBetweenShotMult : float = 1.0;
                           gun__isOverheat : bool = false)
    let shoot = !gun__isOverheat && turret_aim__shootFlag && !turret__isUnderwater && !turret__isBroken
    let shootDir = turret_serverAim == null && turret_aim__shootDirWithCorrection != null && length_sq(*turret_aim__shootDirWithCorrection) != 0.0 ? *turret_aim__shootDirWithCorrection : turret_state.shoot.dir

    let isForReal = true
    let rndSeed = phys_time_to_seed(atTime)
    using() <| $(var gctr : GunControls#)
      gctr.shoot = shoot
      gctr.boltActionMult = gun__timeBetweenShotMult
      gctr.timeStep = 1. / float(PHYS_DEFAULT_TICKRATE)
      using(turret_state.shoot.dir, shootDir, turret_state.shoot.vel, turret_state.shoot.pos) <| $(var gloc : GunLocation#)
        sendEventImmediate(
          gunEid,
          [[CmdGunUpdate
            atTime=atTime,
            isForReal=isForReal,
            seed=rndSeed,
            gctrl := gctr,
            gloc := gloc]])


[es]
def turret_shooting_es(evt : EventOnTurretShooting;
                       turret_control__gunEids : EidList;
                       isAlive : bool;
                       net_phys__atTick : int;
                       net_phys__timeStep : float)
  if isAlive
    let turretNo = evt.turretNo
    let atTick = net_phys__atTick
    let dt = net_phys__timeStep
    turret_weap_update(turret_control__gunEids[turretNo], float(atTick) * dt)

[es(tag=server)]
def turret_weap_apply_client_controls_es(evt : CmdTurretsUpdate;
                                         isAlive : bool;
                                         turret_control__gunEids : EidList;
                                         net_phys__lastAppliedControlsForTick : int;
                                         net__controlsTickDelta : int)
  if isAlive
    let tick = net_phys__lastAppliedControlsForTick - net__controlsTickDelta

    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (turret_controls_history : TurretControlsHistory;
                                                       var turret_aim__atTick : int&;
                                                       var turret_aim__shootAngles : float2&;
                                                       var turret_aim__shootFlag : bool&)
        let historyState = turret_controls_history |> turret_controls_history_findState(tick)
        if historyState == null
          return

        turret_aim__shootAngles = historyState.shootAngles
        turret_aim__shootFlag = historyState.shootFlag
        turret_aim__atTick = historyState.atTick


[es]
def turret_weap_updater_es(evt : CmdTurretsUpdate;
                           turret_control__gunEids : EidList;
                           isAlive : bool;
                           net_phys__timeStep : float;
                           net_phys__atTick : int;
                           net_phys__lastAppliedControlsForTick : int;
                           net__controlsTickDelta : int;
                           net_phys__role : int;
                           var turret_state__atTick : int&)
  if isAlive
    let dt = net_phys__timeStep
    let tick = net_phys__lastAppliedControlsForTick
    let vehicleTick = net_phys__atTick
    let serverTick = net_phys__lastAppliedControlsForTick - net__controlsTickDelta

    turret_state__atTick = (net_phys__role == int(NetRole ROLE_REMOTELY_CONTROLLED_SHADOW) ?
                            nearest_physics_tick_number(get_sync_time(), dt) :
                            tick)

    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (turret_aim__shootFlag : bool;
                                                       turret_controls_history : TurretControlsHistory const?;
                                                       var turret_state : TurretState)

        if turret_controls_history != null && turret_aim__shootFlag
          let historyState = *turret_controls_history |> turret_controls_history_findState(serverTick)
          if historyState != null
            if (length_sq(turret_state.shoot.pos - historyState.shootPos) < square(0.2) &&
                length_sq(turret_state.shoot.vel - historyState.shootVel) < square(0.04))
              turret_state.shoot.pos = historyState.shootPos
              turret_state.shoot.vel = historyState.shootVel
            let PERMITTED_TURRET_DIR_DIFF = deg_to_rad(16.0)
            let dirDiffCos = dot(historyState.shootDir, turret_state.shoot.dir)
            if dirDiffCos >= cos(PERMITTED_TURRET_DIR_DIFF)
              turret_state.shoot.dir = historyState.shootDir
            elif length_sq(historyState.shootDir) > 1e-12
              // The player attempts to cheat, but this is not always the case, considering
              // fast moving turret, time lag and strong parallax correction we might get too far away from
              // shoot.dir, so at least shoot at pos that's as close at possible to desired one.
              let qa = dir_to_quat(turret_state.shoot.dir)
              let qb = dir_to_quat(historyState.shootDir)
              turret_state.shoot.dir = slerp(qa, qb, PERMITTED_TURRET_DIR_DIFF / acos(dirDiffCos)) |> quat_get_forward()
            else
              return // Ignore 0 or NaN dir
        turret_weap_update(gunEid, float(vehicleTick) * dt)


[es(tag=gameClient, after=after_collision_sync, REQUIRE=vehicleWithWatched)]
def turret_update_visual_shoot_tm_es(evt : ParallelUpdateFrameDelayed;
                                     turret_control__gunEids : EidList;
                                     net_phys__interpK : float;
                                     var turret_current_visual_shoot_tm : float3x4)
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=(resolvedTurret, firstWatchedTurret))] (gun : Gun)
      turret_current_visual_shoot_tm = gun |> gun_lerpGunTmWithK(net_phys__interpK)


[es(tag=(gameClient, net))]
def turret_weap_net_es(evt : TurretShotShellMsg;
                       vehicle__localControls : VehicleControlsState;
                       turret_control__gunEids : EidList)
  let turretNo = evt.turretNo
  if turretNo < length(turret_control__gunEids)
    let gunEid = turret_control__gunEids[turretNo]
    if gunEid != INVALID_ENTITY_ID && !vehicle__localControls |> canControlTurret(uint(turretNo))
      sendEvent(
          gunEid,
          [[CmdNetShot
            shellId=evt.shellId,
            damageId=evt.damageId,
            ballisticsId=evt.ballisticsId,
            gunPropsId=evt.gunPropsId,
            atTime=evt.atTime,
            initialLifeTime=evt.initialLifeTime,
            tm=evt.tm,
            vel=evt.vel,
            firingMode=evt.firingMode,
            bombBayHeight=evt.bombBayHeight]])