require ecs
require soundEvent
require soundSystem
require enlisted.events_enlisted


let SOUND_SPEED = 335.

[es(tag=sound, no_order)]
def lightning_sound(info : ParallelUpdateFrameDelayed;
                    animchar_render__enabled : bool;
                    transform : float3x4;
                    lightning_sound__path : string;
                    lightning_sound__maxDelay : float;
                    var lightning_sound__event : SoundEvent&)
  if animchar_render__enabled != lightning_sound__event.enabled
    lightning_sound__event.enabled = animchar_render__enabled
    abandon(lightning_sound__event.handle)
    if animchar_render__enabled
      let pos = get_listener_pos()
      let dir = normalize(transform[3] - pos)
      let dist = min(length(transform[3] - pos), lightning_sound__maxDelay * SOUND_SPEED)
      lightning_sound__event |> play(lightning_sound__path, pos + dir * dist)
