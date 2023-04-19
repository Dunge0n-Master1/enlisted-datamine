require ecs
require soundEvent


[es(tag=sound, after=global_sound_listener_position_update)]
def compound_sound_effect_update_event_pos(info : UpdateStageInfoAct;
                                           global_sound_listener_position : float3;
                                           compound_sound_effect__event : SoundEvent)
  if compound_sound_effect__event.handle != invalid_sound_event_handle()
    set_pos(compound_sound_effect__event.handle, global_sound_listener_position) // accurate bring event to camera(important)


[es(tag=sound, on_appear, track=sound_bank_preset_state__isValid)]
def compound_sound_effect_toggle(evt : Event;
                                 sound_bank_preset_state__isValid : bool;
                                 compound_sound_effect__path : string;
                                 var compound_sound_effect__range : float&;
                                 var compound_sound_effect__event : SoundEvent&)
  release_immediate(compound_sound_effect__event.handle)
  if sound_bank_preset_state__isValid
    compound_sound_effect__range = get_max_distance(compound_sound_effect__path)
