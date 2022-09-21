require ecs
require app
require soundEvent
require soundSystem
require soundProps
require common_shooter.events_common_shooter
require sound_utils.modules.sound_physmat_common
require EnlistedDm
require Dacoll
require DagorRandom
require math.base
require BallisticsProps


[es(tag=sound, REQUIRE=msg_sink)]
def shell_shatters_sound(evt : EventOnShellExploded)
  let shellSoundProps = shell_sound_try_get_props(int(evt.shellId))
  if shellSoundProps == null
    return
  assume props = *shellSoundProps

  let maxRadius = get_shell_max_radius(int(evt.shellId), int(evt.damageId), int(evt.ballisticsId))
  let minMaxRayLen = props.shattersMinMaxRayLenMul * maxRadius
  if length_sq(get_listener_pos() - evt.explPos) >= square(props.shattersSampleRangeAroundListener + minMaxRayLen.y)
    return

  projectile_get_props(int(evt.shellId)) <| $(projectileProps : ProjectileProps)
    let caliberVar = projectileProps.caliber
    var count = rnd_int(props.shattersMinMaxCount.x, props.shattersMinMaxCount.y)
    if count <= 0
      return

    let needCooldown = find_query() <| $ [es] (var shell_shatters_sounds__nextTime : float&; shell_shatters_sounds__cooldown : float)
      let res = get_sync_time() < shell_shatters_sounds__nextTime
      shell_shatters_sounds__nextTime = get_sync_time() + shell_shatters_sounds__cooldown
      return res
    if needCooldown
      return

    while --count >= 0
      let ptAroundListener = get_listener_pos() + float3(rnd_float(-1., 1.), rnd_float(-1., 1.), rnd_float(-1., 1.)) * props.shattersSampleRangeAroundListener
      let traceDir = normalize(ptAroundListener - evt.explPos)
      let traceStart = evt.explPos + traceDir * minMaxRayLen.x
      var norm : float3
      var pmid = -1
      var riDesc = RendInstDesc()
      var distance = minMaxRayLen.y - minMaxRayLen.x
      if traceray_normalized(traceStart, traceDir, distance, pmid, norm, ETF_LMESH | ETF_HEIGHTMAP | ETF_FRT | ETF_RI | ETF_STRUCTURES, riDesc, -1)
        var soundHandle = soundEvent::play(props.shattersHitPath, traceStart + traceDir * distance) // shatter surface hit sound
        set_var(soundHandle, "cal", caliberVar)
        set_var(soundHandle, "mat", get_projectile_sound_material_id(pmid))
        abandon(soundHandle)
      let t = dot(get_listener_pos() - traceStart, traceDir)
      if t > 0. && t < distance
        var soundHandle = soundEvent::play(props.shattersWizPath, traceStart + traceDir * t) // shatter wiz fly sound
        set_var(soundHandle, "cal", caliberVar)
        abandon(soundHandle)
