require ecs
require DagorMath
require soundEvent
require enlisted.events_enlisted

[es(tag=sound, no_order)]
def bomb_site_tick_sound(info : ParallelUpdateFrameDelayed;
                         bomb_site__explosionTimeEnd : float;
                         bomb_site__timeToExplosion : float;
                         bomb_site_tick_sound__path : string;
                         var bomb_site_tick_sound__event : SoundEvent&;
                         transform : float3x4)
  if bomb_site__explosionTimeEnd > 0.
    if !bomb_site_tick_sound__event.enabled
      bomb_site_tick_sound__event.enabled = true
      bomb_site_tick_sound__event |> play(bomb_site_tick_sound__path, transform[3])
    let t = cvt(info.curTime, bomb_site__explosionTimeEnd - bomb_site__timeToExplosion, bomb_site__explosionTimeEnd, 0., 1.)
    set_var(bomb_site_tick_sound__event.handle, "explosive_timer", t)
  elif bomb_site_tick_sound__event.enabled
    bomb_site_tick_sound__event.enabled = false
    release(bomb_site_tick_sound__event.handle)
