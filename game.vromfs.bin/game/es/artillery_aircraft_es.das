require ecs
require app
require math.base
require game.es.events
require enlisted.events_enlisted
require common_shooter.events_common_shooter
require turrets
require Gun
require DaWeapons
require DagorMath
require DagorMathUtils
require DagorRandom
require Dacoll
require GamePhys
require DngPhys
require Plane
require DngPlane
require DngActor
require game.es.artillery_aircraft_common
require game.es.turrets_common

[es(tag=server, no_order, REQUIRE=requested_aircraft)]
def aircraft_request_distance_lifetime_es(info : UpdateStageInfoAct;
                                          eid : EntityId;
                                          ai_aircraft__state : int;
                                          ai_aircraft__endPos : float3;
                                          ai_aircraft__minDistToHide : float;
                                          transform : float3x4)
  if ai_aircraft__state == int(AIAircraftState FLY_TO_END) && length_sq(transform[3].xz - ai_aircraft__endPos.xz) < square(ai_aircraft__minDistToHide)
    destroyEntity(eid)

[es(tag=server, no_order)]
def aircraft_request_lifetime_es(info : UpdateStageInfoAct;
                                 eid : EntityId;
                                 artillery__deadTime : float;
                                 aircraft_request__targetMarks : EidList)
  if artillery__deadTime < info.curTime
    for targetMarkEid in aircraft_request__targetMarks
      destroyEntity(targetMarkEid)

    destroyEntity(eid)

[es(on_disappear, tag=server)]
def on_aircraft_request_destroyed(evt : Event;
                                  aircraft_request__targetMarks : EidList;
                                  aircraft_request__spawnedAircrafts : EidList)
  for targetMarkEid in aircraft_request__targetMarks
    destroyEntity(targetMarkEid)

  for aircraftEid in aircraft_request__spawnedAircrafts
    query(aircraftEid) <| $ [es] (ai_aircraft__endPos : float3;
                                  var ai_aircraft__state : int&;
                                  var ai_aircraft__flyPos : float3&)
      ai_aircraft__state = int(AIAircraftState FLY_TO_END)
      ai_aircraft__flyPos = ai_aircraft__endPos

[es(on_disappear, tag=server, REQUIRE=requested_aircraft, REQUIRE_NOT=deadEntity)]
def aircraft_request_on_aircraft_destroyed(evt : Event;
                                           requested_aircraft__aircraftRequesterEid : EntityId)
  query(requested_aircraft__aircraftRequesterEid) <| $ [es] (var aircraft_request__spawnedAircraftsCount : int&;
                                                             aircraft_request__targetMarks : EidList)
    aircraft_request__spawnedAircraftsCount -= 1

    if aircraft_request__spawnedAircraftsCount == 0
      for targetMarkEid in aircraft_request__targetMarks
        destroyEntity(targetMarkEid)
      destroyEntity(requested_aircraft__aircraftRequesterEid)

