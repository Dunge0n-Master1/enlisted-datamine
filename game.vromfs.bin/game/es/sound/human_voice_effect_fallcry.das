require ecs

[es(tag=sound, track=(human_voice_effect_fallcry__enabled, human_fall_sound__isFalling))]
def human_voice_effect_fallcry_update(evt : Event;
                                      human_voice_effect_fallcry__enabled : bool;
                                      human_fall_sound__isFalling : bool;
                                      var human_voice_effect__activeEffects : Object&)
  human_voice_effect__activeEffects |> set("fallcry", human_voice_effect_fallcry__enabled && human_fall_sound__isFalling)
