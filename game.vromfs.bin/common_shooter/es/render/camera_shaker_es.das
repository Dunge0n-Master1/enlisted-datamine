require ecs
require game.es.events
require math
require math.base
require DagorMath
require DngPhysObj
require CameraShaker
require DngCameraShaker
require BallisticsProps
require enlisted.events_enlisted

[es(tag=gameClient, after=after_camera_sync)]
def camera_shaker_update_es(info : UpdateStageInfoAct;
                            var camera_shaker : CameraShaker;
                            var transform : float3x4&)
  camera_shaker_update(camera_shaker, info.dt)
  camera_shaker_shakeMatrix(camera_shaker, transform)

[es(tag=gameClient, no_order)]
def shell_fly_shock_wave_es(info : ParallelUpdateFrameDelayed;
                            phys_obj_net_phys : PhysObjActor;
                            shell__shell_id__shell_id : int;
                            active : bool&)
  if active != true
    return
  let pos = float3(phys_obj_net_phys.phys.currentState.location.P)
  let prevPos = float3(phys_obj_net_phys.phys.previousState.location.P)
  projectile_get_props(shell__shell_id__shell_id) <| $(props : ProjectileProps)
    if props.caliber > 0.f
      broadcastEvent([[ProjectileFlyShockWave position=pos, prev_position=prevPos, caliber=props.caliber]])

[es(tag=gameClient)]
def cmd_shake_camera_es(evt : CmdShakeCamera;
                        var camera_shaker : CameraShaker;
                        transform : float3x4&)
  let pos = evt.position
  let distanceSq = length_sq(pos - transform[3])
  let maxDistSq = square(evt.max_distance)
  if distanceSq < maxDistSq
    let maxPower = evt.wish_shake
    let smooth = evt.smooth
    let shakePower = cvt(square(maxDistSq - distanceSq), 0.f, maxDistSq, 0.f, maxPower)
    camera_shaker_setShake(camera_shaker, shakePower)
    camera_shaker_setShakeHiFreq(camera_shaker, shakePower / smooth)
    camera_shaker_setSmoothShakeHiFreq(camera_shaker, shakePower * smooth)

[es(tag=gameClient)]
def camera_shaker_shell_explosion_es(evt : EventShellExplosionShockWave;
                                     var camera_shaker : CameraShaker;
                                     transform : float3x4&;
                                     camera_shaker__waveMinPower : float;
                                     camera_shaker__waveMaxPower : float;
                                     camera_shaker__waveRadiusMod : float;
                                     camera_shaker__waveDamageMod : float)
  let explosionPos = evt.position
  let damageRadius = evt.dmg_radius
  let damageHp = evt.dmg_hp
  let blastWaveRadiusSq = square(damageRadius * camera_shaker__waveRadiusMod)
  let distanceSq = length_sq(transform[3] - explosionPos)
  if distanceSq < blastWaveRadiusSq
    let waveWeakening = cvt(distanceSq, 0.f, blastWaveRadiusSq, 0.f, camera_shaker__waveMaxPower - camera_shaker__waveMinPower)
    let shakePower = (camera_shaker__waveMaxPower - waveWeakening) * damageHp * camera_shaker__waveDamageMod
    camera_shaker_setShake(camera_shaker, shakePower)
    camera_shaker_setShakeHiFreq(camera_shaker, shakePower)
    camera_shaker_setSmoothShakeHiFreq(camera_shaker, shakePower)

[es(tag=gameClient)]
def camera_shaker_projectile_fly_es(evt : ProjectileFlyShockWave;
                                    var camera_shaker : CameraShaker;
                                    transform : float3x4&;
                                    camera_shaker__projectilePowerMod : float;
                                    camera_shaker__projectileMaxDistance : float;
                                    camera_shaker__projectileMinCaliber : float;
                                    camera_shaker__projectileShakeSmooth : float)
  let caliber = evt.caliber
  if caliber < camera_shaker__projectileMinCaliber
    return

  let pos = evt.position
  let prevPos = evt.prev_position
  let dir = normalize(pos - prevPos)
  let closestPointOnDir = pos + dir * dot(transform[3] - pos, dir)
  let distanceSq = length_sq(transform[3] - closestPointOnDir)
  if distanceSq < square(camera_shaker__projectileMaxDistance) && dot(prevPos - closestPointOnDir, dir) <= 0.f && dot(pos - closestPointOnDir, dir) > 0.f
    let maxPower = caliber * camera_shaker__projectilePowerMod
    let shakePower = maxPower - cvt(distanceSq, 0.f, square(camera_shaker__projectileMaxDistance), 0.f, maxPower)
    camera_shaker_setShake(camera_shaker, shakePower)
    camera_shaker_setShakeHiFreq(camera_shaker, shakePower / camera_shaker__projectileShakeSmooth)
    camera_shaker_setSmoothShakeHiFreq(camera_shaker, shakePower * camera_shaker__projectileShakeSmooth)

def camera_shaker_add_smooth_shake(var camera_shaker : CameraShaker;
                                   target : float3&;
                                   source : float3&;
                                   maxDist : float;
                                   maxPower : float;
                                   smooth : float)
  let distanceSq = length_sq(target - source)
  let maxDistSq = square(maxDist)
  if distanceSq < maxDistSq
    let shakePower = cvt(square(maxDistSq - distanceSq), 0.f, maxDistSq, 0.f, maxPower)
    camera_shaker_setShake(camera_shaker, shakePower)
    camera_shaker_setShakeHiFreq(camera_shaker, shakePower / smooth)
    camera_shaker_setSmoothShakeHiFreq(camera_shaker, shakePower * smooth)

[es(tag=gameClient)]
def camera_shaker_projectile_hit_es(evt : ProjectileHitShake;
                                    var camera_shaker : CameraShaker&;
                                    transform : float3x4&;
                                    camera_shaker__projectileMaxDistance : float;
                                    camera_shaker__projectileShakeSmooth : float;
                                    camera_shaker__projectileHitDamageMod : float)
  let position = evt.position
  let damage = evt.damage
  camera_shaker_add_smooth_shake(camera_shaker,
                                 transform[3],
                                 position,
                                 camera_shaker__projectileMaxDistance,
                                 damage * camera_shaker__projectileHitDamageMod,
                                 camera_shaker__projectileShakeSmooth)

[es(tag=gameClient)]
def camera_shaker_vehicle_earth_tremor_es(evt : EventVehicleEarthTremor;
                                          var camera_shaker : CameraShaker;
                                          transform : float3x4&;
                                          camera__target : EntityId;
                                          camera_shaker__vehicleMaxDistance : float;
                                          camera_shaker__vehicleShakeSmooth : float;
                                          camera_shaker__vehicleMassMod : float;
                                          camera_shaker__vehicleSpeedMod : float;
                                          bindToVehicle : bool = false;
                                          camera__active : bool&)
  if !camera__active || bindToVehicle || get_bool(camera__target, "isInVehicle") ?? false
    return
  let position = evt.position
  let mass = evt.mass
  let speed = evt.speed
  let massShake = mass * camera_shaker__vehicleMassMod
  let speedShake = speed * camera_shaker__vehicleSpeedMod
  camera_shaker_add_smooth_shake(camera_shaker,
                                 transform[3],
                                 position,
                                 camera_shaker__vehicleMaxDistance,
                                 massShake + speedShake,
                                 camera_shaker__vehicleShakeSmooth)
