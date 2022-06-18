require ecs
require app
require DagorShaders

let
  flash_blind_intensityVarId = get_shader_variable_id("flash_blind_intensity", true)

[es(tag=render, REQUIRE=flash_blind__intensity, on_appear)]
def blind_flash_es(evt : Event; flash_blind__intensity : float)
  DagorShaders::set_real(flash_blind_intensityVarId, flash_blind__intensity)
