require ecs
require soundEvent
require math.base
require enlisted.events_enlisted


[es(tag=sound, track=gun__reloadFinishTime)]
def gun_reload_sound_start(evt : Event;
                           turret__isBroken : bool;
                           gun__reloadFinishTime : float;
                           gun_reload_sound__path : string;
                           gun_sound__isWatched : bool;
                           var gun_reload_sound__event : SoundEvent&)
  if gun__reloadFinishTime > 0. && !turret__isBroken && gun_sound__isWatched
    release(gun_reload_sound__event.handle)
    gun_reload_sound__event |> play(gun_reload_sound__path)
    gun_reload_sound__event.enabled = true


[es(tag=sound, no_order)]
def gun_reload_sound_end(info : ParallelUpdateFrameDelayed;
                         turret__isBroken : bool;
                         gun__reloadFinishTime : float;
                         gun_reload_sound__readyPath : string;
                         gun__reloadTime : float = 0.;
                         gun_reload_sound__duration : float = 2.;
                         gun_sound__isWatched : bool;
                         var gun_reload_sound__event : SoundEvent&)
  if !turret__isBroken && gun_sound__isWatched && gun__reloadFinishTime > 0.
    let reloadSoundStartTime = gun__reloadFinishTime - saturate(min(gun_reload_sound__duration, gun__reloadTime * 0.5))
    if info.curTime < reloadSoundStartTime && info.curTime + info.dt >= reloadSoundStartTime
      release(gun_reload_sound__event.handle)
      gun_reload_sound__event.enabled = false
      oneshot(gun_reload_sound__readyPath)
  elif gun_reload_sound__event.enabled
    release(gun_reload_sound__event.handle)
    gun_reload_sound__event.enabled = false
