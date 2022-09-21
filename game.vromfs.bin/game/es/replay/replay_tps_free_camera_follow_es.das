require ecs
require math.base
require DagorMath

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
