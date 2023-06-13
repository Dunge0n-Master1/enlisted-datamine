require ecs
require game.events_game

[es(tag=recordingReplay, on_appear)]
def replay_init_key_frame_timer_es(evt : Event; replay__nextKeyTimeSec : float; var replay__keyFrameTimerSec : float&)
  replay__keyFrameTimerSec = replay__nextKeyTimeSec

[es(tag=recordingReplay, no_order)]
def replay_save_key_frame_timer_es(info : UpdateStageInfoAct; replay__nextKeyTimeSec : float; var replay__keyFrameTimerSec : float&)
  replay__keyFrameTimerSec -= info.dt
  if replay__keyFrameTimerSec <= 0.
    replay__keyFrameTimerSec = replay__nextKeyTimeSec
    broadcastEvent([[RequestSaveKeyFrame]])
