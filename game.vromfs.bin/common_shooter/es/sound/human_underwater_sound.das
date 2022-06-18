require ecs
require sound_utils.modules.sound_player_common
require soundEvent
require soundHash


[es(tag=sound, track=human_breath__isUnderWater)]
def human_underwater_sound(evt : Event;
                           var sound_tags : Object&;
                           var sound_event_group : SoundEventGroup&;
                           [[shared_comp]] human_voice_sound__path : Object;
                           [[shared_comp]] human_voice_sound__descs : Object;
                           is_watched_sound : bool;
                           transform : float3x4;
                           isAlive : bool;
                           human_breath__isUnderWater : bool;
                           human_breath__timer : float = 0.;
                           human_breath__maxHoldBreathTime = 0.)

  if is_watched_sound && isAlive
    if human_breath__isUnderWater
      sound_player_common::play("underwaterIn", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash("underwaterInOut"), sound_event_group)
    else
      set_sound_tag("headIsUnderwater", false, sound_tags)
      let handle = sound_player_common::play("underwaterOut", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash("underwaterInOut"), sound_event_group)
      let param = human_breath__timer / max(human_breath__maxHoldBreathTime, 0.01)
      set_var_optional(handle, "noairtime", param)

  set_sound_tag("headIsUnderwater", human_breath__isUnderWater, sound_tags)
