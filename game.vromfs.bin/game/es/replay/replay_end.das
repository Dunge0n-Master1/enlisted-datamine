require ecs
require replay
require game.es.input.input_events


[es(tag=playingReplay)]
def replay_on_end(evt : EventDaInputInit)
  if !evt.init
    replay_clear_current_play_file()
