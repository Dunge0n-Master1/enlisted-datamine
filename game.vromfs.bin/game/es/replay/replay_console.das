options no_aot
require ecs
require DagorConsole
require EnlistedCamera
require game.es.events

def private replay_change_camera(camera_eid : EntityId; var tm : float3x4&)
  let curCam = get_cur_cam_entity()
  if curCam == camera_eid
    return
  query(curCam) <| $ [es] (var camera__target : EntityId&; transform : float3x4)
    tm = transform
    set_scene_camera_entity(camera_eid)
    sendEvent(camera_eid, [[CmdSetCameraTarget target=camera__target]])
    camera__target = INVALID_ENTITY_ID

[console_cmd(name="replay.fps_camera")]
def replay_fps_camera_cmd()
  find_query() <| $ [es(REQUIRE=replayCamera)] (eid : EntityId;
                                                var transform : float3x4&;
                                                isTpsView : bool = false)
    if isTpsView
      return false
    replay_change_camera(eid, transform)
    return true

[console_cmd(name="replay.tps_camera")]
def replay_tps_camera_cmd()
  find_query() <| $ [es(REQUIRE=replayCamera)] (eid : EntityId;
                                                var transform : float3x4&;
                                                isTpsView : bool = false)
    if !isTpsView
      return false
    replay_change_camera(eid, transform)
    return true

[console_cmd(name="replay.tps_free_camera")]
def replay_tps_free_camera_cmd()
  find_query() <| $ [es(REQUIRE=replay_camera__tpsFree)] (eid : EntityId; var transform : float3x4&)
    replay_change_camera(eid, transform)
    return true
