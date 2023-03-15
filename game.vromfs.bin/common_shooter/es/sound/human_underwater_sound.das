require ecs
require soundEvent
require sound_utils.modules.sound_player_common
require human_sounds.modules.human_voice_effect_common
require DagorMath


[es(tag=sound, on_appear, before=human_voice_effect_on_change, track=human_breath__isUnderWater)]
def human_underwater_sound(evt : Event;
                           var sound_tags : Object&;
                           human_breath__isUnderWater : bool;
                           var human_voice_effect__activeEffects : Object&)
  set_human_voice_effect("underwater", human_breath__isUnderWater, human_voice_effect__activeEffects)
  set_sound_tag("headIsUnderwater", human_breath__isUnderWater, sound_tags)


[es(tag=sound, after=human_voice_effect_on_change, track=human_voice_effect__activeEffects, REQUIRE=human_voice_effect__activeEffects)]
def human_underwater_sound_set_var(evt : Event;
                                   human_breath__timer : float;
                                   human_breath__maxHoldBreathTime : float;
                                   human_voice_effect__event : SoundEvent&)
  if human_breath__timer > 0.
    set_var_optional(human_voice_effect__event.handle, "noairtime", safediv(human_breath__timer, human_breath__maxHoldBreathTime))
