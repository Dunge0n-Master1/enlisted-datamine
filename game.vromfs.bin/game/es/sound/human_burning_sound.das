require ecs
require soundHash
require soundEvent
require sound_utils.modules.sound_player_common


[es(tag=sound, track=burning__isBurning, REQUIRE=humanSound)]
def human_burning_sound_toggle(evt : Event;
                               burning__isBurning : bool;
                               sound_tags : Object;
                               var sound_event_group : SoundEventGroup&;
                               [[shared_comp]] sound_paths : Object;
                               is_watched_sound : bool;
                               transform : float3x4)
  if burning__isBurning
    sound_player_common::play_path("burning", sound_paths, sound_tags, is_watched_sound, transform[3], sound_hash("burning"), sound_event_group)
  else
    reject_sound(sound_event_group, sound_hash("burning"))


[es(tag=sound, track=burning__isPuttingOut, REQUIRE=humanSound)]
def human_burning_sound_putting_out(evt : Event;
                                    burning__isPuttingOut : bool;
                                    sound_tags : Object;
                                    var sound_event_group : SoundEventGroup&;
                                    [[shared_comp]] sound_paths : Object;
                                    is_watched_sound : bool;
                                    transform : float3x4)
  if burning__isPuttingOut
    sound_player_common::play_path("burningPuttingOut", sound_paths, sound_tags, is_watched_sound, transform[3], sound_hash("burningPuttingOut"), sound_event_group)
  else
    reject_sound(sound_event_group, sound_hash("burningPuttingOut"))
