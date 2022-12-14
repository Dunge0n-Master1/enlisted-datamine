require ecs
require DagorMath
require math.base
require math.ang
require vehicle
require Dacoll
require CollRes
require DagorSystem
require sound_utils_net.modules.sound_utils_net_events


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=(vehicle_phys_es, sound_control_update))]
def vehicle_engine_sound_update_vars(evt : Event;
                                     vehicle_net_phys : VehiclePhysActor;
                                     var vehicle_engine_sound_vars__rpm : float&;
                                     var vehicle_engine_sound_vars__load : float&;
                                     var vehicle_engine_sound_vars__isStarted : bool&;
                                     isAlive : bool = true)
  assume phys = vehicle_net_phys.phys
  let isOnGround = phys.currentState.leftTrack.isOnGround || phys.currentState.rightTrack.isOnGround
  vehicle_engine_sound_vars__rpm = cvt(phys.engineRPM, phys.engineMinRPM, phys.engineMaxRPM, 0., 100.)
  vehicle_engine_sound_vars__load = isOnGround ? phys.engineLoad : 0.
  vehicle_engine_sound_vars__isStarted = isAlive && phys.engineReadyness > 0. && phys.isICEWorking


[es(tag=sound, after=(vehicle_phys_es, sound_control_update, vehicle_engine_sound_update_vars))]
def vehicle_sound_update_speed(info : ParallelUpdateFrameDelayed;
                               sound_control__shouldPlay : bool;
                               var vehicle_sound_update_speed__prevTransform : float3x4&;
                               var vehicle_sound_vars__speed : float&;
                               var vehicle_sound_vars__linearVelocity : float3&;
                               collres : CollisionResource;
                               transform : float3x4)
  if sound_control__shouldPlay
    if vehicle_sound_vars__speed < 0.
      vehicle_sound_update_speed__prevTransform = transform

    let diffAA = length_sq(transform * collres.vFullBBox.bmin.xyz - vehicle_sound_update_speed__prevTransform * collres.vFullBBox.bmin.xyz)
    let diffBB = length_sq(transform * collres.vFullBBox.bmax.xyz - vehicle_sound_update_speed__prevTransform * collres.vFullBBox.bmax.xyz)

    vehicle_sound_vars__speed = safediv(sqrt(max(diffAA, diffBB)), info.dt)
    vehicle_sound_vars__linearVelocity = (transform[3] - vehicle_sound_update_speed__prevTransform[3]) * safeinv(info.dt)
    vehicle_sound_update_speed__prevTransform = transform
  else
    vehicle_sound_vars__speed = -1.


[es(tag=sound, after=(vehicle_phys_es, sound_control_update, vehicle_engine_sound_update_vars))]
def vehicle_sound_update_vars(info : ParallelUpdateFrameDelayed;
                              sound_control__shouldPlay : bool;
                              vehicle_net_phys : VehiclePhysActor;
                              var vehicle_sound_vars__isOnGround : bool&;
                              var vehicle_sound_vars__slip : float&;
                              vehicle_sound_vars__speed : float;
                              var vehicle_sound_vars__prevSoundShockSummary : float&;
                              var vehicle_sound_vars__deltaShock : float&;
                              vehicle_sound_vars__noiseReductionDecayPeriod : float;
                              vehicle_sound_vars__noiseDeltaShockThreshold : float;
                              vehicle_sound_vars__noiseSpeedThreshold : float;
                              var vehicle_sound_vars__noiseReductionTimer : float&;
                              var vehicle_sound_vars__noiseReduction : float&;
                              transform : float3x4)

  assume phys = vehicle_net_phys.phys
  assume currentState = phys.currentState
  vehicle_sound_vars__isOnGround = currentState.leftTrack.isOnGround || currentState.rightTrack.isOnGround
  vehicle_sound_vars__slip = 0.

  if sound_control__shouldPlay
    vehicle_sound_vars__deltaShock = vehicle_sound_vars__prevSoundShockSummary >= 0. && currentState.soundShockSummary > vehicle_sound_vars__prevSoundShockSummary ? currentState.soundShockSummary - vehicle_sound_vars__prevSoundShockSummary : 0.
    vehicle_sound_vars__prevSoundShockSummary = currentState.soundShockSummary

    let loud = vehicle_sound_vars__deltaShock >= vehicle_sound_vars__noiseDeltaShockThreshold || vehicle_sound_vars__speed >= vehicle_sound_vars__noiseSpeedThreshold
    vehicle_sound_vars__noiseReductionTimer = loud ? 0. : min(vehicle_sound_vars__noiseReductionTimer + info.dt, vehicle_sound_vars__noiseReductionDecayPeriod)
    vehicle_sound_vars__noiseReduction = 1. - safediv(vehicle_sound_vars__noiseReductionTimer, vehicle_sound_vars__noiseReductionDecayPeriod)

    let speed = dot(float3(currentState.velocity), transform[0])
    if currentState.leftTrack.isOnGround
      let wheelSpeed = phys.currentState.leftTrack.speed * (1. - saturate(abs(currentState.leftSteeringBrake)))
      vehicle_sound_vars__slip += abs(wheelSpeed - speed) * 0.5
    if currentState.rightTrack.isOnGround
      let wheelSpeed = phys.currentState.rightTrack.speed * (1. - saturate(abs(currentState.rightSteeringBrake)))
      vehicle_sound_vars__slip += abs(wheelSpeed - speed) * 0.5
