require ecs
require DagorMath
require math
require math.base
require math.easing
require game.es.events
require game.utils.hero
require game.events_game
require EnlistedDm
require HumanPhys
require EnlistedHuman
require DaWeapons
require common_shooter.es.render.camera_shaker_common
require common_shooter.events_common_shooter


def calc_trauma(trauma, addTrauma, maxTrauma)
  return trauma >= maxTrauma ? trauma : clamp(min(trauma + addTrauma, maxTrauma), 0.f, 1.f)

[es(tag=gameClient)]
def camera_shaker_perlin_add_trauma(evt : CmdAddCameraTrauma;
                                    camera__active : bool;
                                    var camera_shaker__trauma : float&)
  if camera__active
    camera_shaker__trauma = calc_trauma(camera_shaker__trauma, evt.addTrauma, evt.maxTrauma)

[es(tag=gameClient)]
def camera_shaker_perlin_add_trauma_by_distance(evt : CmdAddCameraTraumaByDistance;
                                                transform : float3x4;
                                                camera__active : bool;
                                                var camera_shaker__trauma : float&)
  if camera__active
    let distanceSq = length_sq(evt.position - transform[3])
    let maxDistSq = square(evt.maxDistance)
    let maxTrauma = cvt(maxDistSq - distanceSq, 0.f, maxDistSq, 0.f, evt.maxTrauma)
    camera_shaker__trauma = calc_trauma(camera_shaker__trauma, evt.addTrauma, maxTrauma)

[es(tag=gameClient)]
def camera_shaker_perlin_punch(evt : CmdCameraPunch;
                               camera__active : bool;
                               var camera_shaker__punch : float&;
                               var camera_shaker__punchAngles : float3&)
  if camera__active && camera_shaker__punch <= 0.05f
    camera_shaker__punch = 1.f
    camera_shaker__punchAngles = evt.angles * DEG_TO_RAD

[es(tag=gameClient)]
def camera_shaker_perlin_punch_by_dir(evt : CmdCameraPunchByDir;
                                      camera__active : bool;
                                      camera_shaker__punchByDirMaxAngles : float3;
                                      camera_shaker__punchMaxPower : float;
                                      camera_shaker__punchDirLength : float;
                                      var camera_shaker__punch : float&;
                                      var camera_shaker__punchAngles : float3&)
  if !camera__active || camera_shaker__punch > 0.05f
    return

  let dir = evt.localDir
  let power = cvt(length(evt.localDir), 0.f, camera_shaker__punchDirLength, 0.f, camera_shaker__punchMaxPower)

  let maxPitch = camera_shaker__punchByDirMaxAngles.x * power
  let maxYaw = camera_shaker__punchByDirMaxAngles.y * power
  let maxRoll = camera_shaker__punchByDirMaxAngles.z * power

  let roll = cvt(dir.y, -1.f, 1.f, -maxRoll, maxRoll)
  if abs(dir.x) >= abs(dir.z)
    camera_shaker__punchAngles = float3(-sign(dir.x) * maxPitch, 0.f, -sign(dir.z) * roll)
  else
    camera_shaker__punchAngles = float3(0.f, sign(dir.z) * maxYaw, sign(dir.z) * roll)

  camera_shaker__punch = 1.f
  camera_shaker__punchAngles *= DEG_TO_RAD