[es(tag=server, no_order)]
def aircraft_request_spawn_airplane_delayed_es(info : UpdateStageInfoAct;
                                               eid : EntityId;
                                               artillery__offender : EntityId;
                                               aircraft_request__aircraftStartRelativeSpeed : float;
                                               aircraft_request__aircraftAfterBombingHeight : float;
                                               aircraft_request__aircraftBombingHeight : float;
                                               aircraft_request__aircraftTemplate : string;
                                               aircraft_request__aircraftSpawnDistance : float;
                                               aircraft_request__aircraftSpawnDelaySec : float;
                                               aircraft_request__spawnDelayedTemplate : string;
                                               aircraft_request__originTm : float3x4;
                                               var aircraft_request__aircraftLeader : EntityId&;
                                               var aircraft_request__spawners : EidList&;
                                               var aircraft_request__aircraftNextSpawnSec : float&;
                                               var aircraft_request__spawnedAircrafts : EidList&)
  if length(aircraft_request__spawners) <= 0
    removeSubTemplate(eid, aircraft_request__spawnDelayedTemplate)
    return

  aircraft_request__aircraftNextSpawnSec -= info.dt
  if aircraft_request__aircraftNextSpawnSec > 0.
    return
  aircraft_request__aircraftNextSpawnSec = aircraft_request__aircraftSpawnDelaySec

  query(artillery__offender) <| $ [es] (team aka owner_team : int)
    assume originTm = aircraft_request__originTm
    query(aircraft_request__spawners[0]) <| $ [es] (aircraft_request_spawner__bias : float3)
      assume bias = aircraft_request_spawner__bias
      let origPoint = originTm[3] + bias.x * originTm[0] + bias.y * originTm[1] + bias.z * originTm[2]
      var spawnPos = origPoint - originTm[0] * aircraft_request__aircraftSpawnDistance
      var aircraftStartRelativeSpeed = aircraft_request__aircraftStartRelativeSpeed

      query(aircraft_request__aircraftLeader) <| $ [es] (transform : float3x4; plane_net_phys : PlaneActor)
        assume phys = plane_net_phys.phys
        aircraftStartRelativeSpeed = (phys.speed - phys.Vmin) / (phys.Vmax - phys.Vmin)
        spawnPos = transform[3] + bias.x * originTm[0] + bias.y * originTm[1] + bias.z * originTm[2]

      let endPos   = float3(origPoint.x, aircraft_request__aircraftAfterBombingHeight, origPoint.z) + originTm[0] * aircraft_request__aircraftSpawnDistance

      let flyToPos = float3(origPoint.x, aircraft_request__aircraftBombingHeight, origPoint.z)

      let trgPos2D = origPoint.xz
      let trgPos3D = float3(trgPos2D.x, traceht_lmesh(trgPos2D), trgPos2D.y)

      let aircraftEid = createEntity(aircraft_request__aircraftTemplate) <| $(var init : ComponentsInitializer)
        set(init, "team", team)

        set(init, "startVelDir", float3(1.f, 0.f, 0.f))
        set(init, "startRelativeSpeed", aircraftStartRelativeSpeed)

        set(init, "requested_aircraft__aircraftRequesterEid", eid)

        set(init, "ai_aircraft__endPos", endPos)
        set(init, "ai_aircraft__flyPos", flyToPos)
        set(init, "ai_aircraft__targetPos", trgPos3D)
        set(init, "redirectProjectileOffender", artillery__offender)
        var tm = originTm
        tm[3] = spawnPos

        set(init, "transform", tm)

      push(aircraft_request__spawnedAircrafts, aircraftEid)

      if !aircraft_request__aircraftLeader
        aircraft_request__aircraftLeader = aircraftEid

    destroyEntity(aircraft_request__spawners[0])
    aircraft_request__spawners |> erase(0)

