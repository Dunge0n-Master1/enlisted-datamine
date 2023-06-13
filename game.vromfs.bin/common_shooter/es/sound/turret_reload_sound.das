require ecs
require soundEvent
require math.base
require enlisted.events_enlisted
require Gun
require common_shooter.es.sound.gun_sound_common


[es(tag=sound, track=gun__reloadFinishTime)]
def gun_reload_sound_start(evt : Event;
                           turret__isBroken : bool;
                           gun__owner : EntityId;
                           gun__reloadFinishTime : float;
                           gun_reload_sound__path : string;
                           var gun_reload_sound__event : SoundEvent&)
  if gun__reloadFinishTime > 0. && !turret__isBroken && is_watched_gun_sound(gun__owner)
    release(gun_reload_sound__event.handle)
    gun_reload_sound__event |> play(gun_reload_sound__path)
    gun_reload_sound__event.enabled = true


[es(tag=sound)]
def gun_reload_sound_end(info : ParallelUpdateFrameDelayed;
                         turret__isBroken : bool;
                         gun__owner : EntityId;
                         gun__reloadFinishTime : float;
                         gun__reloadTime : float = 0.;
                         gun_reload_sound__readyPath : string;
                         gun_reload_sound__duration : float = 2.;
                         var gun_reload_sound__event : SoundEvent&)
  if !turret__isBroken && gun__reloadFinishTime > 0. && is_watched_gun_sound(gun__owner)
    let reloadSoundStartTime = gun__reloadFinishTime - saturate(min(gun_reload_sound__duration, gun__reloadTime * 0.5))
    if info.curTime < reloadSoundStartTime && info.curTime + info.dt >= reloadSoundStartTime
      release(gun_reload_sound__event.handle)
      gun_reload_sound__event.enabled = false
      oneshot(gun_reload_sound__readyPath)
  elif gun_reload_sound__event.enabled
    release(gun_reload_sound__event.handle)
    gun_reload_sound__event.enabled = false


[es(tag=sound)]
def gun_ready_to_shoot_sound(info : ParallelUpdateFrameDelayed;
                             gun : Gun;
                             gun__owner : EntityId;
                             gun__timeBetweenShots : float;
                             gun_ready_to_shoot_sound__duration : float;
                             gun_ready_to_shoot_sound__minTimeBetweenShots : float;
                             gun_ready_to_shoot_sound__path : string)
  if info.curTime + gun_ready_to_shoot_sound__duration >= gun.curState.nextShotAtTime && info.curTime + gun_ready_to_shoot_sound__duration - info.dt < gun.curState.nextShotAtTime && gun.curState.nextShotAtTime > 0.
    if gun__timeBetweenShots >= gun_ready_to_shoot_sound__minTimeBetweenShots
      if is_watched_gun_sound(gun__owner)
        oneshot(gun_ready_to_shoot_sound__path)
