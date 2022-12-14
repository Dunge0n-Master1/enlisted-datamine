require ecs
require DagorMath
require math.base
require soundEvent
require soundSystem
require soundProps
require sound_utils.modules.sound_player_common
require PhysMat
require sound_utils_net.modules.sound_utils_net_events


[es(tag=sound, track=is_watched_sound, REQUIRE=is_watched_sound)]
def vehicle_tracks_sound_reset(evt : Event;
                               var vehicle_tracks_sound__event : SoundEvent&;
                               var vehicle_tracks_sound__timer : float&)
  vehicle_tracks_sound__timer = 0.
  vehicle_tracks_sound__event.enabled = false
  abandon(vehicle_tracks_sound__event.handle)


[es(tag=sound, after=(vehicle_sound_update_vars, vehicle_suspension_sound, vehicle_suspension_sound_update_surface, ship_sound_update_vars))]
def vehicle_tracks_sound(info : ParallelUpdateFrameDelayed;
                         sound_control__shouldPlay : bool;

                         var vehicle_tracks_sound__event : SoundEvent&;
                         var vehicle_tracks_sound__timer : float&;
                         vehicle_tracks_sound__speedThreshold : float;
                         vehicle_tracks_sound__speedMul : float;
                         vehicle_tracks_sound__speedToTurnMul : float4;
                         vehicle_tracks_sound__surfaceWaterToVar : float = 10.;
                         vehicle_tracks_sound__surfaceConcreteToVar : float = 1.;

                         vehicle_sound_vars__speed : float;
                         vehicle_sound_vars__noiseReduction : float;
                         vehicle_sound_vars__slip : float;
                         vehicle_sound_vars__water : float;
                         vehicle_sound_vars__concrete : float;

                         is_watched_sound : bool;

                         [[shared_comp]] vehicle_tracks_sound__path : Object;
                         sound_tags : Object;

                         transform : float3x4)

  if !sound_control__shouldPlay
    if vehicle_tracks_sound__event.enabled
      vehicle_tracks_sound__timer = -1.
      vehicle_tracks_sound__event.enabled = false
      abandon(vehicle_tracks_sound__event.handle)
    return

  vehicle_tracks_sound__timer += info.dt
  if vehicle_tracks_sound__timer < 0.
    return

  let speed = vehicle_sound_vars__speed * vehicle_tracks_sound__speedMul * vehicle_sound_vars__noiseReduction
  if speed >= vehicle_tracks_sound__speedThreshold
    vehicle_tracks_sound__timer = 0.
    if !vehicle_tracks_sound__event.enabled
      vehicle_tracks_sound__event.enabled = true
      abandon(vehicle_tracks_sound__event.handle)
      vehicle_tracks_sound__event.handle = sound_player_common::play_path(vehicle_tracks_sound__path, sound_tags, is_watched_sound, transform[3], false)
  elif vehicle_tracks_sound__timer >= 1.
    vehicle_tracks_sound__timer = -1.
    if vehicle_tracks_sound__event.enabled
      vehicle_tracks_sound__event.enabled = false
      abandon(vehicle_tracks_sound__event.handle)

  if vehicle_tracks_sound__event.enabled
    set_var(vehicle_tracks_sound__event.handle, "speed", speed)
    let surfaceWater = vehicle_sound_vars__water * vehicle_tracks_sound__surfaceWaterToVar
    let turn = vehicle_sound_vars__slip * cvt(vehicle_sound_vars__speed * vehicle_tracks_sound__speedMul,
                                              vehicle_tracks_sound__speedToTurnMul.x, vehicle_tracks_sound__speedToTurnMul.y,
                                              vehicle_tracks_sound__speedToTurnMul.z, vehicle_tracks_sound__speedToTurnMul.w)
    set_var(vehicle_tracks_sound__event.handle, "turn", saturate(1. - surfaceWater) * turn)
    set_var(vehicle_tracks_sound__event.handle, "surface_water", surfaceWater)
    set_var(vehicle_tracks_sound__event.handle, "surface_concrete", vehicle_sound_vars__concrete * vehicle_tracks_sound__surfaceConcreteToVar)
    set_pos(vehicle_tracks_sound__event.handle, transform[3])
