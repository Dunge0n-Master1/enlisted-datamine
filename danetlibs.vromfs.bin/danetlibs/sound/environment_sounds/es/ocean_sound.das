require ecs
require soundEvent
require soundSystem
require ecs.common


def is_border(seg : float4)
  return (int(seg.x) & 1) != 0


def find_closest_point(start_idx : int; pt : float2; ocean_sound__points : Point4List) : float2
  var closestPt = ocean_sound__points[start_idx].xy
  var idx = start_idx
  while idx < length(ocean_sound__points)
    let p = ocean_sound__points[idx]
    ++idx
    if length_sq(p) == 0.
      break
    if !is_border(p)
      let s = p.xy
      let e = p.zw
      let len = max(0.1, length(e - s))
      let dir = (e - s) / len
      let res = s + dir * clamp(dot(dir, pt - s), 0., len)
      if length_sq(res - pt) < length_sq(closestPt - pt)
        closestPt = res
  return closestPt


def is_point_inside(pt : float2; ocean_sound__points : Point4List; var closest_point_on_segment : float2&)
  var idx = 0
  var startIdx = 0
  var inside = true
  for p in ocean_sound__points
    ++idx
    if length_sq(p) == 0.
      if inside
        closest_point_on_segment = find_closest_point(startIdx, pt, ocean_sound__points)
        return true
      inside = true
      startIdx = idx
    else
      if dot(p.yz - p.wx, pt - p.xy) < 0.
        inside = false
  return false


[es(tag=sound, on_event=ParallelUpdateFrameDelayed)]
def ocean_sound_update(evt : Event;
                       sound_bank_preset_state__isValid : bool;
                       var ocean_sound__event : SoundEvent&;
                       ocean_sound__path : string;
                       ocean_sound__points : Point4List;
                       ocean_sound__waterLevel : float)
  if !sound_bank_preset_state__isValid
    return
  if !ocean_sound__event.enabled
    ocean_sound__event.enabled = true
    ocean_sound__event |> play(ocean_sound__path)

  let listener = get_listener_pos()
  var closestPointOnSegment : float2
  if is_point_inside(listener.xz, ocean_sound__points, closestPointOnSegment)
    let pos = float3(closestPointOnSegment.x, ocean_sound__waterLevel, closestPointOnSegment.y)
    set_pos(ocean_sound__event.handle, pos)
  else
    let pos = float3(listener.x, ocean_sound__waterLevel, listener.z)
    set_pos(ocean_sound__event.handle, pos)


[es(tag=sound, track=sound_bank_preset_state__isValid, REQUIRE=sound_bank_preset_state__isValid)]
def ocean_sound_toggle(evt : Event;
                       var ocean_sound__event : SoundEvent&)
  release_immediate(ocean_sound__event.handle)
  ocean_sound__event.enabled = false
