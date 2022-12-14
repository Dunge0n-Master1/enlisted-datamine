require ecs
require math.base
require soundEvent
require turrets
require Gun
require enlisted.events_enlisted


def update_turret_sound(vel_h, vel_v : float; var event : SoundEvent&; path : string; pos : float3 const&)
  if event.enabled
    set_var(event.handle, "velH", vel_h * RAD_TO_DEG)
    set_var(event.handle, "velV", vel_v * RAD_TO_DEG)
    set_pos(event.handle, pos)
  elif vel_h + vel_v > 1e-4
    event.enabled = true
    event |> play(path, pos)
    set_var(event.handle, "velH", vel_h * RAD_TO_DEG)
    set_var(event.handle, "velV", vel_v * RAD_TO_DEG)


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, REQUIRE=turret_sound_group)]
def turret_sound_group_update(evt : Event;
                              is_watched_sound : bool;
                              var turret_sound__event : SoundEvent&;
                              turret_sound__path : string;
                              turret_control__gunEids : EidList;
                              transform : float3x4 const&)
  if is_watched_sound
    var velH = 0.
    var velV = 0.
    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (turret_state : TurretState& const)
        velH = max(velH, abs(turret_state.speed.x))
        velV = max(velV, abs(turret_state.speed.y))
    update_turret_sound(velH, velV, turret_sound__event, turret_sound__path, transform[3])
  elif turret_sound__event.enabled
    turret_sound__event.enabled = false
    abandon(turret_sound__event.handle)


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, REQUIRE_NOT=turret_sound_group)]
def turret_sound_update(evt : Event;
                        is_watched_sound : bool;
                        turret_control__gunEids : EidList)
  if is_watched_sound
    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (turret_state : TurretState& const;
                                                       gun : Gun& const;
                                                       var turret_sound__event : SoundEvent&;
                                                       turret_sound__path : string)
        let velH = abs(turret_state.speed.x)
        let velV = abs(turret_state.speed.y)
        update_turret_sound(velH, velV, turret_sound__event, turret_sound__path, gun.shootNodePos)


[es(tag=sound, REQUIRE_NOT=turret_sound_group, track=is_watched_sound)]
def turret_sound_disable(evt : Event;
                         is_watched_sound : bool;
                         turret_control__gunEids : EidList)
  if !is_watched_sound
    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es] (var turret_sound__event : SoundEvent&)
        abandon(turret_sound__event.handle)
        turret_sound__event.enabled = false