[es(tag=server, on_appear)]
def aircraft_request_started_es(evt : Event;
                                eid : EntityId;
                                artillery_zone__radius : float;
                                artillery__offender : EntityId;
                                artillery__callerEid : EntityId;
                                artillery__targetPos : float3;
                                artillery__lifeTime : float;
                                var artillery__deadTime : float&;
                                aircraft_request__interval : float;
                                aircraft_request__aircraftSpawnHeight : float;
                                aircraft_request__aircraftTargetMarkTemplate : string;
                                aircraft_request__aircraftBiases : Point3List;
                                aircraft_request__spawnDelayedTemplate : string;
                                aircraft_request__spawnerTemplate : string;
                                var aircraft_request__originTm : float3x4&;
                                var aircraft_request__targetMarks : EidList&;
                                var aircraft_request__spawners : EidList&;
                                var aircraft_request__spawnedAircraftsCount : int&)
  artillery__deadTime = get_sync_time() + artillery__lifeTime

  query(artillery__callerEid) <| $ [es] (team : int;
                                         possessed : EntityId;
                                         var artillery__availableAtTime : float&;
                                         var artillery__lastShotInTime : float&)
    let heroSquad = get_Eid(possessed, "squad_member__squad") ?? INVALID_ENTITY_ID
    let artilleryMulUnlock = get_float(heroSquad, "squad__artilleryTimersMulUnlock") ?? 1.

    let atTime = get_sync_time()

    artillery__availableAtTime = atTime + aircraft_request__interval * artilleryMulUnlock
    artillery__lastShotInTime  = atTime
    query() <| $ [es] (team__id : int;
                       team__aircraftRequestInterval : float;
                       var team__aircraftRequestAvailableAtTime : float&)
      if team__id == team
        team__aircraftRequestAvailableAtTime = atTime + team__aircraftRequestInterval

  query(artillery__offender) <| $ [es] (team aka owner_team : int)
    let dir = calc_aircraft_request_dir(owner_team)
    assume originTm = aircraft_request__originTm
    originTm[0] = float3(dir.y, 0., -dir.x)
    originTm[1] = float3(0., 1., 0.)
    originTm[2] = cross(originTm[0], originTm[1])
    originTm[3] = artillery__targetPos + float3(0., aircraft_request__aircraftSpawnHeight, 0.)

    for bias in aircraft_request__aircraftBiases
      let origPoint = originTm[3] + bias.x * originTm[0] + bias.y * originTm[1] + bias.z * originTm[2]

      let trgPos2D = origPoint.xz
      let trgPos3D = float3(trgPos2D.x, traceht_lmesh(trgPos2D), trgPos2D.y)

      let spawner = createEntity(aircraft_request__spawnerTemplate) <| $(var init : ComponentsInitializer)
        set(init, "team", team)
        set(init, "aircraft_request_spawner__bias", bias)
      aircraft_request__spawners |> push(spawner)

      let targetMarkEid = createEntity(aircraft_request__aircraftTargetMarkTemplate) <| $(var init : ComponentsInitializer)
        set(init, "artillery__targetPos", trgPos3D)
        set(init, "artillery_zone__radius", artillery_zone__radius)

      push(aircraft_request__targetMarks, targetMarkEid)

    aircraft_request__spawnedAircraftsCount = length(aircraft_request__aircraftBiases)
  addSubTemplate(eid, aircraft_request__spawnDelayedTemplate)

def calc_ballistic_end_pos(vel : float3;
                           pos : float3;
                           alt : float;
                           var outPos : float3&;
                           var airTime : float&)
  let velSq = length_sq(vel)
  let velVl = sqrt(velSq)

  let eps = 0.001

  if velSq < eps
    return false

  let dir = normalize(vel)

  let dsc = (velSq * square(dir.y) + 2. * gravity() * (pos.y - alt))

  if dsc < 0.001
    return false

  airTime = (velVl * dir.y + sqrt(dsc)) / gravity()

  let dxz = normalize(float3(dir.x, 0., dir.z))

  let airLen = velVl * dot(dxz, dir) * airTime

  outPos = pos + dxz * airLen
  outPos.y = alt

  return true

def calc_ballistic_speed_for_dist(dst : float;
                                  dir : float3;
                                  pos : float3;
                                  alt : float)
  let cosDir = dot(normalize(float3(dir.x, 0., dir.z)), dir)
  let sinDir = dir.y

  let c = dst * gravity()

  return safediv(c, sqrt(abs(2. * cosDir * sinDir * c + 2. * cosDir * cosDir * gravity() * (pos.y - alt))))

