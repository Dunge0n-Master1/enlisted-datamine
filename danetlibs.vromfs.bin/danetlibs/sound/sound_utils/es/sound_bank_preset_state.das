require ecs
require soundHash
require soundSystem
require sound_utils.modules.sound_utils_events

[es(tag=sound)]
def sound_bank_preset_state_on_toggle(evt : EventOnSoundBanksValid;
                                      sound_bank_preset_state__name : string;
                                      var sound_bank_preset_state__isValid : bool&)
  if evt.hash == sound_hash(sound_bank_preset_state__name)
    sound_bank_preset_state__isValid = evt.isValid

[es(tag=sound, on_appear)]
def sound_bank_preset_state_on_appear(evt : Event;
                                      var sound_bank_preset_state__isValid : bool&;
                                      sound_bank_preset_state__name : string)
  sound_bank_preset_state__isValid = are_banks_valid(sound_bank_preset_state__name)