[es(tag=gameClient, after=shooter_cam_update_tm_es, before=after_camera_sync)]
def camera_shaker_perlin_update_es(info : UpdateStageInfoAct;
                                   camera_shaker__maxShake : float3;
                                   camera_shaker__traumaFadeoutSpeed : float;
                                   camera_shaker__shakePower : float;
                                   camera_shaker__punchSpeed : float;
                                   camera_shaker__punchAngles : float3;
                                   camera_shaker__extraShakeAngles : float3;
                                   var camera_shaker__punch : float&;
                                   var camera_shaker__shake : float&;
                                   var camera_shaker__trauma : float&;
                                   var camera_shaker__totalTime : float&;
                                   var transform : float3x4)
  camera_shaker__shake = square(camera_shaker__trauma)

  let shake = camera_shaker__shake
  let maxShake = camera_shaker__maxShake * DEG_TO_RAD
  var shakerAngles = float3(maxShake.x * shake * perlin_noise1(camera_shaker__totalTime),
                            maxShake.y * shake * perlin_noise1(camera_shaker__totalTime + 1000.f),
                            maxShake.z * shake * perlin_noise1(camera_shaker__totalTime + 2000.f))

  camera_shaker__trauma = clamp(camera_shaker__trauma - camera_shaker__traumaFadeoutSpeed * info.dt, 0.f, 1.f)
  camera_shaker__totalTime += camera_shaker__shakePower * info.dt
  if camera_shaker__totalTime > 1e5
    camera_shaker__totalTime = 0.f

  shakerAngles += smoothStopArch3(1.f - camera_shaker__punch) * camera_shaker__punchAngles
  camera_shaker__punch = clamp(camera_shaker__punch - camera_shaker__punchSpeed * info.dt, 0.f, 1.f)

  shakerAngles += camera_shaker__extraShakeAngles

  var shakerTm : float3x4

  rotxTM(shakerAngles.x, shakerTm)
  transform = transform * shakerTm

  rotyTM(shakerAngles.y, shakerTm)
  transform = transform * shakerTm

  rotzTM(shakerAngles.z, shakerTm)
  transform = transform * shakerTm


[es(tag=gameClient, REQUIRE=hero, before=camera_shaker_perlin_update_es)]
def camera_shaker_perlin_swing_on_sprint(info : UpdateStageInfoAct;
                                         human_net_phys : HumanActor;
                                         human_net_phys__curMoveState : int;
                                         camera_shake__sprintSwingMaxPitch : float;
                                         camera_shake__sprintSwingMaxYaw : float;
                                         camera_shake__sprintSwingMaxRoll : float;
                                         camera_shake__sprintSwingOmega : float3;
                                         camera_shake__sprintSwingMinVelocity : float;
                                         camera_shake__sprintSwingMaxVelocity : float;
                                         camera_shake__sprintSwingTau : float;
                                         var camera_shake__sprintSwingTime : float&;
                                         var camera_shake__sprintSwingAmplitude : float&)
  query() <| $ [es] (camera__active : bool;
                     camera_settings__shakePowerMult : float;
                     var camera_shaker__extraShakeAngles : float3&)
    if !camera__active
      return

    let velocity = human_net_phys.phys.currentState.velocity
    let isInSprint = human_net_phys__curMoveState == int(HUMoveState EMS_SPRINT)

    var wishAmplitude = isInSprint ? cvt(length_sq(velocity), square(camera_shake__sprintSwingMinVelocity), square(camera_shake__sprintSwingMaxVelocity), 0.f, 1.f) : 0.f
    wishAmplitude *= camera_settings__shakePowerMult

    camera_shake__sprintSwingAmplitude = approach(camera_shake__sprintSwingAmplitude, wishAmplitude, info.dt, camera_shake__sprintSwingTau)

    if camera_shake__sprintSwingAmplitude <= 1.e-2f
      camera_shake__sprintSwingTime = 0.f
      camera_shaker__extraShakeAngles = float3(0.f, 0.f, 0.f)
      return

    let maxSwingPitch = camera_shake__sprintSwingMaxPitch * DEG_TO_RAD
    let maxSwingYaw = camera_shake__sprintSwingMaxYaw * DEG_TO_RAD
    let maxSwingRoll = camera_shake__sprintSwingMaxRoll * DEG_TO_RAD
    camera_shaker__extraShakeAngles.x = camera_shake__sprintSwingAmplitude * maxSwingPitch * sin(camera_shake__sprintSwingOmega.x * camera_shake__sprintSwingTime)
    camera_shaker__extraShakeAngles.y = camera_shake__sprintSwingAmplitude * maxSwingYaw * sin(camera_shake__sprintSwingOmega.y * camera_shake__sprintSwingTime)
    camera_shaker__extraShakeAngles.z = camera_shake__sprintSwingAmplitude * maxSwingRoll * sin(camera_shake__sprintSwingOmega.z * camera_shake__sprintSwingTime)

    camera_shake__sprintSwingTime += info.dt

