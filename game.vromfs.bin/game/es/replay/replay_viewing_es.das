require ecs
require app

[es(tag=playingReplay, track=replay__speed, on_appear)]
def change_replay_speed_es(evt : Event; replay__speed : float)
  set_timespeed(replay__speed)
