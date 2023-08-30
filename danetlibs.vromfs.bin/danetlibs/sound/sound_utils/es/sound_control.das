require ecs
require soundSystem
require math.base


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=animchar_render_es, REQUIRE_NOT=disableSoundControl)]
def sound_control_update(evt : Event;
                         sound_banks_state__isPresetLoaded : bool;
                         sound_control__enable : bool;
                         sound_control__range : float;
                         var sound_control__inRange : bool&;
                         var sound_control__shouldPlay : bool&;
                         is_watched_sound : bool = false;
                         transform : float3x4)
  sound_control__inRange = is_watched_sound || (sound_control__inRange ? (distance_sq(get_listener_pos(), transform[3]) < square(sound_control__range)) :
                                                                         (distance_sq(get_listener_pos(), transform[3]) < square(sound_control__range * 0.9)))
  sound_control__shouldPlay = sound_control__inRange && sound_banks_state__isPresetLoaded && sound_control__enable


[es(tag=sound, on_appear, REQUIRE=disableSoundControl)]
def sound_control_disable(evt : Event;
                          var sound_control__shouldPlay : bool&)
  sound_control__shouldPlay = false