[es(tag=gameClient, REQUIRE=hero)]
def camera_shaker_perlin_on_collision(evt : CmdCollisionDamage;
                                      hitpoints__maxHp : float;
                                      camera_shake__collisionDamageHpFactor : float;
                                      camera_shake__collisionDamageMaxTrauma : float)
  let trauma = cvt(evt.damage, 0.f, camera_shake__collisionDamageHpFactor * hitpoints__maxHp, 0.f, camera_shake__collisionDamageMaxTrauma)
  add_trauma(trauma, camera_shake__collisionDamageMaxTrauma)

[es(tag=gameClient, REQUIRE=hero)]
def camera_shaker_perlin_on_jump(evt : CmdPostPhysUpdate;
                                 human_net_phys : HumanActor;
                                 camera_shake__jumpMaxPunch : float;
                                 camera_shake__jumpMinSpeed : float;
                                 camera_shake__jumpMaxSpeed : float)
  let spdSummaryDiffY = human_net_phys.phys.currentState.spdSummaryDiff.y
  if spdSummaryDiffY >= camera_shake__jumpMinSpeed
    let pitchPunch = cvt(spdSummaryDiffY, camera_shake__jumpMinSpeed, camera_shake__jumpMaxSpeed, 0.f, -camera_shake__jumpMaxPunch)
    query() <| $ [es] (camera__active : bool;
                       camera_settings__shakePowerMult : float)
      if camera__active
        add_punch(float3(pitchPunch * camera_settings__shakePowerMult, 0.f, 0.f))

[es(tag=gameClient)]
def camera_shaker_perlin_vehicle_earth_tremor_es(evt : EventVehicleEarthTremor;
                                                 camera__target : EntityId;
                                                 camera_shaker__vehicleMaxDistance : float;
                                                 camera_shaker__vehicleMassMod : float;
                                                 camera_shaker__vehicleSpeedMod : float;
                                                 camera_shaker__vehicleMaxTrauma : float;
                                                 bindToVehicle : bool = false;
                                                 camera__active : bool)
  if !camera__active || bindToVehicle || get_bool(camera__target, "isInVehicle") ?? false
    return
  let massShake = evt.mass * camera_shaker__vehicleMassMod
  let speedShake = evt.speed * camera_shaker__vehicleSpeedMod
  add_trauma(massShake + speedShake, camera_shaker__vehicleMaxTrauma, evt.position, camera_shaker__vehicleMaxDistance)

[es(tag=gameClient)]
def camera_shaker_perlin_projectile_hit_es(evt : ProjectileHitShake;
                                           camera_shaker__projectileMaxDistance : float;
                                           camera_shaker__projectileHitDamageMod : float)
  let trauma = evt.damage * camera_shaker__projectileHitDamageMod
  add_trauma(trauma, 1.f, evt.position, camera_shaker__projectileMaxDistance)

