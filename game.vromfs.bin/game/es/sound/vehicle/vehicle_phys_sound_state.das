require ecs
require DagorMath
require math.base
require math.ang
require vehicle
require CollRes
require DagorSystem

[es(tag=sound, after=(vehicle_phys_es, sound_control_update))]
def vehicle_phys_sound_state(info : UpdateStageInfoAct;
                             sound_control__enabled : bool;
                             vehicle_net_phys : VehiclePhysActor;
                             var vehicle_sound_state__isOnGround : bool&;
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
                             isAlive : bool = true)

  assume currentState = vehicle_net_phys.phys.currentState

  vehicle_sound_state__isOnGround = isAlive && (currentState.leftTrack.isOnGround || currentState.rightTrack.isOnGround)
  vehicle_sound_state__engineRpm = cvt(vehicle_net_phys.phys.engineRPM, vehicle_net_phys.phys.engineMinRPM, vehicle_net_phys.phys.engineMaxRPM, 0., 100.)
  vehicle_sound_state__engineLoad = vehicle_sound_state__isOnGround ? vehicle_net_phys.phys.engineLoad : 0.
  vehicle_sound_state__isEngineStarted = isAlive && vehicle_net_phys.phys.engineReadyness > 0.

  if !sound_control__enabled
    vehicle_sound_state__prevTransform = transform
    return

  if vehicle_sound_state__speed < 0.
    vehicle_sound_state__prevTransform = transform
  let diffAA = length_sq(transform * collres.vFullBBox.bmin.xyz - vehicle_sound_state__prevTransform * collres.vFullBBox.bmin.xyz)
  let diffBB = length_sq(transform * collres.vFullBBox.bmax.xyz - vehicle_sound_state__prevTransform * collres.vFullBBox.bmax.xyz)
  vehicle_sound_state__speed = cvt(safediv(sqrt(max(diffAA, diffBB)), info.dt), vehicle_sound__minSpeed, vehicle_sound__maxSpeed, 0., 100.)
  vehicle_sound_state__prevTransform = transform

  vehicle_sound_state__deltaShock = vehicle_sound_state__prevSoundShockSummary >= 0. && currentState.soundShockSummary > vehicle_sound_state__prevSoundShockSummary ? currentState.soundShockSummary - vehicle_sound_state__prevSoundShockSummary : 0.
  vehicle_sound_state__prevSoundShockSummary = currentState.soundShockSummary

  let loud = vehicle_sound_state__deltaShock >= vehicle_sound__noiseDeltaShockThreshold || vehicle_sound_state__speed >= vehicle_sound__noiseSpeedThreshold
  vehicle_sound_state__noiseReductionTimer = loud ? 0. : min(vehicle_sound_state__noiseReductionTimer + info.dt, vehicle_sound__noiseReductionDecayPeriod)
  vehicle_sound_state__noiseReduction = 1. - safediv(vehicle_sound_state__noiseReductionTimer, vehicle_sound__noiseReductionDecayPeriod)

  vehicle_sound_state__slip = 0.
  let speed = dot(float3(currentState.velocity), transform[0])

  if currentState.leftTrack.isOnGround
    let wheelSpeed = vehicle_net_phys.phys.currentState.leftTrack.speed * (1. - saturate(abs(currentState.leftSteeringBrake)))
    vehicle_sound_state__slip += abs(wheelSpeed - speed) * 0.5

  if currentState.rightTrack.isOnGround
    let wheelSpeed = vehicle_net_phys.phys.currentState.rightTrack.speed * (1. - saturate(abs(currentState.rightSteeringBrake)))
    vehicle_sound_state__slip += abs(wheelSpeed - speed) * 0.5
