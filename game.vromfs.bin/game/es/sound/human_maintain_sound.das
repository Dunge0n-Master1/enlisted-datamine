require ecs
require ecs.common
require soundHash
require soundEvent
require sound_utils.modules.sound_player_common

[es(tag=sound, track=repair__active)]
def human_maintain_sound_repair(evt : Event;
                                repair__active : bool;
                                var sound_event_group : SoundEventGroup&;
                                [[shared_comp]] sound_paths : Object;
                                sound_tags : Object;
                                is_watched_sound : bool;
                                transform : float3x4)
  if repair__active
    sound_player_common::play_path("repair", sound_paths, sound_tags, is_watched_sound, transform[3], sound_hash("repair"), sound_event_group)
  else
    reject_sound(sound_event_group, sound_hash("repair"))

[es(tag=sound, track=extinguisher__active)]
def human_maintain_sound_extinguish(evt : Event;
                                    extinguisher__active : bool;
                                    var sound_event_group : SoundEventGroup&;
                                    [[shared_comp]] sound_paths : Object;
                                    sound_tags : Object;
                                    is_watched_sound : bool;
                                    transform : float3x4)
  if extinguisher__active
    sound_player_common::play_path("extinguish", sound_paths, sound_tags, is_watched_sound, transform[3], sound_hash("repair"), sound_event_group)
  else
    reject_sound(sound_event_group, sound_hash("repair"))
