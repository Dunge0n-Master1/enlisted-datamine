require ecs
require app
require math.base
require soundEvent
require soundSystem
require Dacoll


[es(tag=sound, on_event=ParallelUpdateFrameDelayed)]
def river_sound_update(evt : Event;
                       sound_bank_preset_state__isValid : bool;
                       var river_sound__event : SoundEvent&;
                       var river_sound__wasStarted : bool&;
                       river_sound__path : string;
                       river_sound__points : Point3List;
                       var river_sound__pointId : int&;
                       var river_sound__pos : float3&;
                       var river_sound__radius : float&)
  if !sound_bank_preset_state__isValid || length(river_sound__points) < 2
    return
  if !river_sound__wasStarted
    river_sound__wasStarted = true
    river_sound__event |> play(river_sound__path)
    river_sound__pointId = 0

  let listenerXZ = get_listener_pos().xz
  let numPointsToUpdate = clamp(length(river_sound__points) / 8, 1, 16)
  let nextPoint = min(river_sound__pointId + numPointsToUpdate, length(river_sound__points) - 1)

  while river_sound__pointId < nextPoint
    let p0 = river_sound__points[river_sound__pointId]
    let p1 = river_sound__points[river_sound__pointId + 1]
    if p1.z == 0.
      river_sound__pointId += 2
      continue
    let start = p0.xy
    let end = p1.xy
    let dir = end - start
    var t = 0.
    let c1 = dot(listenerXZ - start, dir)
    if c1 > FLT_EPSILON
      let c2 = dot(dir, dir)
      t = c1 + FLT_EPSILON < c2 ? c1 / c2 : 1.
    let p = start + dir * t
    if river_sound__pointId == 0 || length_sq(p - listenerXZ) < length_sq(river_sound__pos.xz - listenerXZ)
      river_sound__pos.x = p.x
      river_sound__pos.z = p.y
      river_sound__radius = lerp(p0.z, p1.z, t)
    ++river_sound__pointId

  if river_sound__pointId + 1 >= length(river_sound__points)
    river_sound__pointId = 0
    let d = length_sq(listenerXZ - river_sound__pos.xz)
    if d > square(river_sound__radius)
      traceht_water(river_sound__pos, river_sound__pos.y)
      let strideXZ = normalize(listenerXZ - river_sound__pos.xz) * river_sound__radius
      river_sound__pos.x += strideXZ.x
      river_sound__pos.z += strideXZ.y
    else
      river_sound__pos.x = listenerXZ.x
      river_sound__pos.z = listenerXZ.y
      traceht_water(river_sound__pos, river_sound__pos.y)
    set_pos(river_sound__event.handle, river_sound__pos)


[es(tag=sound, track=sound_bank_preset_state__isValid, REQUIRE=sound_bank_preset_state__isValid)]
def river_sound_toggle(evt : Event;
                       var river_sound__event : SoundEvent&;
                       var river_sound__wasStarted : bool&)
  release_immediate(river_sound__event.handle)
  river_sound__wasStarted = false
