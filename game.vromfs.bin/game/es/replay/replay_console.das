options no_aot
require ecs
require app
require EnlistedCamera
require DagorConsole
require game.events_game
require enlisted.events_enlisted

def private float_to_sec(time : float) : float
  return float(int(time)) * 60. + (time * 100.) % 100.

[console_cmd(name="replay.fps_camera")]
def replay_fps_camera_cmd()
  broadcastEvent([[ReplaySetFpsCamera]])

[console_cmd(name="replay.tps_camera")]
def replay_tps_camera_cmd()
  broadcastEvent([[ReplaySetTpsCamera]])

[console_cmd(name="replay.tps_free_camera")]
def replay_tps_free_camera_cmd()
  broadcastEvent([[ReplaySetFreeTpsCamera]])

[console_cmd(name="replay.rewind", hint="time - replay time in format: min.sec, for example 3.2 mean 3 min 20 second")]
def replay_rewind_cmd(time : float)
  find_query() <| $ [es(REQUIRE=replay__accelerationTime)] (eid : EntityId)
    destroyEntity(eid)
    return true

  createEntity("replay_acceleration_to_debug") <| $(var init)
    init |> set("replay__accelerationTime", float_to_sec(time))

[es(tag=dev, REQUIRE=replay__accelerationDebug, on_disappear, before=replay_acceleration_to_init_es)]
def replay_rewind_pause_debug_es(evt : Event)
  find_query() <| $ [es] (var replay__speed : float&)
    replay__speed = 0.
    set_timespeed(replay__speed) // for set speed Immediate
    return true

[console_cmd(name="replay.next_target")]
def replay_next_target_cmd(delta : int = 1)
  sendEvent(get_cur_cam_entity(), [[NextReplayTarget delta=delta]])

[console_cmd(name="replay.change_free_tps_speed")]
def replay_change_free_tps_speed(speed : float = 5.)
  broadcastEvent([[CmdSetFreeTpsCameraSpeed speed=speed]])

[console_cmd(name="replay.set_postfx")]
def replay_set_postfx(enabled : bool = true)
  broadcastEvent([[CmdSetCinematicPostFxBloom enabled=enabled]])

[console_cmd(name="replay.camera_set_lerp_factor")]
def replay_camera_inert_enable_cmd(factor : float = 2.0)
  query() <| $ [es] (var replay_camera__tpsLerpFactor : float&)
    replay_camera__tpsLerpFactor = factor

[console_cmd(name="replay.operator_camera")]
def replay_operator_camera_cmd()
  broadcastEvent([[ReplaySetOperatorCamera]])
