require ecs
require math.base
require DagorMath

let FIXED_DT = 1. / 60. // 60hz

[es(tag=playingReplay, after=camera_set_sync, before=before_camera_sync, REQUIRE=replay_camera__tpsFree)]
def replay_tps_free_camera_follow_es(info : UpdateStageInfoAct;
                                     camera__active : bool;
                                     isTpsView : bool;
                                     camera__target : EntityId;
                                     camera__input_enabled : bool;
                                     replay_camera__offset : float3;
                                     replay_camera__viscosity : float = 0.03;
                                     var transform aka cam_transform : float3x4&;
                                     var camera__accuratePos : DPoint3&)
  if !isTpsView || !camera__active || camera__input_enabled
    return

  query(camera__target) <| $ [es] (transform : float3x4)
    let pos = transform[3] + replay_camera__offset
    cam_transform[3] = approach(cam_transform[3], pos, info.dt, replay_camera__viscosity)
    camera__accuratePos = approach(camera__accuratePos, DPoint3(pos), info.dt, replay_camera__viscosity)


[es(after=camera_set_sync, before=before_camera_sync)]
def replay_tps_free_camera_movement_es(evt : UpdateStageInfoAct;
                                       camera__input_enabled : bool;
                                       camera__active : bool;
                                       transform aka cam_transform : float3x4;
                                       camera__target : EntityId;
                                       var camera__accuratePos : DPoint3&;
                                       var replay_camera__offset : float3&)
  if !camera__active || !camera__input_enabled
    return

  camera__accuratePos = DPoint3(cam_transform[3])
  query(camera__target) <| $ [es] (transform : float3x4)
    replay_camera__offset = cam_transform[3] - transform[3]

[es(track=fovSettings, REQUIRE=replay_camera__tpsFree)]
def set_free_tps_camera_fov_es(evt : Event; fovSettings : float; var fov : float&)
  fov = fovSettings

[es(tag=playingReplay, track=camera__active, before=free_tps_camera_update_es)]
def free_tps_initial_rotation_es(evt : Event;
                                 camera__active : bool;
                                 transform : float3x4;
                                 var replay_camera__tpsInputAngle : float2&;
                                 var replay_camera__tpsCurAng : float2&)
  if !camera__active
    return
  let dir = transform[2]
  replay_camera__tpsInputAngle = float2(-safe_atan2(dir.x, dir.z), safe_asin(dir.y))
  replay_camera__tpsCurAng = replay_camera__tpsInputAngle

[es(tag=playingReplay, no_order)]
def free_tps_camera_update_es(info : UpdateStageInfoAct;
                              camera__active : bool;
                              replay_camera__tpsInputAngle : float2;
                              replay_camera__tpsLerpFactor : float;
                              var transform : float3x4&;
                              var replay_camera__tpsCurAng : float2&)
  if !camera__active
    return

  let oldPosition = transform[3]
  replay_camera__tpsCurAng = lerp(replay_camera__tpsCurAng, replay_camera__tpsInputAngle, float2(FIXED_DT * replay_camera__tpsLerpFactor))

  var tmY, tmX = IDENT_TM
  rotyTM(replay_camera__tpsCurAng.x, tmY)
  rotxTM(replay_camera__tpsCurAng.y, tmX)
  transform = tmY * tmX
  transform[3] = oldPosition
