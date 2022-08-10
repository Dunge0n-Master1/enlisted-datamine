require ecs
require DagorShaders
require DagorSystem
require game.utils.hero
require EnlistedDm
require game.es.vehicle.vehicle_seats_common

let
  smoke_blackout_effect_time_startVarId = get_shader_variable_id("smoke_blackout_effect_time_start", true)
  smoke_blackout_effect_time_endVarId = get_shader_variable_id("smoke_blackout_effect_time_end", true)
  smoke_blackout_effect_interval_VarId = get_shader_variable_id("smoke_blackout", true)
  smoke_blackout_decrease_duration_VarId = get_shader_variable_id("smoke_blackout_effect_decrease_duration", true)

def instant_effect_stop()
  DagorShaders::set_real(smoke_blackout_effect_time_startVarId, -1000f)
  DagorShaders::set_real(smoke_blackout_effect_time_endVarId, -1000f)
  DagorShaders::set_int(smoke_blackout_effect_interval_VarId, 0)

[es(tag=render, no_order, REQUIRE=heroVehicle)]
def control_blackout_effect_inside_vehicle_es(info : UpdateStageInfoBeforeRender;
                                              fire_damage__isBurn : bool;
                                              fire_damage__startTime : float;
                                              vehicle_seats__seatEids : EidList)
  let heroId = get_controlled_hero()
  if !fire_damage__isBurn
    query(heroId) <| $ [es] (var burning__isBlackouted : bool&;
                             var burning__blackoutEffectEndTime : float&;
                             var burning__blackoutDecreaseDuration : float&)
      if !burning__isBlackouted
        if burning__blackoutEffectEndTime > 0f
          if burning__blackoutDecreaseDuration < 0f
            burning__blackoutDecreaseDuration = DagorShaders::get_real(smoke_blackout_decrease_duration_VarId)
          if get_shader_global_time_phase(0f, 0f) - burning__blackoutEffectEndTime > burning__blackoutDecreaseDuration
            burning__blackoutEffectEndTime = -1f
            DagorShaders::set_int(smoke_blackout_effect_interval_VarId, 0)
        return
      burning__isBlackouted = false
      DagorShaders::set_real(smoke_blackout_effect_time_endVarId, get_shader_global_time_phase(0f, 0f))
      burning__blackoutEffectEndTime = get_shader_global_time_phase(0f, 0f)
  let seatNo = find_seat_with_owner(heroId, vehicle_seats__seatEids)
  if seatNo < 0
    return
  var shouldBeBlackouted = true
  query(vehicle_seats__seatEids[seatNo]) <| $ [es] (seat__allowSmokeScreen : bool = true; seats_hatch_nodes__isValid : bool = false; seats_hatch_nodes__openPos : float = 0.f)
    let hasHatch = seats_hatch_nodes__isValid
    let isHatchClosed = hasHatch && seats_hatch_nodes__openPos <= 0.f
    shouldBeBlackouted &&= seat__allowSmokeScreen && (!hasHatch || isHatchClosed)
  query(heroId) <| $ [es] (var burning__isBlackouted : bool&; isAlive : bool)
    shouldBeBlackouted &&= isAlive
    if !burning__isBlackouted && shouldBeBlackouted
      if fire_damage__startTime > 0.0
        DagorShaders::set_real(smoke_blackout_effect_time_startVarId, fire_damage__startTime)
        DagorShaders::set_real(smoke_blackout_effect_time_endVarId, fire_damage__startTime + 1000f)
        DagorShaders::set_int(smoke_blackout_effect_interval_VarId, 1)
        burning__isBlackouted = true
    if burning__isBlackouted && !shouldBeBlackouted
      burning__isBlackouted = false
      instant_effect_stop()

[es(tag=render, REQUIRE=heroVehicle, on_disappear)]
def stop_blackout_effect_outside_vehicle_es(evt : Event)
  find_query() <| $ [es(REQUIRE=hero)] (var burning__isBlackouted : bool&)
    burning__isBlackouted = false
    instant_effect_stop()
    return true

[es(on_disappear, tag=render, no_order, REQUIRE=hero)]
def stop_blackout_effect_critical_es(evt : Event; var burning__isBlackouted : bool&)
  burning__isBlackouted = false
  instant_effect_stop()
