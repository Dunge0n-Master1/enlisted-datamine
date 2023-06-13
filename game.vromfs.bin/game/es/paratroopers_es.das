require ecs
require app
require enlisted.events_enlisted
require game.es.vehicle.vehicle_events
require enlisted.game.es.spawn_soldier_events
require game.es.artillery_aircraft_common
require enlisted.game.es.enlisted_squad_common
require game.es.squad_order_common
require DngActor
require DngNet
require DngPlane
require common_shooter.es.human.human_parachute_common
require DagorRandom
require game.utils.team
require DagorMathUtils
require AnimV20
require player
require game.es.respawn_camera_common
require DagorMath
require math.base
require game.events_game
require game.es.stat_bq_common

[es(tag=server, no_order)]
def kick_paratroopers(info : UpdateStageInfoAct;
                      eid : EntityId;
                      vehicle_seats__seatEids : EidList;
                      paratroopers_aircraft__kickTimePeriod : float;
                      var paratroopers_aircraft__kickTimer : float&)
  if paratroopers_aircraft__kickTimer > 0. && info.curTime > paratroopers_aircraft__kickTimer
    for kickSeatNo in range(length(vehicle_seats__seatEids) - 1)
      let ownerEid = get_Eid(vehicle_seats__seatEids[kickSeatNo], "seat__ownerEid") ?? INVALID_ENTITY_ID
      if !!ownerEid
        reset_squad_mate_behaviour(ownerEid)
        reset_squad_mate_order(ownerEid)
        sendEvent(eid, [[CmdKickFromVehicle eid=ownerEid]])
        paratroopers_aircraft__kickTimer += paratroopers_aircraft__kickTimePeriod
        return
    paratroopers_aircraft__kickTimer = -1.

[es(tag=server, REQUIRE=eid)] // required any component, otherwise system without components
def kick_paratroopers_supply_box(evt : CmdStartParatroopersExit)
  query(evt.aircraftEid) <| $ [es] (paratroopers_aircraft__kickSupplyBoxDelay : float; var paratroopers_aircraft__kickSupplyBoxAtTime : float&)
    if paratroopers_aircraft__kickSupplyBoxAtTime < 0.0
      paratroopers_aircraft__kickSupplyBoxAtTime = get_sync_time() + paratroopers_aircraft__kickSupplyBoxDelay

[es(tag=server)]
def kick_paratroopers_start(evt : CmdKickFromVehicle;
                            paratroopers_aircraft__kickTimePeriod : float;
                            paratroopers_aircraft__kickSupplyBoxDelay : float;
                            var paratroopers_aircraft__kickTimer : float&;
                            var paratroopers_aircraft__kicked : bool&;
                            var paratroopers_aircraft__kickSupplyBoxAtTime : float&)
  if paratroopers_aircraft__kicked || !(get_bool(evt.eid, "isAlive") ?? true)
    return
  let time = get_sync_time()
  paratroopers_aircraft__kicked = true
  paratroopers_aircraft__kickTimer = time + paratroopers_aircraft__kickTimePeriod
  paratroopers_aircraft__kickSupplyBoxAtTime = time + paratroopers_aircraft__kickSupplyBoxDelay

[es(tag=server, after=finalize_soldier_creation)]
def finalize_paratroopers_creation(evt : FinalizeSoldierCreation;
                                   eid : EntityId;
                                   transform : float3x4;
                                   human_anim__vehicleSelected : EntityId;
                                   squad_member__playerEid : EntityId;
                                   squad_member__squad : EntityId;
                                   var horizontal_air_resistance__isOn : bool&;
                                   var squad_member__canBeLeader : bool&;
                                   var human_freefall__animationTemplate : das_string&;
                                   var human_parachute_wind__deadZone : float&;
                                   var human_parachute_wind__paratroopers : bool&;
                                   var human_parachute_wind__landingPoint : float2&;
                                   var human_freefall__gameEffect : EntityId&;
                                   var human_parachute_redeploy__altitude : float&)
  query(human_anim__vehicleSelected) <| $ [es] (paratroopers_aircraft__parachuteTemplate : string)
    human_parachute_redeploy__altitude = 0.
    horizontal_air_resistance__isOn = true
    parachute_create_for_eid(eid, paratroopers_aircraft__parachuteTemplate)
    human_parachute_wind__paratroopers = true
    query(squad_member__playerEid) <| $ [es] (respawner__paratroopersPointCoords : float3)
      human_parachute_wind__landingPoint = respawner__paratroopersPointCoords.xz
    human_parachute_wind__deadZone = 10.
    let squadLeader = get_Eid(squad_member__squad, "squad__leader") ?? INVALID_ENTITY_ID
    if squadLeader == eid
      addSubTemplate(eid, "human_vehicle_custom_exit_animator")
      human_freefall__animationTemplate := "human_freefall_animation_paratroopers"
      human_freefall__gameEffect = createEntity(string(human_freefall__animationTemplate))
    else
      squad_member__canBeLeader = false
      send_net_event(eid, [[RequestPersonalSquadMateOrder
        orderType=int(SquadMateOrder ESMO_USE_VEHICLE),
        orderPosition=transform[3],
        orderUseEntity = human_anim__vehicleSelected
      ]])

