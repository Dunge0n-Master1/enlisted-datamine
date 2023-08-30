require ecs
require soundEvent
require soundSystem
require ecs.common
require DagorMath

/*
// first spline, linestrip
p:p3=40,10,0 // segment start: p.x, p.z, segment length (computed on init)
p:p3=50,20,0
// ...
p:p3=40,10,0 // same as first point in spline
// next spline
// ...
*/



def update(pt : float2;
           ocean_sound__points : Point3List;

           var ocean_sound__idx : int&;
           var ocean_sound__firstIdx : int&;
           var ocean_sound__numIntersections : int&;
           var ocean_sound__isSplineInited : bool&;
           var ocean_sound__splinePt : float2&;

           var ocean_sound__shorePt : float2&;
           var ocean_sound__closestShorePt : float2&;
           var ocean_sound__isShoreInited : bool&;

           var ocean_sound__eventPos : float2&;
           var ocean_sound__isInside : bool&)

  if ocean_sound__idx < 0 // restart
    ocean_sound__idx = 0
    ocean_sound__firstIdx = 0
    ocean_sound__numIntersections = 0
    ocean_sound__isSplineInited = false
    ocean_sound__isShoreInited = false

  let numPoints = length(ocean_sound__points)
  let maxLookupPoints = clamp(numPoints / 8, 8, 32)

  for _n in range(maxLookupPoints)

    if ++ocean_sound__idx >= numPoints
      ocean_sound__isInside = (ocean_sound__numIntersections & 1) != 0
      ocean_sound__eventPos = ocean_sound__splinePt
      ocean_sound__closestShorePt = ocean_sound__shorePt
      ocean_sound__idx = -1 // finish
      return

    let a = ocean_sound__points[ocean_sound__idx - 1]
    let b = ocean_sound__points[ocean_sound__idx]

    let p0 = a.xy
    let p1 = b.xy

    let len = a.z
    if len > 0.1
      let dir = (p1 - p0) / len
      let res = p0 + dir * clamp(dot(dir, pt - p0), 0., len)
      if !ocean_sound__isSplineInited || length_sq(res - pt) < length_sq(ocean_sound__splinePt - pt)
        ocean_sound__splinePt = res
      ocean_sound__isSplineInited = true

      if !ocean_sound__isShoreInited || length_sq(res - pt) < length_sq(ocean_sound__shorePt - pt)
        ocean_sound__shorePt = res
      ocean_sound__isShoreInited = true

    if a.y < b.y
      if pt.y >= a.y && pt.y < b.y
        if cvt(pt.y, a.y, b.y, a.x, b.x) > pt.x
          ++ocean_sound__numIntersections
    elif a.y > b.y
      if pt.y >= b.y && pt.y < a.y
        if cvt(pt.y, b.y, a.y, b.x, a.x) > pt.x
          ++ocean_sound__numIntersections

    if b.xy == ocean_sound__points[ocean_sound__firstIdx].xy
      // end of spline
      if (ocean_sound__numIntersections & 1) != 0
        ocean_sound__isInside = true
        ocean_sound__eventPos = ocean_sound__splinePt
        ocean_sound__closestShorePt = ocean_sound__shorePt
        ocean_sound__idx = -1 // finish
        return

      // next spline
      ocean_sound__numIntersections = 0
      ocean_sound__firstIdx = ++ocean_sound__idx
      ocean_sound__isSplineInited = false



[es(tag=sound, on_event=ParallelUpdateFrameDelayed)]
def ocean_sound_update(evt : Event;
                       sound_banks_state__isPresetLoaded : bool;
                       var ocean_sound__event : SoundEvent&;
                       ocean_sound__path : string;
                       ocean_sound__points : Point3List;
                       ocean_sound__waterLevel : float;
                       ocean_sound__shoreDistanceToVar : float4;

                       var ocean_sound__idx : int&;
                       var ocean_sound__firstIdx : int&;
                       var ocean_sound__numIntersections : int&;
                       var ocean_sound__isSplineInited : bool&;
                       var ocean_sound__splinePt : float2&;

                       var ocean_sound__shorePt : float2&;
                       var ocean_sound__closestShorePt : float2&;
                       var ocean_sound__isShoreInited : bool&;

                       var ocean_sound__eventPos : float2&;
                       var ocean_sound__isInside : bool&)

  if !sound_banks_state__isPresetLoaded
    return
  if !ocean_sound__event.enabled
    ocean_sound__event.enabled = true
    ocean_sound__event |> play(ocean_sound__path)

  let listener = get_listener_pos().xz
  update(listener, ocean_sound__points, ocean_sound__idx, ocean_sound__firstIdx, ocean_sound__numIntersections, ocean_sound__isSplineInited, ocean_sound__splinePt, ocean_sound__shorePt, ocean_sound__closestShorePt, ocean_sound__isShoreInited, ocean_sound__eventPos, ocean_sound__isInside)

  if ocean_sound__isInside
    set_pos(ocean_sound__event.handle, float3(ocean_sound__eventPos.x, ocean_sound__waterLevel, ocean_sound__eventPos.y))
    set_var(ocean_sound__event.handle, "shore", 1.)
  else
    set_pos(ocean_sound__event.handle, float3(listener.x, ocean_sound__waterLevel, listener.y))
    set_var(ocean_sound__event.handle, "shore", cvt(distance(listener, ocean_sound__closestShorePt), ocean_sound__shoreDistanceToVar.x, ocean_sound__shoreDistanceToVar.y, ocean_sound__shoreDistanceToVar.z, ocean_sound__shoreDistanceToVar.w))


[es(tag=sound, track=sound_banks_state__isPresetLoaded, REQUIRE=sound_banks_state__isPresetLoaded)]
def ocean_sound_toggle(evt : Event;
                       var ocean_sound__event : SoundEvent&)
  release_immediate(ocean_sound__event.handle)
  ocean_sound__event.enabled = false


[es(tag=sound, on_appear)]
def ocean_sound_appear(evt : Event;
                       var ocean_sound__points : Point3List&)
  var idx = 0
  let numPoints = length(ocean_sound__points)
  while ++idx < numPoints
    ocean_sound__points[idx - 1].z = distance(ocean_sound__points[idx - 1], ocean_sound__points[idx])
