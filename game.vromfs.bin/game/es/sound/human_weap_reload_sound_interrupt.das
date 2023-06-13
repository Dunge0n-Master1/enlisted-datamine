require ecs
require soundEvent
require soundHash
require sound_utils.modules.sound_player_common


[es(tag=sound, track=human_weap__isReloadRequested)]
def human_weap_reload_sound_interrupt(evt : Event;
                                      human_weap__isReloadRequested : bool;
                                      var sound_event_group : SoundEventGroup&)
  if !human_weap__isReloadRequested
    reject_sound(sound_event_group, sound_hash("gunIrq"), true)
