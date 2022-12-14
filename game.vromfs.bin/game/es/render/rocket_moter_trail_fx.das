require ecs
require app
require math.base
require Ballistics
require BallisticsProps
require DagorSystem
require DagorMath
require strings
require fx


def update_effect(fx_tm : float3x4;
                  fx_scale : float;
                  fx_velocity : float3;
                  var fx_eid : EntityId&)
  query(fx_eid) <| $ [es] (var effect : TheEffect&)
    effect_set_scale(effect, fx_scale)

    if fx_scale < 0.1
      destroyEntity(fx_eid)
      fx_eid = INVALID_ENTITY_ID
    else
      effect_set_emitter_tm(effect, fx_tm)
      effect_set_velocity(effect, fx_velocity)


[es(tag=render, on_appear)]
def rocket_motor_trail_on_appear(evt : Event; var rocket_motor_trail__endSmokeViscosity : float&)
  if is_equal_float(rocket_motor_trail__endSmokeViscosity, 0.0)
    rocket_motor_trail__endSmokeViscosity = 0.01
    logerr("rocket_motor_trail__endSmokeViscosity must be greater than 0.0")


[es(tag=render, on_disappear)]
def rocket_motor_trail_on_disappear(evt : Event;
                                    rocket_motor_trail__fireFxEid : EntityId;
                                    rocket_motor_trail__hazeFxEid : EntityId)
  destroyEntity(rocket_motor_trail__fireFxEid)
  destroyEntity(rocket_motor_trail__hazeFxEid)


[es(tag=render, after=update_rocket_motor_phys_es)]
def rocket_motor_trail_on_update(info : UpdateStageInfoAct;
                                 transform : float3x4;
                                 rocket__launchTime : float;
                                 projectile__stopped : bool;
                                 bomb_ballistics_curr : ShellState;
                                 rocket_motor_trail__burnTime : float;
                                 rocket_motor_trail__fireEffect : string;
                                 rocket_motor_trail__hazeEffect : string;
                                 rocket_motor_trail__endSmokeViscosity : float;
                                 rocket_motor_props : RocketMotorProps;
                                 var rocket_motor_trail__fxScale : float&;
                                 var rocket_motor_trail__endedSmoke : bool&;
                                 var rocket_motor_trail__fireFxEid : EntityId&;
                                 var rocket_motor_trail__hazeFxEid : EntityId&;
                                 var rocket_motor_trail__isEffectsStarted : bool&)
  if projectile__stopped
    return

  let flightTime = get_sync_time() - rocket__launchTime

  let thrust = calc_rocket_motor_propulsive_thrust(rocket_motor_props, flightTime)
  if thrust < 1.0
    rocket_motor_trail__endedSmoke = true
  elif !rocket_motor_trail__isEffectsStarted
    rocket_motor_trail__isEffectsStarted = true
    rocket_motor_trail__endedSmoke = false

    if !empty(rocket_motor_trail__fireEffect)
      rocket_motor_trail__fireFxEid = createEntity(rocket_motor_trail__fireEffect) <| $(var init)
        set(init, "transform", transform)

    if !empty(rocket_motor_trail__hazeEffect)
      rocket_motor_trail__hazeFxEid = createEntity(rocket_motor_trail__hazeEffect) <| $(var init)
        set(init, "transform", transform)

  if !rocket_motor_trail__isEffectsStarted
    return

  rocket_motor_trail__fxScale = (rocket_motor_trail__endedSmoke
                              ? approach(rocket_motor_trail__fxScale, 0.0, info.dt, rocket_motor_trail__endSmokeViscosity)
                              : approach(rocket_motor_trail__fxScale, 1.0, flightTime - rocket_motor_props.fireDelay, rocket_motor_trail__burnTime))

  var tm : float3x4
  make_tm(quat(transform), tm)
  tm[3] = transform[3]

  update_effect(tm, rocket_motor_trail__fxScale, bomb_ballistics_curr.velocity, rocket_motor_trail__fireFxEid)
  update_effect(tm, rocket_motor_trail__fxScale, bomb_ballistics_curr.velocity, rocket_motor_trail__hazeFxEid)
