require ecs
require vehicle
require math.base
require math.ang
require common_shooter.es.input.turret_input_common

def clamp_turret_controller_camera_angle(turret_control__gunEids : EidList;
                                         dir : float3;
                                         maxAngle : float2)
  var isFirstAimPosVaild = false
  var firstAimPos = float3()

  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=(resolvedTurret, firstTurretInput))] (var turret_input__aimAngles : float2&;
                                                                         var turret_input__aimPos : float3&)
      assume aimAngles = turret_input__aimAngles
      assume aimPos = turret_input__aimPos

      aimAngles = clamp_angles_by_dir(aimAngles, maxAngle, dir)
      aimAngles.y = clamp(aimAngles.y, -SAFE_HALF_PI, SAFE_HALF_PI)

      aimPos = calc_aim_pos(aimAngles)

      isFirstAimPosVaild = false
      firstAimPos = aimPos

  if !isFirstAimPosVaild
    return

  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=resolvedTurret, REQUIRE_NOT=firstTurretInput)] (var turret_input__aimPos : float3&)
      turret_input__aimPos = firstAimPos


[es(tag=gameClient, after=after_net_phys_sync, before=human_look_dir_camera_in_vehicle_es)]
def vehicle_input_gunner_limits_control_es(info : UpdateStageInfoAct;
                                           input__enabled : bool;
                                           vehicleCameraType : int;
                                           turret_control__gunEids : EidList;
                                           turret_current_visual_shoot_tm : float3x4;
                                           gunnerFpsCamMaxAngle : float2;
                                           cockpit__eid : EntityId = INVALID_ENTITY_ID;
                                           cockpit__cameraDir : float3 = float3();
                                           gunner_cam_limit__useCockpitDir : bool = false;
                                           isTpsView : bool = false)
  if isTpsView
    return

  if !input__enabled
    return
  if (vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_GUNNER) &&
      vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_MACHINEGUNNER_COCKPIT))
    return
  let dir = (gunner_cam_limit__useCockpitDir && !!cockpit__eid) ? cockpit__cameraDir : turret_current_visual_shoot_tm[0]

  clamp_turret_controller_camera_angle(turret_control__gunEids, dir, gunnerFpsCamMaxAngle)

[es(tag=gameClient, after=after_net_phys_sync, before=human_look_dir_camera_in_vehicle_es)]
def vehicle_input_commander_limits_control_es(info : UpdateStageInfoAct;
                                              input__enabled : bool;
                                              vehicleCameraType : int;
                                              turret_control__gunEids : EidList;
                                              turret_current_visual_shoot_tm : float3x4;
                                              commanderFpsCamMaxAngle : float2;
                                              isTpsView : bool = false)
  if isTpsView
    return

  if !input__enabled
    return
  if vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_COMMANDER)
    return

  clamp_turret_controller_camera_angle(turret_control__gunEids, turret_current_visual_shoot_tm[0], commanderFpsCamMaxAngle)
