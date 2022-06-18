require ecs
require sound_utils.modules.sound_utils_events
require enlisted.events_enlisted
require soundHash

[es(tag=sound)]
def human_dig_sound(evt : EventOnDig; eid : EntityId)
  if evt.isSuccessful
    sendEvent(eid, [[CmdPlaySound hash=sound_hash("terraform")]])
