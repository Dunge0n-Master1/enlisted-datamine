require ecs
require math.base
require DngCamera
require soundSystem
require soundEvent


[es(tag=sound, on_appear, track=sound_banks_state__isPresetLoaded)]
def ambient_sound_toggle(evt : Event;
                         sound_banks_state__isPresetLoaded : bool;
                         ambient_sound__path : string;
                         var ambient_sound__event : SoundEvent&)
  release(ambient_sound__event.handle)
  if sound_banks_state__isPresetLoaded
    let listener = (get_cur_cam_entity() |> get_TMatrix("transform") ?? IDENT_TM)[3]
    ambient_sound__event |> play(ambient_sound__path, listener)


// NOT ParallelUpdateFrameDelayed because should accurate bring event to camera(important)
// (AFTER camera tm update && fmod listener setup) and (BEFORE fmod::update)
[es(tag=sound, after=sound_listener_update_es)]
def ambient_sound_update(evt : UpdateStageInfoAct;
                         ambient_sound__event : SoundEvent)
  set_pos(ambient_sound__event.handle, get_listener_pos())
