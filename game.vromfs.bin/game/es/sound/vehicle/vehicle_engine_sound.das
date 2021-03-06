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


[es(tag=sound, after=(vehicle_phys_sound_state, ship_phys_sound_state))]
def vehicle_engine_sound(info : UpdateStageInfoAct;
                         sound_control__enabled : bool;
                         vehicle_sound_state__speed : float;
                         vehicle_sound_state__engineRpm : float;
                         vehicle_sound_state__engineLoad : float;
                         vehicle_sound_state__isEngineStarted : bool;
                         var vehicle_engine_sound__isInited : bool&;
                         var vehicle_engine_sound__isStartStopInited : bool&;
                         var vehicle_engine_sound__isStarted : bool&;
                         vehicle_engine_sound__shouldStart : bool;
                         vehicle_engine_sound__rpmMul = 0.25;
                         [[shared_comp]] vehicle_engine_sound__path : Object;
                         [[shared_comp]] vehicle_engine_sound__startPath : Object;
                         [[shared_comp]] vehicle_engine_sound__stopPath : Object;
                         sound_tags : Object;
                         is_watched_sound : bool;
                         var sound_event_group : SoundEventGroup&;
                         transform : float3x4)

  if sound_control__enabled
    let isStarted = vehicle_engine_sound__shouldStart && vehicle_sound_state__isEngineStarted
    if !vehicle_engine_sound__isInited || vehicle_engine_sound__isStarted != isStarted
      reject_sound(sound_event_group, sound_hash("engine"))
      if isStarted
        sound_player_common::play_path(vehicle_engine_sound__path, sound_tags, is_watched_sound, transform[3], sound_hash("engine"), sound_event_group)

    if vehicle_engine_sound__isStarted != isStarted && vehicle_engine_sound__isStartStopInited
      if isStarted
        sound_player_common::play_path(vehicle_engine_sound__startPath, sound_tags, is_watched_sound, transform[3], sound_hash("startstop"), sound_event_group)
      elif !isStarted
        sound_player_common::play_path(vehicle_engine_sound__stopPath, sound_tags, is_watched_sound, transform[3], sound_hash("startstop"), sound_event_group)

    vehicle_engine_sound__isStarted = isStarted
    vehicle_engine_sound__isInited = true
    vehicle_engine_sound__isStartStopInited = true

    if vehicle_engine_sound__isStarted
      let handle = get_sound(sound_event_group, sound_hash("engine"))
      let rpm = vehicle_sound_state__engineRpm + (100. - vehicle_sound_state__engineRpm) * vehicle_sound_state__engineLoad * vehicle_engine_sound__rpmMul
      set_var(handle, "rpm", rpm)
      set_var_optional(handle, "speed", vehicle_sound_state__speed)
      set_var(handle, "load", vehicle_sound_state__engineLoad)
      set_pos(handle, transform[3])
  elif vehicle_engine_sound__isInited // !sound_control__enabled
    vehicle_engine_sound__isInited = false
    reject_sound(sound_event_group, sound_hash("engine"))