def turret_shoot(gunEid : EntityId;
                 vel : float3;
                 dir : float3;
                 pos : float3;
                 atTime : float)
  query(gunEid) <| $ [es] (gun__timeBetweenShotMult : float = 1.0)
    using() <| $(var gctr : GunControls#)
      gctr.shoot          = true
      gctr.boltActionMult = gun__timeBetweenShotMult
      gctr.timeStep       = 1. / float(PHYS_DEFAULT_TICKRATE)

      using(dir, dir, vel, pos) <| $(var gloc : GunLocation#)
        sendEventImmediate(gunEid,
                         [[CmdGunUpdate
                           atTime   =atTime,
                           isForReal=true,
                           seed     =phys_time_to_seed(atTime),
                           gctrl   := gctr,
                           gloc    := gloc]])

[es(tag=server)]
def change_requested_aircraft_fly_pos(evt : EventRequestedAircraftShootAllBombs)
  query(evt.aircraftEid) <| $ [es] (ai_aircraft__endPos : float3;
                                    var ai_aircraft__flyPos : float3&)
    ai_aircraft__flyPos = ai_aircraft__endPos

[es(tag=server)]
def change_artillery_life_time(evt : EventRequestedAircraftShootAllBombs)
  query(evt.aircraftEid) <| $ [es] (requested_aircraft__aircraftRequesterEid : EntityId;
                                    ai_aircraft__lastTimeToTarget : float)
    query(requested_aircraft__aircraftRequesterEid) <| $ [es] (artilleryLifeTimeAfterBombing : float;
                                                               var artillery__deadTime : float&)
      artillery__deadTime = get_sync_time() + ai_aircraft__lastTimeToTarget + artilleryLifeTimeAfterBombing

[es(tag=server, before=turret_weap_updater_es, after=turret_weap_reset_shoot, REQUIRE=requested_aircraft, REQUIRE_NOT=deadEntity)]
def ai_aircraft_try_to_start_bombing_es(evt : CmdTurretsUpdate;
                                        requested_aircraft__aircraftRequesterEid : EntityId;
                                        ai_aircraft__shootOffset : float3;
                                        ai_aircraft__targetPos : float3;
                                        var ai_aircraft__state : int&;
                                        var ai_aircraft__lastDstSqToTarget : float&;
                                        var ai_aircraft__lastShootVelocity : float3&;
                                        var ai_aircraft__lastHitPosition : float3&;
                                        plane_net_phys : PlaneActor;
                                        transform : float3x4)
  if ai_aircraft__state != int(AIAircraftState FLY_TO_TARGET)
    return

  query(requested_aircraft__aircraftRequesterEid) <| $ [es] (artillery_zone__radius : float)
    let startPos = transform[3] - ai_aircraft__shootOffset
    let planeVel = float3(plane_net_phys.phys.vel)
    let velDir2D = transform[0].xz
    let bombVel  = normalize(float3(velDir2D.x, normalize(planeVel).y, velDir2D.y)) * length(planeVel)

    var hitPos = float3()
    var airTime = 0.

    if calc_ballistic_end_pos(bombVel, startPos, ai_aircraft__targetPos.y, hitPos, airTime)
      let distToTarget2DSq = length_sq(hitPos.xz - ai_aircraft__targetPos.xz)
      if distToTarget2DSq < square(artillery_zone__radius) && (ai_aircraft__lastDstSqToTarget < 0. || distToTarget2DSq <= ai_aircraft__lastDstSqToTarget)
        ai_aircraft__lastDstSqToTarget = distToTarget2DSq
        ai_aircraft__lastShootVelocity = bombVel
        ai_aircraft__lastHitPosition = hitPos

        return

    if ai_aircraft__lastDstSqToTarget >= 0.
      ai_aircraft__state = int(AIAircraftState FLY_BOMBING)

[es(tag=server, before=turret_weap_updater_es, after=turret_weap_reset_shoot, REQUIRE=requested_aircraft, REQUIRE_NOT=deadEntity)]
def ai_aircraft_bombing_es(evt : CmdTurretsUpdate;
                           eid : EntityId;
                           net_phys__atTick : int;
                           net_phys__timeStep : float;
                           turret_control__gunEids : EidList;
                           ai_aircraft__shoot_angles : float2;
                           ai_aircraft__shootOffset : float3;
                           ai_aircraft__lastShootVelocity : float3;
                           ai_aircraft__lastHitPosition : float3;
                           ai_aircraft__timeBetweenBombDrops : float2;
                           ai_aircraft__targetPos : float3;
                           requested_aircraft__aircraftRequesterEid : EntityId;
                           transform : float3x4;
                           var ai_aircraft__state : int&;
                           var ai_aircraft__bombDropsTimer : float&;
                           var ai_aircraft__lastTimeToTarget : float&)
  if ai_aircraft__state != int(AIAircraftState FLY_BOMBING)
    return

  let curTime = get_sync_time()
  if curTime < ai_aircraft__bombDropsTimer
    return

  ai_aircraft__bombDropsTimer = curTime + rnd_float(ai_aircraft__timeBetweenBombDrops.x, ai_aircraft__timeBetweenBombDrops.y)

  query(requested_aircraft__aircraftRequesterEid) <| $ [es] (artillery_zone__bombingRadius : float)
    var bombGunCount = 0
    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=ai_bomb_launcher)]
        bombGunCount += 1

    let distBetweenShots = artillery_zone__bombingRadius * 2. / float(bombGunCount + 1)

    var dist = 0.
    for gunEid in turret_control__gunEids
      var isShooted = false

      query(gunEid) <| $ [es(REQUIRE=ai_bomb_launcher)] (gun__ammo : int)
        dist += distBetweenShots

        if gun__ammo == 0
          return

        let bombPos = transform[3] - ai_aircraft__shootOffset

        let velDir = normalize(ai_aircraft__lastShootVelocity)
        let velVal = calc_ballistic_speed_for_dist(length(transform[3].xz - ai_aircraft__lastHitPosition.xz) - artillery_zone__bombingRadius + dist,
                                                   velDir, bombPos, ai_aircraft__targetPos.y)

        let bombDir = normalize(float3(velDir.x, -rnd_float(ai_aircraft__shoot_angles.x, ai_aircraft__shoot_angles.y), velDir.z))

        let bombVel = velDir * velVal

        var hitPos = float3()
        var airTime = 0.

        if calc_ballistic_end_pos(bombVel, bombPos, ai_aircraft__targetPos.y, hitPos, airTime)
          ai_aircraft__lastTimeToTarget = airTime

        turret_shoot(gunEid, bombVel, bombDir, bombPos, float(net_phys__atTick) * net_phys__timeStep)

        isShooted = true

      if isShooted
        return

    ai_aircraft__state = int(AIAircraftState FLY_TO_END)

    broadcastEvent([[EventRequestedAircraftShootAllBombs aircraftEid=eid]])

