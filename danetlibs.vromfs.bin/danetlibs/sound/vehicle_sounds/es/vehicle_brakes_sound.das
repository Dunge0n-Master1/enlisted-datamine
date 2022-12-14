require ecs
require math.base
require DagorMath
require vehicle
require soundEvent
require soundHash
require sound_utils.modules.sound_player_common
require sound_utils_net.modules.sound_utils_net_events


[es(tag=sound, after=vehicle_sound_update_vars)]
def vehicle_brakes_sound(info : ParallelUpdateFrameDelayed;
                         sound_control__shouldPlay : bool;
                         vehicle_net_phys : VehiclePhysActor;
                         vehicle_sound_vars__isOnGround : bool;
                         var vehicle_brakes_sound__brakes : float&;
                         vehicle_brakes_sound__brakesStart : float;
                         vehicle_brakes_sound__speedFadeInOut : float2;
                         var sound_event_group : SoundEventGroup&;
                         is_watched_sound : bool;
                         [[shared_comp]] vehicle_brakes_sound__path : Object;
                         sound_tags : Object;
                         transform : float3x4)

  assume currentState = vehicle_net_phys.phys.currentState
  let speed = abs(dot(float3(currentState.velocity), transform[0]))
  let speedFadeIn = cvt(speed, 0., vehicle_brakes_sound__speedFadeInOut.x, 0., 1.)
  let speedFadeOut = cvt(speed, vehicle_brakes_sound__speedFadeInOut.x, vehicle_brakes_sound__speedFadeInOut.y, 1., 0.)

  let brakes = vehicle_sound_vars__isOnGround ? saturate(max(abs(currentState.leftSteeringBrake), abs(currentState.rightSteeringBrake))) : 0.
  vehicle_brakes_sound__brakes = max(max(vehicle_brakes_sound__brakes - info.dt, 0.), brakes * speedFadeOut * speedFadeIn)

  if vehicle_brakes_sound__brakes > vehicle_brakes_sound__brakesStart && sound_control__shouldPlay && is_watched_sound
    if !is_playing(get_sound(sound_event_group, sound_hash("brakes")))
      sound_player_common::play_path(vehicle_brakes_sound__path, sound_tags, is_watched_sound, transform[3], sound_hash("brakes"), sound_event_group)
    let handle = get_sound(sound_event_group, sound_hash("brakes"))
    set_var(handle, "brakes", vehicle_brakes_sound__brakes)
  else
    reject_sound(sound_event_group, sound_hash("brakes"))
