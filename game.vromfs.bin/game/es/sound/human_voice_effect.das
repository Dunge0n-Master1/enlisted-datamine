require ecs
require ecs.safe
require soundHash
require soundEvent
require sound_utils.modules.sound_player_common


[es(tag=sound, track=human_voice_effect__activeEffects)]
def human_voice_effect_track_active_effect(evt : Event;
                                           human_voice_effect__activeEffects : Object;
                                           [[shared_comp]] human_voice_effect__allOrderedEffects : StringList;
                                           var human_voice_effect__type : das_string&)

  for effect in human_voice_effect__allOrderedEffects
    if human_voice_effect__activeEffects[string(effect)] ?? false
      human_voice_effect__type := effect
      return
  human_voice_effect__type := ""


[es(tag=sound, track=(human_voice_enable, human_voice_effect__type, is_watched_sound))]
def human_voice_effect_impl(evt : Event;
                            human_voice_enable : bool;
                            human_voice_effect__type : string;
                            is_watched_sound = false;
                            [[shared_comp]] human_voice_sound__path : Object;
                            [[shared_comp]] human_voice_sound__descs : Object;
                            var sound_event_group : SoundEventGroup&;
                            sound_tags : Object;
                            transform : float3x4)

  release_sound(sound_event_group, sound_hash("voiceEffect"))
  if human_voice_enable && human_voice_effect__type != ""
    sound_player_common::play(human_voice_effect__type, human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash("voiceEffect"), sound_event_group)