def calculate_pid_value(input : float;
                        origin : float;
                        pid : float3;
                        minVal : float;
                        maxVal : float;
                        dt : float;
                        var intError : float&;
                        var prvError : float&)
  let curError   = (origin   - input)

  let deltaError = (curError - prvError) / dt

  intError = clamp(intError + curError * dt * pid.y, minVal, maxVal)

  prvError = curError

  return clamp(curError * pid.x + intError + deltaError * pid.z, minVal, maxVal)

def ai_aircraft_autopilot_impl(aircraft_eid : EntityId)
  query(aircraft_eid) <| $ [es] (ai_aircraft__speedPidK : float3;
                                 ai_aircraft__rollPidK : float3;
                                 ai_aircraft__pitchPidK : float3;
                                 ai_aircraft__yawPidK : float3;
                                 var ai_aircraft__speedPrevError : float&;
                                 var ai_aircraft__speedError : float&;
                                 var ai_aircraft__rollPrevError : float&;
                                 var ai_aircraft__rollError : float&;
                                 var ai_aircraft__yawPrevError : float&;
                                 var ai_aircraft__yawError : float&;
                                 var ai_aircraft__pitchPrevError : float&;
                                 var ai_aircraft__pitchError : float&;
                                 var plane_net_phys : PlaneActor&;
                                 ai_aircraft__wishSpeed : float;
                                 ai_aircraft__flyPos : float3;
                                 transform : float3x4)
    let dt = plane_net_phys.phys.timeStep

    let valRoll = calculate_pid_value(plane_net_phys.phys.currentState.location.O.roll,
                                      0., ai_aircraft__rollPidK, -180., +180., dt,
                                      ai_aircraft__rollError, ai_aircraft__rollPrevError)

    let aircraftAng = dir_to_angles(transform[0])
    let targetAng   = dir_to_angles(normalize(ai_aircraft__flyPos - float3(plane_net_phys.phys.currentState.location.P)))

    let angPitch = rad_to_deg(renorm_ang(aircraftAng.y, targetAng.y) - targetAng.y)

    let valPitch = calculate_pid_value(angPitch, 0., ai_aircraft__pitchPidK, -180., +180., dt,
                                      ai_aircraft__pitchError, ai_aircraft__pitchPrevError)

    plane_net_phys.phys |> flight_model_setAileronControl(valRoll)
    plane_net_phys.phys |> flight_model_setElevatorControl(valPitch)

    let ang = rad_to_deg(renorm_ang(aircraftAng.x, targetAng.x) - targetAng.x)

    let valYaw = calculate_pid_value(ang, 0., ai_aircraft__yawPidK, -180., +180.,
                                    dt, ai_aircraft__yawError, ai_aircraft__yawPrevError)

    plane_net_phys.phys |> flight_model_setRudderControl(valYaw)

    let powerControll = calculate_pid_value(length(float3(plane_net_phys.phys.vel)), ai_aircraft__wishSpeed,
                                            ai_aircraft__speedPidK, +0., +180., dt,
                                            ai_aircraft__speedError, ai_aircraft__speedPrevError)

    plane_net_phys.phys |> flight_model_setPowerControlAll(powerControll)

