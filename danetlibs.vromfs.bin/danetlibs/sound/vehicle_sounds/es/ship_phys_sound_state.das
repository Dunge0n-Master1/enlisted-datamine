require ecs
require DagorMath
require math.base
require EnlistedShip
require Dacoll
require CollRes


[es(tag=sound, after=(vehicle_phys_es, sound_control_update))]
def ship_engine_sound_state(info : UpdateStageInfoAct;
                            ship_net_phys : ShipActor;
                            var vehicle_engine_sound_state__rpm : float&;
                            var vehicle_engine_sound_state__load : float&;
                            var vehicle_engine_sound_state__isStarted : bool&;
                            isAlive : bool = true)
  vehicle_engine_sound_state__rpm = cvt(abs(ship_net_phys.phys.engineRPM), ship_net_phys.phys.engineRPMRange.x, ship_net_phys.phys.engineRPMRange.y, 0., 100.)
  vehicle_engine_sound_state__load = max(abs(ship_net_phys.phys.currentState.leftThrottle), abs(ship_net_phys.phys.currentState.rightThrottle))
  vehicle_engine_sound_state__isStarted = isAlive && ship_net_phys.phys.engineRPM != 0.


[es(tag=sound, after=(vehicle_phys_es, sound_control_update, ship_engine_sound_state, vehicle_sound_speed))]
def ship_sound_state(info : UpdateStageInfoAct;
                     sound_control__shouldPlay : bool;
                     ship_net_phys : ShipActor;
                     var vehicle_sound_state__slip : float&;
                     vehicle_sound_speed : float;
                     var vehicle_sound_state__prevSoundShockSummary : float&;
                     var vehicle_sound_state__deltaShock : float&;
                     vehicle_sound_state__noiseReductionDecayPeriod : float = 5.;
                     vehicle_sound_state__noiseDeltaShockThreshold : float = 1.;
                     vehicle_sound_state__noiseSpeedThreshold : float = 0.5;
                     var vehicle_sound_state__noiseReductionTimer : float&;
                     var vehicle_sound_state__noiseReduction : float&;
                     var ship_sound_state__waterTimer : float&;
                     var vehicle_sound_state__water : float&;
                     transform : float3x4)

  vehicle_sound_state__slip = length(ship_net_phys.phys.currentState.omega)

  if sound_control__shouldPlay
    vehicle_sound_state__deltaShock = vehicle_sound_state__prevSoundShockSummary >= 0. && ship_net_phys.phys.soundShockImpulse > vehicle_sound_state__prevSoundShockSummary ? ship_net_phys.phys.soundShockImpulse - vehicle_sound_state__prevSoundShockSummary : 0.
    vehicle_sound_state__prevSoundShockSummary = ship_net_phys.phys.soundShockImpulse
    let loud = vehicle_sound_state__deltaShock >= vehicle_sound_state__noiseDeltaShockThreshold || vehicle_sound_speed >= vehicle_sound_state__noiseSpeedThreshold
    vehicle_sound_state__noiseReductionTimer = loud ? 0. : min(vehicle_sound_state__noiseReductionTimer + info.dt, vehicle_sound_state__noiseReductionDecayPeriod)
    vehicle_sound_state__noiseReduction = 1. - safediv(vehicle_sound_state__noiseReductionTimer, vehicle_sound_state__noiseReductionDecayPeriod)

    ship_sound_state__waterTimer += info.dt
    if ship_sound_state__waterTimer * (1. + vehicle_sound_speed * 0.1) > 1.
      ship_sound_state__waterTimer = 0.
      vehicle_sound_state__water = 0.
      var water = 0.
      if traceht_water(transform[3], water)
        let posXZ = transform[3].xz
        vehicle_sound_state__water = max(0., water - traceht_lmesh(posXZ))
  else
    vehicle_sound_state__water = 0.
