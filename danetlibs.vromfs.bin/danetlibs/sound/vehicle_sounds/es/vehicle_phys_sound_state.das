require ecs
require DagorMath
require math.base
require math.ang
require vehicle
require Dacoll
require CollRes
require DagorSystem


[es(tag=sound, after=(vehicle_phys_es, sound_control_update))]
def vehicle_engine_sound_state(info : UpdateStageInfoAct;
                               vehicle_net_phys : VehiclePhysActor;
                               var vehicle_engine_sound_state__rpm : float&;
                               var vehicle_engine_sound_state__load : float&;
                               var vehicle_engine_sound_state__isStarted : bool&;
                               isAlive : bool = true)
  assume phys = vehicle_net_phys.phys
  let isOnGround = isAlive && (phys.currentState.leftTrack.isOnGround || phys.currentState.rightTrack.isOnGround)
  vehicle_engine_sound_state__rpm = cvt(phys.engineRPM, phys.engineMinRPM, phys.engineMaxRPM, 0., 100.)
  vehicle_engine_sound_state__load = isOnGround ? phys.engineLoad : 0.
  vehicle_engine_sound_state__isStarted = isAlive && phys.engineReadyness > 0.


[es(tag=sound, after=(vehicle_phys_es, sound_control_update, vehicle_phys_engine_sound_state))]
def vehicle_sound_update_speed(info : UpdateStageInfoAct;
                               sound_control__shouldPlay : bool;
                               var vehicle_sound_update_speed__prevTransform : float3x4&;
                               var vehicle_sound_speed : float&;
                               vehicle_sound__minSpeed : float;
                               vehicle_sound__maxSpeed : float;
                               collres : CollisionResource;
                               transform : float3x4)
  if sound_control__shouldPlay
    if vehicle_sound_speed < 0.
      vehicle_sound_update_speed__prevTransform = transform
    let diffAA = length_sq(transform * collres.vFullBBox.bmin.xyz - vehicle_sound_update_speed__prevTransform * collres.vFullBBox.bmin.xyz)
    let diffBB = length_sq(transform * collres.vFullBBox.bmax.xyz - vehicle_sound_update_speed__prevTransform * collres.vFullBBox.bmax.xyz)

    if vehicle_sound__maxSpeed > 0.
      // TODO: remove this, use real values, convert by subsystems
      vehicle_sound_speed = cvt(safediv(sqrt(max(diffAA, diffBB)), info.dt), vehicle_sound__minSpeed, vehicle_sound__maxSpeed, 0., 100.)
    else
      vehicle_sound_speed = safediv(sqrt(max(diffAA, diffBB)), info.dt)
    vehicle_sound_update_speed__prevTransform = transform
  else
    vehicle_sound_speed = -1.


[es(tag=sound, after=(vehicle_phys_es, sound_control_update, vehicle_phys_engine_sound_state))]
def vehicle_sound_state(info : UpdateStageInfoAct;
                        sound_control__shouldPlay : bool;
                        vehicle_net_phys : VehiclePhysActor;
                        var vehicle_sound_state__isOnGround : bool&;
                        var vehicle_sound_state__slip : float&;
                        vehicle_sound_speed : float;
                        var vehicle_sound_state__prevSoundShockSummary : float&;
                        var vehicle_sound_state__deltaShock : float&;
                        vehicle_sound_state__noiseReductionDecayPeriod : float = 5.;
                        vehicle_sound_state__noiseDeltaShockThreshold : float = 1.;
                        vehicle_sound_state__noiseSpeedThreshold : float = 0.5;
                        var vehicle_sound_state__noiseReductionTimer : float&;
                        var vehicle_sound_state__noiseReduction : float&;
                        transform : float3x4;
                        isAlive : bool = true)

  assume phys = vehicle_net_phys.phys
  assume currentState = phys.currentState
  vehicle_sound_state__isOnGround = isAlive && (currentState.leftTrack.isOnGround || currentState.rightTrack.isOnGround)
  vehicle_sound_state__slip = 0.

  if sound_control__shouldPlay
    vehicle_sound_state__deltaShock = vehicle_sound_state__prevSoundShockSummary >= 0. && currentState.soundShockSummary > vehicle_sound_state__prevSoundShockSummary ? currentState.soundShockSummary - vehicle_sound_state__prevSoundShockSummary : 0.
    vehicle_sound_state__prevSoundShockSummary = currentState.soundShockSummary

    let loud = vehicle_sound_state__deltaShock >= vehicle_sound_state__noiseDeltaShockThreshold || vehicle_sound_speed >= vehicle_sound_state__noiseSpeedThreshold
    vehicle_sound_state__noiseReductionTimer = loud ? 0. : min(vehicle_sound_state__noiseReductionTimer + info.dt, vehicle_sound_state__noiseReductionDecayPeriod)
    vehicle_sound_state__noiseReduction = 1. - safediv(vehicle_sound_state__noiseReductionTimer, vehicle_sound_state__noiseReductionDecayPeriod)

    let speed = dot(float3(currentState.velocity), transform[0])
    if currentState.leftTrack.isOnGround
      let wheelSpeed = phys.currentState.leftTrack.speed * (1. - saturate(abs(currentState.leftSteeringBrake)))
      vehicle_sound_state__slip += abs(wheelSpeed - speed) * 0.5
    if currentState.rightTrack.isOnGround
      let wheelSpeed = phys.currentState.rightTrack.speed * (1. - saturate(abs(currentState.rightSteeringBrake)))
      vehicle_sound_state__slip += abs(wheelSpeed - speed) * 0.5
