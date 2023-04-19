require ecs
require game.events_game
require DagorMath
require CollRes
require game.es.vehicle.vehicle_seats_common
require vehicle
require DngWeapon
require DagorMathUtils
require DngHuman
require DngCamera
require common_shooter.es.input.turret_input_common
require enlisted.events_enlisted

def private set_turret_watched(turret_control__gunEids : EidList; seat__ownerControls : VehicleControlsState)
  var foundTurret = INVALID_ENTITY_ID
  for turretNo, turretEid in iter_range(turret_control__gunEids), turret_control__gunEids
    let canControlTurret = can_control_turret(seat__ownerControls, turretNo)
    if !canControlTurret
      continue

    query(turretEid) <| $ [es(REQUIRE=isTurret)] (firstWatchedTurret : Tag const?)
      if firstWatchedTurret == null
        addSubTemplate(turretEid, "first_watched_turret")
      foundTurret = turretEid

    if !!foundTurret
      break

  query() <| $ [es(REQUIRE=firstWatchedTurret)] (eid : EntityId)
    if eid != foundTurret
      removeSubTemplate(eid, "first_watched_turret")

def private set_turret_watched_for_vehicle(seat__vehicleEid : EntityId; seat__ownerControls : VehicleControlsState)
  query(seat__vehicleEid) <| $ [es(REQUIRE=vehicleWithWatched)] (turret_control__gunEids : EidList)
    set_turret_watched(turret_control__gunEids, seat__ownerControls)

[es(tag=playingReplay, track=(camera__target, camera__active), REQUIRE=(camera__target, replayCamera), before=on_change_vehicle_camera_type_es)]
def replay_camera_set_bind_to_vehicle_es(evt : Event; camera__active : bool; var bindToVehicle : bool&; isTpsView : bool = false)
  if camera__active
    query() <| $ [es(REQUIRE=watchedByPlr)] (human_anim__vehicleSelected : EntityId)
      bindToVehicle = !!human_anim__vehicleSelected && !isTpsView && !!(get_Eid(human_anim__vehicleSelected, "cockpit__eid") ?? INVALID_ENTITY_ID) && !has(human_anim__vehicleSelected, "replay_camera__attachToHuman")
      sendEvent(human_anim__vehicleSelected, [[CmdUpdateCameraByVehicleType]])

[es(tag=playingReplay, on_appear, track=human_anim__vehicleSelected, REQUIRE=watchedByPlr, before=on_change_vehicle_camera_type_es)]
def replay_human_camera_set_bind_to_vehicle_es(evt : Event; human_anim__vehicleSelected : EntityId)
  find_query() <| $ [es] (camera__active : bool; var bindToVehicle : bool&; isTpsView : bool = false)
    if camera__active
      bindToVehicle = !!human_anim__vehicleSelected && !isTpsView  && !!(get_Eid(human_anim__vehicleSelected, "cockpit__eid") ?? INVALID_ENTITY_ID) && !has(human_anim__vehicleSelected, "replay_camera__attachToHuman")
      sendEvent(human_anim__vehicleSelected, [[CmdUpdateCameraByVehicleType]])
    return camera__active

[es(tag=playingReplay, on_appear, track=cockpit__eid, REQUIRE=vehicleWithWatched, REQUIRE_NOT=replay_camera__attachToHuman, before=on_change_vehicle_camera_type_es)]
def replay_human_camera_set_bind_to_vehicle_with_cockpit_es(evt : Event; eid : EntityId; cockpit__eid : EntityId)
  find_query() <| $ [es] (camera__active : bool; var bindToVehicle : bool&; isTpsView : bool = false)
    if camera__active
      bindToVehicle = !isTpsView && !!cockpit__eid
      sendEvent(eid, [[CmdUpdateCameraByVehicleType]])
    return camera__active

[es(tag=playingReplay, on_appear, track=human_anim__vehicleSelected, REQUIRE=watchedByPlr, after=fix_camera_target_es)]
def replay_bind_camera_to_human_after_vehicle_es(evt : Event; eid : EntityId; human_anim__vehicleSelected : EntityId)
  if !!human_anim__vehicleSelected
    return
  find_query() <| $ [es] (camera__active : bool; var camera__target : EntityId&)
    if camera__active
      camera__target = eid
    return camera__active

[es(tag=playingReplay, REQUIRE=watchedByPlr, before=shooter_cam_update_tm_es,
  after=(human_fpv_cam_pos, animchar_cam_target_with_offset_es, animchar_cam_target_es))]
def replay_vehicle_set_tps_camera_look_at(evt : UpdateStageInfoAct;
                                          human_anim__vehicleSelected : EntityId;
                                          isTpsView : bool;
                                          var camera__look_at aka human__camera__look_at : DPoint3&)
  if !isTpsView
    return

  query(human_anim__vehicleSelected) <| $ [es] (transform : float3x4;
                                                collres : CollisionResource;
                                                var camera__look_at : DPoint3&)
    let box = transform * BBox3(collres.vFullBBox.bmin.xyz, collres.vFullBBox.bmax.xyz)
    let pos = box.center
    human__camera__look_at = DPoint3(pos)
    camera__look_at = DPoint3(pos)

