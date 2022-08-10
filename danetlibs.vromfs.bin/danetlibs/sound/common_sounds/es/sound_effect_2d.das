require ecs
require soundEvent
require soundSystem


[es(tag=sound, on_appear)]
def sound_effect_2d_appear(evt : Event;
                           sound_bank_preset_state__isValid : bool;
                           sound_effect_2d__path : string;
                           sound_effect_2d__abandonOnReset : bool;
                           var sound_effect_2d__event : SoundEvent&)
  sound_effect_2d__event.abandonOnReset = sound_effect_2d__abandonOnReset
  if sound_bank_preset_state__isValid
    sound_effect_2d__event |> play(sound_effect_2d__path)


[es(tag=sound, track=sound_bank_preset_state__isValid)]
def sound_effect_2d_toggle(evt : Event;
                           sound_bank_preset_state__isValid : bool;
                           sound_effect_2d__path : string;
                           var sound_effect_2d__event : SoundEvent&)
  release(sound_effect_2d__event.handle)
  if sound_bank_preset_state__isValid
    sound_effect_2d__event |> play(sound_effect_2d__path)
