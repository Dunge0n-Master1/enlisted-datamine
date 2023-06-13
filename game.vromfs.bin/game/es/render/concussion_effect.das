require ecs
require app
require game.utils.hero
require DagorShaders

let
  concsussion_effect_time_startVarId = get_shader_variable_id("concussion_effect_time_start", true)
  concussion_effect_durationVarId = get_shader_variable_id("concussion_effect_duration", true)
  concussion_effect_intensityVarId = get_shader_variable_id("concussion_shake_intensity", true)

def enable_concussion_screen_effect(duration : float; intensity : float)
  DagorShaders::set_real(concsussion_effect_time_startVarId, get_shader_global_time_phase(0.0, 0.0))
  DagorShaders::set_real(concussion_effect_durationVarId, duration)
  DagorShaders::set_real(concussion_effect_intensityVarId, intensity)

def disable_concussion_screen_effect()
  DagorShaders::set_real(concsussion_effect_time_startVarId, -1000.0)

[es(tag=render, REQUIRE=(hero, hasConcussedVision), on_disappear)]
def disable_concussion_vision_on_destroy(evt : Event)
  disable_concussion_screen_effect()

[es(tag=render, REQUIRE=hero, REQUIRE_NOT=deadEntity, track=(hasConcussedVision, concussion__endTime), on_appear)]
def track_concussion_vision(evt : Event;
                            hasConcussedVision : bool;
                            concussion__endTime : float;
                            concussion__visionIntensity : float)
  if !hasConcussedVision
    disable_concussion_screen_effect()
  else
    enable_concussion_screen_effect(concussion__endTime - get_sync_time(), concussion__visionIntensity)
