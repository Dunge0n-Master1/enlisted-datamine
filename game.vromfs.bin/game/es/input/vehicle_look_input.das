require ecs
require vehicle
require game.utils.hero
require EnlistedHuman
require HumanPhys
require DagorMath
require DagorMathUtils
require GamePhys
require math.ang
require math.base

require game.es.vehicle.vehicle_events
require game.es.vehicle.vehicle_seats_common


def vehicle_clamp_camera_angle(var aim_angle : float2&; var ct : HumanControlState&; max_angle : float2; dir : float3)
  let wishLookDirAngles = dir_to_angles(ct.wishLookDir)
  aim_angle = clamp_angles_by_dir(aim_angle, max_angle, dir)
  let lookAngle = clamp_angles_by_dir(wishLookDirAngles, max_angle, dir)

  ct |> human_control_state_set_wish_shoot_dir(angles_to_dir(aim_angle))
  ct |> human_control_state_set_wish_look_dir(angles_to_dir(lookAngle))


[es(tag=input, REQUIRE=setCameraDirByHero)]
def human_vehicle_look_es(info : UpdateStageInfoAct;
                          input__enabled : bool;
                          vehicle__localControls : VehicleControlsState;
                          vehicleCameraType : int;
                          var camera__lookDir aka vehicle_camera__lookDir : float3&)
  if !input__enabled
    return
  find_query() <| $ [es(REQUIRE=hero)] (camera__lookDir : float3)
    let inCommanderCockpit = vehicleCameraType == int(VehicleCameraType VEHICLE_CAMERA_COMMANDER_COCKPIT)
    let inGunnerCockpit    = vehicleCameraType == int(VehicleCameraType VEHICLE_CAMERA_GUNNER_COCKPIT)
    let inMachineGunnerCockpit = vehicleCameraType == int(VehicleCameraType VEHICLE_CAMERA_MACHINEGUNNER_COCKPIT)
    if vehicle__localControls.canControlVehicle || inCommanderCockpit || inGunnerCockpit || inMachineGunnerCockpit
      vehicle_camera__lookDir = camera__lookDir
    return true

[es(tag=input, REQUIRE=heroVehicle)]
def human_vehicle_look_passenger_es(info : UpdateStageInfoAct;
                                    vehicleCameraType : int;
                                    var camera__lookDir aka vehicle_camera__lookDir : float3&)
  if vehicleCameraType == int(VehicleCameraType VEHICLE_CAMERA_PASSENGER)
    find_query() <| $ [es(REQUIRE=hero)] (camera__lookDir : float3;
                                          isInVehicle : bool)
      if isInVehicle
        vehicle_camera__lookDir = camera__lookDir
      return true

[es(tag=input, after=after_net_phys_sync, before=human_look_dir_camera_in_vehicle_es, REQUIRE_NOT=unlimitedVehicleCam)]
def human_input_driver_in_vehicle_es(info : UpdateStageInfoAct;
                                     input__enabled : bool;
                                     isInVehicle : bool;
                                     vehicle__globalSeatTm : float3x4;
                                     human_anim__vehicleSelected : EntityId;
                                     vehicleCameraType : int;
                                     camera__relative_angle : float2 = float2();
                                     var human_input__aimAngle : float2&;
                                     var human_net_phys : HumanActor&)
  if !input__enabled || !isInVehicle
    return
  if vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_DRIVER)
    return
  query(human_anim__vehicleSelected) <| $ [es] (driverFpsCamMaxAngle : float2; cockpit__cameraDir : float3 const?)
    let direction = cockpit__cameraDir ?? vehicle__globalSeatTm[0]
    var additionalRotation : quat
    euler_to_quat(-camera__relative_angle.x, -camera__relative_angle.y, 0.0, additionalRotation)
    vehicle_clamp_camera_angle(human_input__aimAngle, human_net_phys.phys.producedCT, driverFpsCamMaxAngle, additionalRotation * direction)


[es(tag=input, after=after_net_phys_sync, before=human_input_driver_in_vehicle_es)]
def human_input_gunner_in_cockpit(info : UpdateStageInfoAct;
                                  input__enabled : bool;
                                  isInVehicle : bool;
                                  human_anim__vehicleSelected : EntityId;
                                  vehicleCameraType : int;
                                  var human_net_phys : HumanActor&;
                                  var human_input__aimAngle : float2&)
  if !input__enabled || !isInVehicle
    return
  if vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_GUNNER_COCKPIT)
    return
  query(human_anim__vehicleSelected) <| $ [es] (commanderCockpitFpsCamMaxAngle : float2; cockpit__cameraDir : float3)
    vehicle_clamp_camera_angle(human_input__aimAngle, human_net_phys.phys.producedCT, commanderCockpitFpsCamMaxAngle, cockpit__cameraDir)


