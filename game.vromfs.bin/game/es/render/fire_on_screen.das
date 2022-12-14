require ecs
require game.es.lut_switcher_common
require DagorShaders
require app
require math.base
require DagorMath
require player
require DagorSystem

let
  fire_on_screen_endVarId = get_shader_variable_id("fire_on_screen_end_time", true)
  angle_deltaVarId = get_shader_variable_id("fire_on_screen_horizontal_delta", true)

[es(tag=render, on_disappear, REQUIRE=hero)]
def fire_on_screen_reset_es(evt : Event)
  DagorShaders::set_real(fire_on_screen_endVarId, -1.0)

[es(tag=render, no_order, REQUIRE=hero)]
def fire_on_screen_update_es(act : ecs::UpdateStageInfoAct; burning__isBurning : bool; isAlive : bool;
                             camera__prevLookDir : float3 const&; camera__lookDir : float3 const&)
  if !burning__isBurning || !isAlive
    return
  DagorShaders::set_real(fire_on_screen_endVarId, get_shader_global_time_phase(0.0, 0.0))
  let phi_old = atan2(camera__prevLookDir.x, camera__prevLookDir.z)
  let phi_new = atan2(camera__lookDir.x, camera__lookDir.z)
  var delta = phi_new - phi_old
  if delta > PI
    delta -= TWOPI
  elif delta < -PI
    delta += TWOPI
  delta *= 10.0
  let prev_delta = DagorShaders::get_real(angle_deltaVarId)
  DagorShaders::set_real(angle_deltaVarId, lerp(prev_delta, delta, pow(0.02, safeinv(min(act.dt, 0.1)) / 150.0)))