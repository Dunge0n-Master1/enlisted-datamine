require ecs
require math.base
require game.events_game
require DagorMath
require Grid
require GridCollision
require game.es.effects.effect_controller_common

[es(tag=server, track=(effect_controller__state, effect_scale_randomizer__scale))]
def convert_spawn_rate_to_push(evt : Event; effect_controller__state : int;  effect_controller__states : Array;
                               effect_scale_randomizer__scale : float;
                               push_effect__spawnRateThreshold : float; var push_effect__active : bool&; var push_effect__scale : float&)
  let stateParams = get_effect_state_params(effect_controller__states, effect_controller__state)
  let spawnRate = 0.5 * (stateParams.spawnRate.x + stateParams.spawnRate.y)

  push_effect__active = spawnRate > push_effect__spawnRateThreshold
  push_effect__scale = effect_scale_randomizer__scale

[es(tag=server, no_order)]
def push_effect_update(info : UpdateStageInfoAct; transform : float3x4; push_effect__active : bool;
                       push_effect__distance, push_effect__vehicleDistance, push_effect__distancePower : float;
                       push_effect__powerLimits : float2; push_effect__direction : float3;
                       push_effect__vehicleEnergyScale, push_effect__shipEnergyScale, push_effect__immunityAmount : float;
                       push_effect__speed, push_effect__scale : float)
  if !push_effect__active
    return
  let center = transform[3]
  for_each_entity_in_grid([[uint[] ecs_hash("humans"); ecs_hash("vehicles")]], BSphere3(center, max(push_effect__distance, push_effect__vehicleDistance)), GridEntCheck BOUNDING) <| $(targetEid : EntityId; targetPos : float3)
    let isHuman = targetEid |> has("human_net_phys")
    let maxDist = isHuman ? push_effect__distance : push_effect__vehicleDistance
    var dir = targetPos - center
    if length_sq(dir) > square(maxDist)
      return
    let dirLen = length(dir)
    dir *= safeinv(dirLen)
    let power = pow(1f - safediv(dirLen, maxDist), push_effect__distancePower) * push_effect__scale
    let fixedPower = clamp(power, push_effect__powerLimits.x, push_effect__powerLimits.y)
    if isHuman
      let vel = dir + push_effect__direction * fixedPower * push_effect__speed
      sendEvent(targetEid, [[CmdPushPhys vel=vel, push_immunity=push_effect__immunityAmount]])
    else
      let scaledDir = dir + push_effect__direction * fixedPower
      if targetEid |> has("vehicle_net_phys")
        sendEvent(targetEid, [[CmdVehiclePushPhys energyScaledDir=scaledDir * push_effect__vehicleEnergyScale, arm=center, duration=0.0]])
      elif targetEid |> has("ship_net_phys")
        sendEvent(targetEid, [[CmdVehiclePushPhys energyScaledDir=scaledDir * push_effect__shipEnergyScale, arm=center, duration=0.0]])
