require ecs
require app

[es(tag=playingReplay, track=replay__speed, on_appear)]
def change_replay_speed_es(evt : Event; replay__speed : float)
  set_timespeed(replay__speed)

[es(tag=playingReplay, on_appear, after=change_replay_speed_es)]
def replay_acceleration_to_init_es(evt : Event; replay__accelerationSpeed : float)
  find_query() <| $ [es] (var replay__speed : float&)
    replay__speed = replay__accelerationSpeed
    set_timespeed(replay__accelerationSpeed) // for set speed Immediate
    return true

[es(tag=playingReplay, no_order)]
def replay_acceleration_to_update_es(evt : UpdateStageInfoAct;
                                     eid : EntityId;
                                     replay__accelerationPrevSpeed : float;
                                     replay__accelerationTime : float)
  if evt.curTime >= replay__accelerationTime
    find_query() <| $ [es] (var replay__speed : float&)
      replay__speed = replay__accelerationPrevSpeed
      set_timespeed(replay__accelerationPrevSpeed) // for set speed Immediate
      return true
    destroyEntity(eid)