[es(tag=gameClient, REQUIRE=msg_sink)]
def camera_shaker_perlin_shell_explosion_es(evt : EventShellExplosionShockWave)
  query() <| $ [es] (transform : float3x4;
                     camera__active : bool;
                     camera_shaker__waveMinPower : float;
                     camera_shaker__waveMaxPower : float;
                     camera_shaker__waveRadiusMod : float;
                     camera_shaker__waveDamageMod : float;
                     camera__target : EntityId)
    if !camera__active
      return
    let explosionPos = evt.position
    let damageRadius = evt.dmg_radius
    let damageHp = evt.dmg_hp
    let blastWaveRadius = damageRadius * camera_shaker__waveRadiusMod
    let hitDir = transform[3] - explosionPos
    let distance = length(hitDir)
    let hitDirNormalized = hitDir * safeinv(distance)
    if distance < blastWaveRadius
      let waveWeakening = cvt(distance, 0.f, blastWaveRadius, 0.f, camera_shaker__waveMaxPower - camera_shaker__waveMinPower)
      var shakePower = (camera_shaker__waveMaxPower - waveWeakening) * damageHp * camera_shaker__waveDamageMod
      query(camera__target) <| $ [es] (entity_mods__shakePowerMult : float)
        shakePower *= entity_mods__shakePowerMult
      add_trauma(shakePower)
      add_punch_by_dir(shakePower * rotate(inverse(transform), hitDirNormalized))

[es(tag=gameClient)]
def camera_shaker_perlin_projectile_fly_es(evt : ProjectileFlyShockWave;
                                           transform : float3x4&;
                                           camera__active : bool;
                                           camera_shaker__projectilePowerMod : float;
                                           camera_shaker__projectileMaxDistance : float;
                                           camera_shaker__projectileMinCaliber : float;
                                           camera_shaker__projectileFlyMaxTrauma : float)
  let caliber = evt.caliber
  if !camera__active || caliber < camera_shaker__projectileMinCaliber
    return

  let pos = evt.position
  let prevPos = evt.prev_position
  let dir = normalize(pos - prevPos)
  let closestPointOnDir = pos + dir * dot(transform[3] - pos, dir)
  let distanceSq = length_sq(transform[3] - closestPointOnDir)
  if distanceSq < square(camera_shaker__projectileMaxDistance) && dot(prevPos - closestPointOnDir, dir) <= 0.f && dot(pos - closestPointOnDir, dir) > 0.f
    let maxPower = caliber * camera_shaker__projectilePowerMod
    let shakePower = maxPower - cvt(distanceSq, 0.f, square(camera_shaker__projectileMaxDistance), 0.f, maxPower)
    add_trauma(shakePower, camera_shaker__projectileFlyMaxTrauma, evt.position, camera_shaker__projectileMaxDistance)

[es(tag=gameClient)]
def cmd_camera_shaker_perlin_es(evt : CmdShakeCamera; camera__active : bool)
  if camera__active
    add_trauma(evt.wish_shake, 1.f, evt.position, evt.max_distance)

[es(tag=gameClient, after=after_guns_update_sync, before=clear_gun_launch_events_es)]
def camara_shake_perlin_on_shooting(info : UpdateStageInfoAct;
                                    gun__owner : EntityId;
                                    gun_launch_events : GunLaunchEvents;
                                    gun__cameraShakeTrauma : float;
                                    gun__cameraShakeMaxTrauma : float)
  if has(gun__owner, "hero") && length(gun_launch_events.launchEvents) > 0
    add_trauma(gun__cameraShakeTrauma, gun__cameraShakeMaxTrauma)

[es(tag=gameClient, REQUIRE=hero)]
def camara_shake_perlin_punch_on_hit(evt : EventOnEntityHit; isAlive : bool; transform : float3x4)
  let acceptDamageType = (evt.damageType == int(DamageType DM_MELEE) ||
                          evt.damageType == int(DamageType DM_BACKSTAB) ||
                          evt.damageType == int(DamageType DM_PROJECTILE) ||
                          evt.damageType == int(DamageType DM_COLLISION))
  if has(evt.victim, "hero") && acceptDamageType && isAlive
    add_punch_by_dir(evt.deltaHp * rotate(inverse(transform), evt.hitDir))

[es(tag=gameClient)]
def camera_shake_perlin_break_window(evt : EventRiExtraDestroyed; isDoor : bool)
  if isDoor
    return
  ecs::query(evt.offenderEid) <| $ [es(REQUIRE=watchedByPlr)] (camera_shake__breakWindowTrauma : float)
    add_trauma(camera_shake__breakWindowTrauma)
