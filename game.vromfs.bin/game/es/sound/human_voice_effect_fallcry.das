require ecs
require human_sounds.modules.human_voice_effect_common


[es(tag=sound, on_appear, before=human_voice_effect_on_change, track=(human_voice_effect_fallcry__enabled, human_fall_sound__isFalling))]
def human_voice_effect_fallcry(evt : Event;
                               human_voice_effect_fallcry__enabled : bool;
                               human_fall_sound__isFalling : bool;
                               var human_voice_effect__activeEffects : Object&)
  set_human_voice_effect("fallcry", human_voice_effect_fallcry__enabled && human_fall_sound__isFalling, human_voice_effect__activeEffects)
