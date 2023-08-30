require ecs
require app
require math
require math.base
require soundEvent
require soundSystem
require Dacoll
require DngCamera


[es(tag=sound, on_event=ParallelUpdateFrameDelayed)]
def spline_sound_update(evt : Event;
                        sound_banks_state__isPresetLoaded : bool;
                        var spline_sound__event : SoundEvent&;
                        spline_sound__path : string;
                        spline_sound__points : Point4List;
                        var spline_sound__pointId : int&;
                        var spline_sound__pos : float3&;
                        var spline_sound__eventPos : float3&;
                        var spline_sound__radius : float&;
                        var spline_sound__isInside : bool&;
                        spline_sound__range : float;
                        spline_sound__floorOnWater : bool)
  if !sound_banks_state__isPresetLoaded || length(spline_sound__points) < 2
    return

  let listener = (get_cur_cam_entity() |> get_TMatrix("transform") ?? IDENT_TM)[3]
  let numPointsToUpdate = clamp(length(spline_sound__points) / 8, 1, 16)
  let nextPoint = min(spline_sound__pointId + numPointsToUpdate, length(spline_sound__points) - 1)

  while spline_sound__pointId < nextPoint
    let p0 = spline_sound__points[spline_sound__pointId]
    let p1 = spline_sound__points[spline_sound__pointId + 1]
    if p1.w < 0. // next spline
      spline_sound__pointId += 2
      continue
    let start = p0.xyz
    let end = p1.xyz
    let dir = end - start
    var t = 0.
    let c1 = dot(listener - start, dir)
    if c1 > FLT_EPSILON
      let c2 = dot(dir, dir)
      t = c1 + FLT_EPSILON < c2 ? c1 / c2 : 1.
    let p = start + dir * t
    if spline_sound__pointId == 0 || length_sq(p - listener) < length_sq(spline_sound__pos - listener)
      spline_sound__pos = p
      spline_sound__radius = lerp(p0.w, p1.w, t)
    ++spline_sound__pointId

  if spline_sound__pointId + 1 >= length(spline_sound__points)
    spline_sound__pointId = 0
    spline_sound__isInside = false
    spline_sound__eventPos = spline_sound__pos

    if spline_sound__radius > 0.
      if spline_sound__floorOnWater
        let diff = listener.xz - spline_sound__eventPos.xz
        spline_sound__isInside = length_sq(diff) < square(spline_sound__radius)
        if spline_sound__isInside
          spline_sound__eventPos = listener
          traceht_water(spline_sound__eventPos, spline_sound__eventPos.y)
        else
          traceht_water(spline_sound__eventPos, spline_sound__eventPos.y)
          let offset = normalize(diff) * spline_sound__radius
          spline_sound__eventPos.x += offset.x
          spline_sound__eventPos.z += offset.y
      else
        spline_sound__isInside = length_sq(listener - spline_sound__eventPos) < square(spline_sound__radius)
        if spline_sound__isInside
          spline_sound__eventPos = listener
        else
          spline_sound__eventPos += normalize(listener - spline_sound__eventPos) * spline_sound__radius

    let inRange = (spline_sound__event.enabled ? (distance_sq(spline_sound__eventPos, listener) < square(spline_sound__range)) :
                                                 (distance_sq(spline_sound__eventPos, listener) < square(spline_sound__range * 0.9)))

    if spline_sound__event.enabled != inRange
      spline_sound__event.enabled = inRange
      release_immediate(spline_sound__event.handle)
      if spline_sound__event.enabled
        spline_sound__event |> play(spline_sound__path, spline_sound__eventPos)

    if spline_sound__event.enabled && !spline_sound__isInside
      set_pos(spline_sound__event.handle, spline_sound__eventPos)


// NOT ParallelUpdateFrameDelayed because should accurate bring event to camera(important)
// (AFTER camera tm update && fmod listener setup) and (BEFORE fmod::update)
[es(tag=sound, after=sound_listener_update_es)]
def spline_sound_update_event_pos(info : UpdateStageInfoAct;
                                  spline_sound__isInside : bool;
                                  spline_sound__event : SoundEvent;
                                  spline_sound__eventPos : float3;
                                  spline_sound__floorOnWater : bool)
  if spline_sound__isInside && spline_sound__event.enabled
    let listener = get_listener_pos()
    if spline_sound__floorOnWater
      let pos = float3(listener.x, spline_sound__eventPos.y, listener.z)
      set_pos(spline_sound__event.handle, pos)
    else
      set_pos(spline_sound__event.handle, listener)


[es(tag=sound, track=sound_banks_state__isPresetLoaded, REQUIRE=sound_banks_state__isPresetLoaded)]
def spline_sound_toggle(evt : Event;
                        var spline_sound__event : SoundEvent&;
                        var spline_sound__pointId : int&;
                        var spline_sound__range : float&;
                        spline_sound__path : string)
  release_immediate(spline_sound__event.handle)
  spline_sound__event.enabled = false
  spline_sound__pointId = 0
  spline_sound__range = get_max_distance(spline_sound__path)
