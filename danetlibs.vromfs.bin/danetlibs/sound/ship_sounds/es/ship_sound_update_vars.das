require ecs
require DagorMath
require math.base
require EnlistedShip
require Dacoll
require CollRes
require sound_utils_net.modules.sound_utils_net_events


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=(vehicle_phys_es, sound_control_update))]
def ship_engine_sound_update_vars(evt : Event;
                                  ship_net_phys : ShipActor;
                                  var vehicle_engine_sound_vars__rpm : float&;
                                  var vehicle_engine_sound_vars__load : float&;
                                  var vehicle_engine_sound_vars__isStarted : bool&;
                                  isAlive : bool)
  vehicle_engine_sound_vars__rpm = cvt(abs(ship_net_phys.phys.engineRPM), ship_net_phys.phys.engineRPMRange.x, ship_net_phys.phys.engineRPMRange.y, 0., 100.)
  vehicle_engine_sound_vars__load = max(abs(ship_net_phys.phys.currentState.leftThrottle), abs(ship_net_phys.phys.currentState.rightThrottle))
  vehicle_engine_sound_vars__isStarted = isAlive && ship_net_phys.phys.engineRPM != 0.


[es(tag=sound, after=(vehicle_phys_es, sound_control_update, ship_engine_sound_update_vars, vehicle_sound_update_speed))]
def ship_sound_update_vars(info : ParallelUpdateFrameDelayed;
                           sound_control__shouldPlay : bool;
                           ship_net_phys : ShipActor;
                           var vehicle_sound_vars__slip : float&;
                           vehicle_sound_vars__speed : float;
                           var vehicle_sound_vars__prevSoundShockSummary : float&;
                           var vehicle_sound_vars__deltaShock : float&;
                           vehicle_sound_vars__noiseReductionDecayPeriod : float;
                           vehicle_sound_vars__noiseDeltaShockThreshold : float;
                           vehicle_sound_vars__noiseSpeedThreshold : float;
                           var vehicle_sound_vars__noiseReductionTimer : float&;
                           var vehicle_sound_vars__noiseReduction : float&;
                           var ship_sound_vars__waterTimer : float&;
                           var vehicle_sound_vars__water : float&;
                           transform : float3x4)

  vehicle_sound_vars__slip = length(ship_net_phys.phys.currentState.omega)

  if sound_control__shouldPlay
    vehicle_sound_vars__deltaShock = vehicle_sound_vars__prevSoundShockSummary >= 0. && ship_net_phys.phys.soundShockImpulse > vehicle_sound_vars__prevSoundShockSummary ? ship_net_phys.phys.soundShockImpulse - vehicle_sound_vars__prevSoundShockSummary : 0.
    vehicle_sound_vars__prevSoundShockSummary = ship_net_phys.phys.soundShockImpulse
    let loud = vehicle_sound_vars__deltaShock >= vehicle_sound_vars__noiseDeltaShockThreshold || vehicle_sound_vars__speed >= vehicle_sound_vars__noiseSpeedThreshold
    vehicle_sound_vars__noiseReductionTimer = loud ? 0. : min(vehicle_sound_vars__noiseReductionTimer + info.dt, vehicle_sound_vars__noiseReductionDecayPeriod)
    vehicle_sound_vars__noiseReduction = 1. - safediv(vehicle_sound_vars__noiseReductionTimer, vehicle_sound_vars__noiseReductionDecayPeriod)

    ship_sound_vars__waterTimer += info.dt
    if ship_sound_vars__waterTimer * (1. + vehicle_sound_vars__speed) > 1.
      ship_sound_vars__waterTimer = 0.
      vehicle_sound_vars__water = 0.
      var water = 0.
      if traceht_water(transform[3], water)
        let posXZ = transform[3].xz
        vehicle_sound_vars__water = max(0., water - traceht_lmesh(posXZ))
  else
    vehicle_sound_vars__water = 0.
