require ecs
require soundEvent
require soundSystem
require math.base
require DagorMath
require enlisted.events_enlisted


[es(tag=sound, no_order)]
def force_dome_sound_update(info : ParallelUpdateFrameDelayed;
                            force_dome_sound__path : string;
                            force_dome_sound__enterPath : string;
                            force_dome_sound__hearingRange : float;
                            var force_dome_sound__isInside : bool&;
                            var force_dome_sound__event : SoundEvent&)
  var depth = 1.
  var isInside = false
  ecs::query() <| $ [es] (force_dome__radius : float; force_dome__position : float3)
    let dist = length(get_listener_pos() - force_dome__position)
    depth = min(depth, cvt(dist, force_dome__radius - force_dome_sound__hearingRange, force_dome__radius, 0., 1.))
    isInside ||= dist < force_dome__radius

  if !force_dome_sound__event.enabled
    force_dome_sound__event.enabled = true
    force_dome_sound__event |> play(force_dome_sound__path)
  elif force_dome_sound__isInside != isInside
    oneshot(force_dome_sound__enterPath, get_listener_pos())
  force_dome_sound__isInside = isInside

  set_var_global("foolMoonDomeDepth", depth)

  set_pos(force_dome_sound__event.handle, get_listener_pos())
