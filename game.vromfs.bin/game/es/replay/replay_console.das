options no_aot
require ecs
require DagorConsole
require game.events_game

[console_cmd(name="replay.fps_camera")]
def replay_fps_camera_cmd()
  broadcastEvent([[ReplaySetFpsCamera]])

[console_cmd(name="replay.tps_camera")]
def replay_tps_camera_cmd()
  broadcastEvent([[ReplaySetTpsCamera]])

[console_cmd(name="replay.tps_free_camera")]
def replay_tps_free_camera_cmd()
  broadcastEvent([[ReplaySetFreeTpsCamera]])
