require ecs
require soundSystem
require math.base

[es(tag=sound, after=animchar_render_es)]
def sound_control_update(info : UpdateStageInfoAct;
                         sound_bank_preset_state__isValid : bool;
                         sound_control__active : bool;
                         sound_control__range : float;
                         var sound_control__inRange : bool&;
                         var sound_control__enabled : bool&;
                         is_watched_sound : bool = false;
                         transform : float3x4)
  sound_control__inRange = is_watched_sound || (sound_control__inRange ? (distance_sq(get_listener_pos(), transform[3]) < square(sound_control__range)) :
                                                                         (distance_sq(get_listener_pos(), transform[3]) < square(sound_control__range * 0.9)))
  sound_control__enabled = sound_control__inRange && sound_bank_preset_state__isValid && sound_control__active