[es(on_appear, after=human_input_appear_es)]
def init_paratroopers_look_dir(evt : Event; var human_input__aimAngle : float2&; human_anim__vehicleSelected : EntityId)
  if !has(human_anim__vehicleSelected, "paratroopersAircraft")
    return
  query(human_anim__vehicleSelected) <| $ [es] (transform : float3x4)
    human_input__aimAngle = dir_to_angles(transform[2])


[es(tag=server, REQUIRE=paratroopersAircraft)]
def turn_on_squad_leader_for_paratrooper(evt : CmdKickFromVehicle)
  query(evt.eid) <| $ [es] (var squad_member__canBeLeader : bool&)
    squad_member__canBeLeader = true

[es(tag=server, no_order)]
def paratroopers_kick_distance_es(info : ParallelUpdateFrameDelayed;
                                  eid : EntityId;
                                  transform : float3x4;
                                  vehicle_seats__seatEids : EidList;
                                  ai_aircraft__distToKickParatroopers : float;
                                  ai_aircraft__targetPos : float3;
                                  paratroopers_aircraft__kicked : bool)
  if paratroopers_aircraft__kicked || distance_sq(transform[3].xz, ai_aircraft__targetPos.xz) > ai_aircraft__distToKickParatroopers
    return
  let ownerEid = get_Eid(vehicle_seats__seatEids[0], "seat__ownerEid") ?? INVALID_ENTITY_ID
  if !!ownerEid
    send_net_event(ownerEid, [[CmdStartParatroopersExit aircraftEid=eid]])

[es(tag=server, no_order)]
def paratroopers_kick_timer_es(info : ParallelUpdateFrameDelayed;
                               eid : EntityId;
                               vehicle_seats__seatEids : EidList;
                               paratroopers_aircraft__flyToKickTimer : float;
                               paratroopers_aircraft__kicked : bool)
  if paratroopers_aircraft__kicked || info.curTime < paratroopers_aircraft__flyToKickTimer
    return
  let ownerEid = get_Eid(vehicle_seats__seatEids[0], "seat__ownerEid") ?? INVALID_ENTITY_ID
  if !!ownerEid
    sendEvent(eid, [[CmdKickFromVehicle eid=ownerEid]])

[es(tag=server)]
def paratroopers_spawn_confirmed(evt : CmdParatroopersSpawnConfirm;
                                 var respawner__paratroopersPointCoords : float3&)
  respawner__paratroopersPointCoords = evt.spawnPos


[es(tag=server, on_appear)]
def spawn_paratroopers_squad(evt : Event;
                             eid : EntityId;
                             paratroopers_aircraft__respawnerEid : EntityId;
                             paratroopers_aircraft__squadId : int;
                             paratroopers_aircraft__memberId : int)
  query(paratroopers_aircraft__respawnerEid) <| $ [es] (team aka player_team : int)
    var respawnGroupId = -1
    find_query() <| $ [es] (respawnBaseGroup : int;
                            team aka resp_team : int;
                            respawnbaseType : string;
                            active : bool)
      if resp_team == player_team && respawnbaseType == "human" && active
        respawnGroupId = respawnBaseGroup
        return true
      return false
    sendEvent(paratroopers_aircraft__respawnerEid, [[CmdSpawnSquad team=team,
      possessed=INVALID_ENTITY_ID,
      squadId=paratroopers_aircraft__squadId,
      memberId=paratroopers_aircraft__memberId,
      respawnGroupId=respawnGroupId, existedVehicleEid=eid
    ]])

[es(tag=server, on_appear)]
def delete_aircaft_spawn_point_after_appear(evt : Event; eid : EntityId; team : int)
  query(get_team_eid(team)) <| $ [es] (var paratroopersAircraftSpawnPoints : Object&)
    erase(paratroopersAircraftSpawnPoints, string(uint(eid)))


