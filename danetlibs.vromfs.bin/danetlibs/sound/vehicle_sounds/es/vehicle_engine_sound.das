require ecs
require DagorMath
require soundEvent
require soundHash
require sound_utils.modules.sound_player_common


[es(tag=sound, track=is_watched_sound, REQUIRE=is_watched_sound)]
def vehicle_engine_sound_reset(evt : Event;
                               var sound_event_group : SoundEventGroup&;
                               var vehicle_engine_sound__isInited : bool&)
  reject_sound(sound_event_group, sound_hash("engine"))
  vehicle_engine_sound__isInited = false


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=(vehicle_engine_sound_update_vars, vehicle_sound_update_vars, ship_engine_sound_update_vars, ship_sound_update_vars))]
def vehicle_engine_sound(evt : Event;
                         sound_control__shouldPlay : bool;
                         vehicle_sound_vars__speed : float;
                         vehicle_engine_sound__speedToVar : float2;
                         vehicle_engine_sound_vars__rpm : float;
                         vehicle_engine_sound_vars__load : float;
                         vehicle_engine_sound_vars__isStarted : bool;
                         var vehicle_engine_sound__isInited : bool&;
                         var vehicle_engine_sound__isStartStopInited : bool&;
                         var vehicle_engine_sound__isStarted : bool&;
                         vehicle_engine_sound__rpmMul : float;
                         [[shared_comp]] vehicle_engine_sound__path : Object;
                         [[shared_comp]] vehicle_engine_sound__startPath : Object;
                         [[shared_comp]] vehicle_engine_sound__stopPath : Object;
                         sound_tags : Object;
                         is_watched_sound : bool;
                         var sound_event_group : SoundEventGroup&;
                         transform : float3x4)

  if sound_control__shouldPlay
    let isStarted = vehicle_engine_sound_vars__isStarted
    if !vehicle_engine_sound__isInited || vehicle_engine_sound__isStarted != isStarted
      reject_sound(sound_event_group, sound_hash("engine"))
      if isStarted
        sound_player_common::play_path(vehicle_engine_sound__path, sound_tags, is_watched_sound, transform[3], sound_hash("engine"), sound_event_group)

    if vehicle_engine_sound__isStarted != isStarted && vehicle_engine_sound__isStartStopInited
      if isStarted
        sound_player_common::play_path(vehicle_engine_sound__startPath, sound_tags, is_watched_sound, transform[3], sound_hash("startstop"), sound_event_group)
      else
        sound_player_common::play_path(vehicle_engine_sound__stopPath, sound_tags, is_watched_sound, transform[3], sound_hash("startstop"), sound_event_group)

    vehicle_engine_sound__isStarted = isStarted
    vehicle_engine_sound__isInited = true
    vehicle_engine_sound__isStartStopInited = true

    if vehicle_engine_sound__isStarted
      let handle = get_sound(sound_event_group, sound_hash("engine"))
      let rpm = vehicle_engine_sound_vars__rpm + (100. - vehicle_engine_sound_vars__rpm) * vehicle_engine_sound_vars__load * vehicle_engine_sound__rpmMul
      set_var(handle, "rpm", rpm)
      set_var_optional(handle, "speed", cvt(vehicle_sound_vars__speed, vehicle_engine_sound__speedToVar.x, vehicle_engine_sound__speedToVar.y, 0., 100.))
      set_var(handle, "load", vehicle_engine_sound_vars__load)
      set_pos(handle, transform[3])
  elif vehicle_engine_sound__isInited // !sound_control__shouldPlay
    vehicle_engine_sound__isInited = false
    reject_sound(sound_event_group, sound_hash("engine"))