[es(tag=playingReplay, on_appear, REQUIRE=vehicleWithWatched)]
def vehicle_set_turret_watched_es(evt : Event; turret_control__gunEids : EidList; vehicle_seats__seatEids : EidList)
  let seatId = vehicle_get_watched_seat_idx(vehicle_seats__seatEids)
  if seatId >= 0
    query(vehicle_seats__seatEids[seatId]) <| $ [es] (seat__availableControls : VehicleControlsState)
      set_turret_watched(turret_control__gunEids, seat__availableControls)

[es(tag=playingReplay, track=(seat__ownerControls, seat__ownerEid), REQUIRE=seat__ownerControls)]
def set_turret_watched_es(evt : Event; seat__vehicleEid : EntityId; seat__availableControls : VehicleControlsState; seat__ownerEid : EntityId)
  if has(seat__ownerEid, "watchedByPlr")
    set_turret_watched_for_vehicle(seat__vehicleEid, seat__availableControls)

[es(tag=playingReplay, on_appear, REQUIRE=watchedByPlr, track=human_anim__vehicleSelected)]
def set_human_turret_watched_es(evt : Event; eid : EntityId; human_anim__vehicleSelected : EntityId)
  var seatId = -1
  query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList)
    seatId = find_seat_with_owner(eid, vehicle_seats__seatEids)
    if seatId >= 0
      query(vehicle_seats__seatEids[seatId]) <| $ [es] (seat__availableControls : VehicleControlsState)
        set_turret_watched_for_vehicle(human_anim__vehicleSelected, seat__availableControls)

  if seatId <= -1
    query() <| $ [es(REQUIRE=firstWatchedTurret)] (eid : EntityId)
      removeSubTemplate(eid, "first_watched_turret")


[es(tag=playingReplay, after=turret_update_visual_shoot_tm_es, REQUIRE=vehicleWithWatched, REQUIRE_NOT=(turret_current_visual_shoot_tm, turret_control__gunEids))]
def replay_set_camera_dir_in_civil_vehicle_es(info : UpdateStageInfoAct; var camera__lookDir : float3&)
  query() <| $ [es(REQUIRE=watchedByPlr)] (human_net_phys : HumanActor)
    camera__lookDir = human_net_phys.phys.currentState.headDir


[es(tag=playingReplay, after=turret_update_visual_shoot_tm_es, REQUIRE=vehicleWithWatched)]
def replay_set_camera_dir_in_vehicle_es(info : UpdateStageInfoAct;
                                        transform : float3x4;
                                        turret_control__gunEids : EidList;
                                        turret_current_visual_shoot_tm : float3x4;
                                        var camera__lookDir : float3&)
  query() <| $ [es(REQUIRE=watchedByPlr)] (human_net_phys : HumanActor; possessedByPlr : EntityId)
    assume gunDir = human_net_phys.phys.currentState.gunDir
    if !!possessedByPlr && !has(possessedByPlr, "playerIsBot")
      camera__lookDir = human_net_phys.phys.currentState.headDir
    else
      // hack for bots player
      // for some reason headDir in vehicle isn't work for bots
      // so set camera directrion from turret dir or vehicle dir
      let camTm = get_TMatrix(get_cur_cam_entity(), "transform")
      let camPos = camTm != null ? (*camTm)[3] : float3()
      var foundTurret = false
      for gunEid in turret_control__gunEids
        query(gunEid) <| $ [es(REQUIRE=(resolvedTurret, firstWatchedTurret))] ()
          camera__lookDir = normalize(calc_aim_pos(dir_to_angles(turret_current_visual_shoot_tm[0])) - camPos)
          foundTurret = true
      if !foundTurret
        camera__lookDir = normalize(calc_aim_pos(dir_to_angles(transform[0])) - camPos)

[es(tag=playingReplay, REQUIRE=watchedByPlr, on_appear, track=(bindedCamera, human_vehicle__occupiedSeatEid), after=camera_set_tps_view_es)]
def replay_set_tps_camera_in_vehicle_by_seat_es(evt : Event;
                                                human_vehicle__occupiedSeatEid : EntityId;
                                                isTpsView : bool;
                                                bindedCamera : EntityId)
  find_query() <| $ [es] (var replay__prevCam : EntityId&; var replay__curCam : EntityId&)
    if !human_vehicle__occupiedSeatEid
      if bindedCamera != replay__prevCam
        sendEvent(replay__prevCam, [[ReplaySetCamera]])
        replay__prevCam = INVALID_ENTITY_ID
      return true

    query(human_vehicle__occupiedSeatEid) <| $ [es] (seats_order__canPlaceManually : bool)
      if !seats_order__canPlaceManually && !isTpsView
        replay__prevCam = bindedCamera
        find_query() <| $ [es(REQUIRE_NOT=replay_camera__tpsFree)] (eid : EntityId; isTpsView : bool)
          if isTpsView
            sendEvent(eid, [[ReplaySetCamera]])
            replay__curCam = eid
          return isTpsView
      elif replay__curCam != bindedCamera
        replay__prevCam = INVALID_ENTITY_ID
      elif bindedCamera != replay__prevCam
        sendEvent(replay__prevCam, [[ReplaySetCamera]])
        replay__prevCam = INVALID_ENTITY_ID
    return true
