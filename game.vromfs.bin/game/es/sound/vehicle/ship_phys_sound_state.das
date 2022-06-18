require ecs
require DagorMath
require math.base
require EnlistedShip
require Dacoll
require CollRes


[es(tag=sound, after=(vehicle_phys_es, sound_control_update))]
def ship_phys_sound_state(info : UpdateStageInfoAct;
                          sound_control__enabled : bool;
                          ship_net_phys : ShipActor;
                          var vehicle_sound_state__engineRpm : float&;
                          var vehicle_sound_state__engineLoad : float&;
                          var vehicle_sound_state__isEngineStarted : bool&;
                          var vehicle_sound_state__slip : float&;

                          var vehicle_sound_state__prevTransform : float3x4&;
                          var vehicle_sound_state__speed : float&;
                          vehicle_sound__minSpeed : float = 0.5;
                          vehicle_sound__maxSpeed : float = 10.;
                          var vehicle_sound_state__prevSoundShockSummary : float&;
                          var vehicle_sound_state__deltaShock : float&;
                          vehicle_sound__noiseReductionDecayPeriod : float = 5.;
                          vehicle_sound__noiseDeltaShockThreshold : float = 1.;
                          vehicle_sound__noiseSpeedThreshold : float = 0.5;
                          var vehicle_sound_state__noiseReductionTimer : float&;
                          var vehicle_sound_state__noiseReduction : float&;
                          collres : CollisionResource;
                          transform : float3x4;

                          var vehicle_sound_state__surfaceTimer : float&;
                          var vehicle_sound_state__surfaceWater : float&;
                          isAlive : bool = true)

  vehicle_sound_state__engineRpm = cvt(abs(ship_net_phys.phys.engineRPM), ship_net_phys.phys.engineRPMRange.x, ship_net_phys.phys.engineRPMRange.y, 0., 100.)
  vehicle_sound_state__engineLoad = max(abs(ship_net_phys.phys.currentState.leftThrottle), abs(ship_net_phys.phys.currentState.rightThrottle))
  vehicle_sound_state__isEngineStarted = isAlive && ship_net_phys.phys.engineRPM != 0.
  vehicle_sound_state__slip = length(ship_net_phys.phys.currentState.omega)

  if !sound_control__enabled
    vehicle_sound_state__prevTransform = transform
    return

  if vehicle_sound_state__speed < 0.
    vehicle_sound_state__prevTransform = transform
  let diffAA = length_sq(transform * collres.vFullBBox.bmin.xyz - vehicle_sound_state__prevTransform * collres.vFullBBox.bmin.xyz)
  let diffBB = length_sq(transform * collres.vFullBBox.bmax.xyz - vehicle_sound_state__prevTransform * collres.vFullBBox.bmax.xyz)
  vehicle_sound_state__speed = cvt(safediv(sqrt(max(diffAA, diffBB)), info.dt), vehicle_sound__minSpeed, vehicle_sound__maxSpeed, 0., 100.)
  vehicle_sound_state__prevTransform = transform

  vehicle_sound_state__deltaShock = vehicle_sound_state__prevSoundShockSummary >= 0. && ship_net_phys.phys.soundShockImpulse > vehicle_sound_state__prevSoundShockSummary ? ship_net_phys.phys.soundShockImpulse - vehicle_sound_state__prevSoundShockSummary : 0.
  vehicle_sound_state__prevSoundShockSummary = ship_net_phys.phys.soundShockImpulse

  let loud = vehicle_sound_state__deltaShock >= vehicle_sound__noiseDeltaShockThreshold || vehicle_sound_state__speed >= vehicle_sound__noiseSpeedThreshold
  vehicle_sound_state__noiseReductionTimer = loud ? 0. : min(vehicle_sound_state__noiseReductionTimer + info.dt, vehicle_sound__noiseReductionDecayPeriod)
  vehicle_sound_state__noiseReduction = 1. - safediv(vehicle_sound_state__noiseReductionTimer, vehicle_sound__noiseReductionDecayPeriod)

  vehicle_sound_state__surfaceTimer += info.dt
  if vehicle_sound_state__surfaceTimer * (1. + vehicle_sound_state__speed * 0.1) > 1.
    vehicle_sound_state__surfaceTimer = 0.
    vehicle_sound_state__surfaceWater = 0.
    var water = 0.
    if traceht_water(transform[3], water)
      let posXZ = transform[3].xz
      vehicle_sound_state__surfaceWater = max(0., water - traceht_lmesh(posXZ))
