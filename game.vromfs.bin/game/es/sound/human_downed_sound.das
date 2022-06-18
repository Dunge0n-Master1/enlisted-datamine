require ecs
require soundHash
require soundEvent
require sound_utils.modules.sound_player_common

[es(tag=sound, REQUIRE=humanSound, track=(is_watched_sound, isDowned, isAlive))]
def human_downed_sound(evt : Event;
                       [[shared_comp]] human_voice_sound__path : Object;
                       [[shared_comp]] human_voice_sound__descs : Object;
                       sound_tags : Object;
                       transform : float3x4;
                       var sound_event_group : SoundEventGroup&;
                       is_watched_sound : bool;
                       isDowned : bool;
                       isAlive : bool)
  reject_sound(sound_event_group, sound_hash("downed"))
  if isDowned && isAlive
    abandon_all_sounds(sound_event_group)
    sound_player_common::play("downed", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash("downed"), sound_event_group)