[es(tag=server, no_order, REQUIRE=ai_aircraft, REQUIRE_NOT=(deadEntity, clientAiAircraft))]
def ai_aircraft_autopilot_server_es(info : CmdPostPhysUpdate; eid : EntityId)
  ai_aircraft_autopilot_impl(eid)

[es(tag=gameClient, no_order, REQUIRE=(ai_aircraft, clientAiAircraft), REQUIRE_NOT=deadEntity)]
def ai_aircraft_autopilot_client_es(info : CmdPostPhysUpdate; eid : EntityId)
  // paratroopersAircraft is controlled from the client to allow it to have LOCALLY_CONTROLED_ net role
  ai_aircraft_autopilot_impl(eid)

[es(tag=gameClient, after=update_projectile_es, REQUIRE=ai_bomb_projectile)]
def update_bomb_projectile_es(info : ParallelUpdateFrameDelayed;
                              projectile__visualPos : float3;
                              launch_desc : LaunchDesc;
                              projectile__stopped : bool;
                              projectile__exploded : bool;
                              var transform : float3x4&)
  if !projectile__stopped && !projectile__exploded
    transform    = launch_desc.tm
    transform[3] = projectile__visualPos

def set_ai_machine_gun_owner(turret_eids, seat_eids)
  for turretEid in turret_eids
    query(turretEid) <| $ [es(REQUIRE_NOT=gun__isLauncher)] (turret__id : int;
                                                             var gun__owner : EntityId&;
                                                             var turret__isControlledByAi : bool&)
      let gunOwner = find_gun_owner(turret__id, seat_eids)
      gun__owner   = gunOwner.eid

      turret__isControlledByAi = true

[es(on_event=(EventOnGunCreated, EventOnSeatOwnersChanged), REQUIRE=ai_aircraft)]
def ai_turret_gun_owners_on_change(evt : Event;
                                   turret_control__gunEids : EidList;
                                   vehicle_seats__seatEids : EidList)
  set_ai_machine_gun_owner(turret_control__gunEids, vehicle_seats__seatEids)

[es(track=seat__ownerControls, REQUIRE=seat__ownerControls)]
def ai_seats_controls_on_change(evt : Event;
                                seat__vehicleEid : EntityId)
  query(seat__vehicleEid) <| $ [es(REQUIRE=ai_aircraft)] (turret_control__gunEids, vehicle_seats__seatEids : EidList)
    set_ai_machine_gun_owner(turret_control__gunEids, vehicle_seats__seatEids)

[es(REQUIRE=(requested_aircraft, redirectProjectileOffender))]
def on_ai_bomb_launcher_created(evt : EventOnGunCreated;
                                eid : EntityId)
  query(evt.gunEid) <| $ [es(REQUIRE=gun__isLauncher)] (var gun__owner : EntityId&;
                                                        var turret__isControlledByAi : bool&)
    gun__owner = eid
    turret__isControlledByAi = false

[es(REQUIRE=ai_bomb_projectile)]
def on_ai_bomb_projectile_hit(evt : EventProjectileHitScene;
                              launch_desc : LaunchDesc;
                              var transform : float3x4&)
  transform    = launch_desc.tm
  transform[3] = evt.pos