[es(tag=gameClient)]
def turn_paratroopers_camera(evt : CmdTurnParatroopersCamera;
                             var respawner__paratroopersChooserOn : bool&)
  respawner__paratroopersChooserOn = evt.paratroopersCameraOn
  if !evt.paratroopersCameraOn
    find_query() <| $ [es] (var battle_area__projectionOn : bool&)
      battle_area__projectionOn = false
      return true


[es(tag=gameClient, REQUIRE=eid)]
def respawn_camera_enable_above_on_paratroopers(evt : CmdTurnParatroopersCamera)
  query() <| $ [es] (var respawn_camera__lookSide : bool&)
    respawn_camera__lookSide = !evt.paratroopersCameraOn

[es(tag=server, on_appear, REQUIRE=clientAiAircraft)]
def paratroopers_aircraft_give_client_controls(evt : Event;
                                               var plane_net_phys : PlaneActor&;
                                               var replication : NetObject&;
                                               ownedByPlayer : EntityId)
  if !is_true_net_server()
    return

  plane_net_phys |> plane_actor_setRoleAndTickrateType(NetRole ROLE_REMOTELY_CONTROLLED_AUTHORITY, PhysTickRateType Normal)
  query(ownedByPlayer) <| $ [es] (connid : int)
    net_object_setControlledBy(replication, connid)

[es(tag=netClient, on_appear, REQUIRE=clientAiAircraft)]
def paratroopers_aircraft_make_locally_controllable(evt : Event;
                                                    var plane_net_phys : PlaneActor&;
                                                    var replication : NetObject&;
                                                    ownedByPlayer : EntityId)
  if ownedByPlayer != get_local_player_eid()
    return

  plane_net_phys |> plane_actor_setRoleAndTickrateType(NetRole ROLE_LOCALLY_CONTROLLED_SHADOW, PhysTickRateType Normal)
  let sconn : IConnection? = get_server_conn()
  if sconn != null
    net_object_setControlledBy(replication, connection_getId(*sconn))

[es(REQUIRE=clientAiAircraft)]
def paratroopers_aircraft_set_exit_delay(evt : CmdKickFromVehicle;
                                         var client_ai_aircraft__delayedExit : float&;
                                         client_ai_aircraft__exitDelay : float = 10.f)
  // We delay making the plane server-controlled to keep it in client time, so that animation is synchronized with the jumping paratrooper
  client_ai_aircraft__delayedExit = get_sync_time() + client_ai_aircraft__exitDelay

[es(no_order, REQUIRE=clientAiAircraft)]
def paratroopers_aircraft_make_server_controllable(info : ParallelUpdateFrameDelayed;
                                                   client_ai_aircraft__delayedExit : float;
                                                   eid : EntityId;
                                                   var plane_net_phys : PlaneActor&;
                                                   var replication : NetObject&)
  if client_ai_aircraft__delayedExit < 0.f || client_ai_aircraft__delayedExit > info.curTime
    return
  let role = is_server() ? NetRole ROLE_LOCALLY_CONTROLLED_AUTHORITY : NetRole ROLE_REMOTELY_CONTROLLED_SHADOW
  plane_net_phys |> plane_actor_setRoleAndTickrateType(role, PhysTickRateType Normal)
  net_object_setControlledBy(replication, INVALID_CONNECTION_ID)
  removeSubTemplate(eid, "client_ai_aircraft")

[es(tag=server, on_appear, after=plane_spawn_in_the_air_es)]
def paratroopers_aircraft_set_kick_distance(evt : Event;
                                            plane_net_phys : PlaneActor;
                                            paratroopers_aircraft__paratroopersAirResistanceAccel : float = 20.0;
                                            vehicle_seats__exitTime : float;
                                            var ai_aircraft__distToKickParatroopers : float&)
  let vel = length(float3(plane_net_phys.phys.currentState.velocity).xz)
  let accel = abs(paratroopers_aircraft__paratroopersAirResistanceAccel)
  let t = abs(safediv(vel, accel))
  let distTraveledInPlane = vehicle_seats__exitTime * vel
  let distTraveledInAir = vel * t - accel * t * t * 0.5
  ai_aircraft__distToKickParatroopers = square(distTraveledInPlane + distTraveledInAir)

[es]
def kick_paratrooper_when_died(evt : EventEntityDied;
                               eid : EntityId;
                               human_anim__vehicleSelected : EntityId)
  query(human_anim__vehicleSelected) <| $ [es(REQUIRE=paratroopersAircraft)] (vehicle_seats__seatEids : EidList)
    let ownerEid = get_Eid(vehicle_seats__seatEids[0], "seat__ownerEid") ?? INVALID_ENTITY_ID
    if ownerEid == eid
      sendEvent(human_anim__vehicleSelected, [[CmdKickFromVehicle eid=eid]])
