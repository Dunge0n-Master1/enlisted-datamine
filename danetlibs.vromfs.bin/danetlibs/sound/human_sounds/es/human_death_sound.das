require ecs
require soundEvent
require sound_utils.modules.sound_player_common

[es(tag=sound, on_event=EventEntityDied, REQUIRE=humanDeathSound)]
def human_death_sound(evt : Event;
                      [[shared_comp]] human_voice_sound__path : Object;
                      [[shared_comp]] human_voice_sound__descs : Object;
                      var sound_event_group : SoundEventGroup&;
                      transform : float3x4;
                      sound_tags : Object;
                      is_watched_sound : bool = false)
  release_all_sounds(sound_event_group)
  sound_player_common::play("death", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3])