[es(tag=input, after=after_net_phys_sync, before=human_input_driver_in_vehicle_es)]
def human_input_machine_gunner_in_cockpit(info : UpdateStageInfoAct;
                                          input__enabled : bool;
                                          isInVehicle : bool;
                                          human_anim__vehicleSelected : EntityId;
                                          vehicleCameraType : int;
                                          var human_net_phys : HumanActor&;
                                          var human_input__aimAngle : float2&)
  if !input__enabled || !isInVehicle
    return
  if vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_MACHINEGUNNER_COCKPIT)
    return
  query(human_anim__vehicleSelected) <| $ [es] (gunnerFpsCamMaxAngle : float2; cockpit__cameraDir : float3)
    vehicle_clamp_camera_angle(human_input__aimAngle, human_net_phys.phys.producedCT, gunnerFpsCamMaxAngle, cockpit__cameraDir)

[es(tag=input, after=after_net_phys_sync, before=human_input_driver_in_vehicle_es)]
def human_input_commander_cockpit_es(info : UpdateStageInfoAct;
                                     input__enabled : bool;
                                     isInVehicle : bool;
                                     human_anim__vehicleSelected : EntityId;
                                     vehicleCameraType : int;
                                     var human_net_phys : HumanActor&;
                                     var human_input__aimAngle : float2&)
  if !input__enabled || !isInVehicle
    return
  if vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_COMMANDER_COCKPIT)
    return
  query(human_anim__vehicleSelected) <| $ [es] (commanderCockpitFpsCamMaxAngle : float2; cockpit__cameraDir : float3)
    vehicle_clamp_camera_angle(human_input__aimAngle, human_net_phys.phys.producedCT, commanderCockpitFpsCamMaxAngle, cockpit__cameraDir)

[es(tag=input, after=after_net_phys_sync, before=human_input_commander_cockpit_es)]
def human_input_commander_no_turret_control_es(info : UpdateStageInfoAct;
                                               input__enabled : bool;
                                               isInVehicle : bool;
                                               human_anim__vehicleSelected : EntityId;
                                               vehicleCameraType : int;
                                               vehicle__globalSeatTm : float3x4;
                                               var human_net_phys : HumanActor&;
                                               var human_input__aimAngle : float2&)
  if !input__enabled || !isInVehicle
    return
  if vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_COMMANDER)
    return
  query(human_anim__vehicleSelected) <| $ [es(REQUIRE_NOT=turretInput)] (commanderFpsCamMaxAngle : float2)
    vehicle_clamp_camera_angle(human_input__aimAngle, human_net_phys.phys.producedCT, commanderFpsCamMaxAngle, vehicle__globalSeatTm[0])

[es(tag=input, after=after_net_phys_sync, before=human_look_dir_camera_in_vehicle_es)]
def human_input_passenger_in_vehicle_es(info : UpdateStageInfoAct;
                                        isInVehicle : bool;
                                        vehicle__globalSeatTm : float3x4;
                                        human_anim__vehicleSelected : EntityId;
                                        vehicleCameraType : int;
                                        var human_net_phys : HumanActor&;
                                        var human_input__aimAngle : float2&;
                                        camera__relative_angle : float2 = float2())
  if !isInVehicle
    return
  assume appliedCt = human_net_phys.phys.appliedCT
  let isAiming = appliedCt |> is_control_bit_set(HumanPhysControlType HCT_ZOOM_VIEW) || appliedCt |> is_control_bit_set(HumanPhysControlType HCT_AIM)
  if vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_PASSENGER) || isAiming
    return
  query(human_anim__vehicleSelected) <| $ [es] (passengerFpsCamMaxAngle : float2)
    var additionalRotation : quat
    euler_to_quat(-camera__relative_angle.x, -camera__relative_angle.y, 0.0, additionalRotation)
    vehicle_clamp_camera_angle(human_input__aimAngle, human_net_phys.phys.producedCT, passengerFpsCamMaxAngle, additionalRotation * vehicle__globalSeatTm[0])

[es(tag=gameClient, after=after_net_phys_sync)]
def vehicle_seats_taken_seat_set_camdir(evt : EventEnterVehicle; vehicle_seats__seatEids : EidList; transform : float3x4; isTpsView : bool = false)
  if isTpsView
    return
  if !evt.enter
    return
  let hero = get_controlled_hero()
  if evt.incomer != hero
    return
  if evt.seat_no < 0 || evt.seat_no >= length(vehicle_seats__seatEids)
    return

  let seatEid = vehicle_seats__seatEids[ evt.seat_no ]
  query(seatEid) <| $ [es] (seats_attach_nodes__initialTm : float3x4; seats_attach_nodes__initialLookAngles : float2 = float2())
    query(hero) <| $ [es] (var human_net_phys : HumanActor&; var human_input__aimAngle : float2&)
      let tm = transform * seats_attach_nodes__initialTm
      let lookDir = tm[0]

      human_input__aimAngle = dir_to_angles(lookDir)
      human_input__aimAngle += deg_to_rad(seats_attach_nodes__initialLookAngles)
      let wishDir = angles_to_dir(human_input__aimAngle)
      assume ct = human_net_phys.phys.producedCT
      ct |> human_control_state_set_wish_shoot_dir(wishDir)
      ct |> human_control_state_set_wish_look_dir(wishDir)
