require ecs
require soundEvent
require soundSystem


[es(tag=sound, on_appear, track=sound_bank_preset_state__isValid)]
def ambient_sound_toggle(evt : Event;
                         sound_bank_preset_state__isValid : bool;
                         ambient_sound__path : string;
                         var ambient_sound__event : SoundEvent&)
  release(ambient_sound__event.handle)
  if sound_bank_preset_state__isValid
    ambient_sound__event |> play(ambient_sound__path, get_listener_pos())


[es(tag=sound, on_event=ParallelUpdateFrameDelayed)]
def ambient_sound_update(evt : Event;
                         ambient_sound__event : SoundEvent)
  set_pos(ambient_sound__event.handle, get_listener_pos())
