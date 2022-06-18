require ecs
require enlisted.game.es.train.train_capzone_common

[es(tag=server, track=active)]
def train_capzone_set_next_point(evt : Event; active : bool; var capzone__isNextTrainZone : bool&)
  if capzone__isNextTrainZone && !active
    capzone__isNextTrainZone = false
    query(get_next_train_checkpoint()) <| $ [es] (var capzone__isNextTrainZone : bool&)
      capzone__isNextTrainZone = true

[es(tag=server, on_event=EventLevelLoaded, after=init_choice_es)]
def train_capzone_init_next_point(evt : Event)
  query(get_next_train_checkpoint()) <| $ [es] (var capzone__isNextTrainZone : bool&)
    capzone__isNextTrainZone = true