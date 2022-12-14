require ecs
require app
require math
require DagorTime
require soundEvent
require soundSystem

def get_stage()
  let hms = get_local_time()
  return (hms.x * 60 + hms.y) / 15


[es(tag=sound, on_event=ParallelUpdateFrameDelayed)]
def clock_chime_ringer(evt : Event;
                       var clock_chime_ringer__stage : int&)

  let stage = get_stage()
  if clock_chime_ringer__stage == stage
    return
  if clock_chime_ringer__stage == -1
    clock_chime_ringer__stage = stage
    return
  clock_chime_ringer__stage = stage

  ecs::query() <| $ [es] (var clock_chime__event : SoundEvent&;
                          clock_chime__ringSound : string;
                          clock_chime__localOffset : float3;
                          clock_chime__range = 30.;
                          transform : float3x4)
    abandon(clock_chime__event.handle)
    if length_sq(get_listener_pos() - transform * clock_chime__localOffset) < clock_chime__range * clock_chime__range
      clock_chime__event |> play(clock_chime__ringSound, transform * clock_chime__localOffset)
