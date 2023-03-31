require ecs
require enlisted.events_enlisted
require DaWeapons
require sound_utils.modules.sound_player_common
require soundEvent
require DagorMath


[es(tag=sound, track=is_watched_sound)]
def rotating_turrets_sound_toggle(evt : Event;
                                  var rotating_turrets_sound__event : SoundEvent&;
                                  is_watched_sound : bool)
  if !is_watched_sound
    abandon(rotating_turrets_sound__event.handle)
    rotating_turrets_sound__event.enabled = false


[es(tag=sound, on_event=ParallelUpdateFrameDelayed)]
def rotating_turrets_sound_update(evt : Event;
                                  [[shared_comp]] rotating_turrets_sound__path : Object;
                                  var rotating_turrets_sound__event : SoundEvent&;
                                  rotating_turrets_sound__omegaLoThreshold : float;
                                  var rotating_turrets_sound__omega : float&;
                                  turret_control__gunEids : EidList;
                                  is_watched_sound : bool;
                                  sound_tags : Object;
                                  transform : float3x4)

  var omega = 0.
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es] (rotate_turret__curOmega, rotate_turret__omegaMax : float)
      omega = max(omega, safediv(rotate_turret__curOmega, rotate_turret__omegaMax))

  let acc = omega - rotating_turrets_sound__omega
  rotating_turrets_sound__omega = omega
  let threshold = acc >= 0. ? 0. : rotating_turrets_sound__omegaLoThreshold
  let shouldPlay = omega > threshold
  if rotating_turrets_sound__event.enabled != shouldPlay
    rotating_turrets_sound__event.enabled = shouldPlay
    if shouldPlay
      abandon(rotating_turrets_sound__event.handle)
      rotating_turrets_sound__event.handle = sound_player_common::play_path(rotating_turrets_sound__path, sound_tags, is_watched_sound, transform[3], false)
    else
      keyoff(rotating_turrets_sound__event.handle)

  if rotating_turrets_sound__event.handle != invalid_sound_event_handle()
    if is_playing(rotating_turrets_sound__event.handle)
      set_var(rotating_turrets_sound__event.handle, "omega", omega)
      set_pos(rotating_turrets_sound__event.handle, transform[3])
    else
      release(rotating_turrets_sound__event.handle)
