require ecs
require app
require math.base
require DagorMath
require DagorDebug3D
require soundEvent
require soundSystem

[es(no_order, tag=(render, sound), REQUIRE=soundDebugDrawEnable)]
def river_sound_debug_draw(info : UpdateStageInfoRenderDebug;
                           river_sound__points : Point3List;
                           transform : float3x4)
  for pt in river_sound__points
    draw_debug_sphere_buffered(transform * float3(pt.x, 0., pt.y), pt.z, E3DCOLOR(0xffffffff), 24, 1)
  var idx = 0
  while idx + 1 < length(river_sound__points)
    let p0 = river_sound__points[idx]
    let p1 = river_sound__points[idx + 1]
    if p1.z == 0.
      idx += 2
      continue
    let a = float3(p0.x, 0., p0.y)
    let b = float3(p1.x, 0., p1.y)
    let tan = normalize(float3(b.z - a.z, 0., a.x - b.x))
    draw_debug_line_buffered(transform * (a + tan * p0.z), transform * (b + tan * p1.z), E3DCOLOR(0xffffffff), 2)
    draw_debug_line_buffered(transform * (a - tan * p0.z), transform * (b - tan * p1.z), E3DCOLOR(0xffffffff), 2)
    ++idx


[es(tag=sound, no_order)]
def river_sound_update(info : UpdateStageInfoAct;
                       sound_bank_preset_state__isValid : bool;
                       var river_sound__event : SoundEvent&;
                       var river_sound__wasStarted : bool&;
                       river_sound__path : string;
                       river_sound__points : Point3List;
                       var river_sound__pointId : int&;
                       var river_sound__pos : float2&;
                       var river_sound__radius : float&;
                       transform : float3x4)
  if !sound_bank_preset_state__isValid || length(river_sound__points) < 2
    return
  if !river_sound__wasStarted
    river_sound__wasStarted = true
    river_sound__event |> play(river_sound__path)
    river_sound__pointId = 0

  let cam = inverse(transform) * soundSystem::get_listener_pos()
  let listener = float2(cam.x, cam.z)
  let numPointsToUpdate = max(1, length(river_sound__points) / 8)
  let nextPoint = min(river_sound__pointId + numPointsToUpdate, length(river_sound__points) - 1)

  while river_sound__pointId < nextPoint
    let p0 = river_sound__points[river_sound__pointId]
    let p1 = river_sound__points[river_sound__pointId + 1]
    if p1.z == 0.
      river_sound__pointId += 2
      continue
    let start = float2(p0.x, p0.y)
    let end = float2(p1.x, p1.y)
    let dir = end - start
    var t = 0.
    let c1 = dot(listener - start, dir)
    if c1 > FLT_EPSILON
      let c2 = dot(dir, dir)
      t = c1 + FLT_EPSILON < c2 ? c1 / c2 : 1.
    let p = start + dir * t
    if river_sound__pointId == 0 || length_sq(p - listener) < length_sq(river_sound__pos - listener)
      river_sound__pos = p
      river_sound__radius = lerp(p0.z, p1.z, t)
    ++river_sound__pointId

  if river_sound__pointId + 1 >= length(river_sound__points)
    river_sound__pointId = 0
    let d = length_sq(listener - river_sound__pos)
    if d > square(river_sound__radius)
      river_sound__pos += normalize(listener - river_sound__pos) * river_sound__radius
    else
      river_sound__pos = listener
    set_pos(river_sound__event.handle, transform * float3(river_sound__pos.x, 0., river_sound__pos.y))


[es(tag=sound, track=sound_bank_preset_state__isValid, REQUIRE=sound_bank_preset_state__isValid, on_event=EventComponentChanged)]
def river_sound_toggle(evt : Event;
                       var river_sound__event : SoundEvent&;
                       var river_sound__wasStarted : bool&)
  release_immediate(river_sound__event.handle)
  river_sound__wasStarted = false
