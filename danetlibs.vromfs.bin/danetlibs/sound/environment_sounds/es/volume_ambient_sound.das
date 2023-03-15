require ecs
require app
require math.base
require math
require soundEvent
require soundSystem
require soundHash
require sound_utils_net.modules.sound_utils_net_events
require environment_sounds.modules.game_object_sound_common
require DagorSystem


[es(tag=sound)]
def volume_ambient_sound_update(info : ParallelUpdateFrameDelayed;
                                sound_bank_preset_state__isValid : bool;
                                global_sound_listener_position : float3;
                                game_object_sound__shape : uint;
                                volume_ambient_sound__extent_maxRadiusSq : float4;
                                game_object_sound__path : string;
                                game_object_sound__name : string;
                                volume_ambient_sound__range : float;
                                var volume_ambient_sound__event : SoundEvent&;
                                transform : float3x4)

  if !sound_bank_preset_state__isValid
    return

  assume listener = global_sound_listener_position

  let clampedPos = place_game_object_sound(listener, volume_ambient_sound__extent_maxRadiusSq, game_object_sound__shape, transform)
  let distSq = distance_sq(listener, clampedPos)

  let isValidHandle = volume_ambient_sound__event.handle != invalid_sound_event_handle()
  let inRange = (isValidHandle ? (distSq < square(volume_ambient_sound__range)) :
                                  (distSq < square(volume_ambient_sound__range * 0.9)))

  if inRange
    if !is_playing(volume_ambient_sound__event.handle)
      release_immediate(volume_ambient_sound__event.handle)
      volume_ambient_sound__event.handle = play(game_object_sound__name, game_object_sound__path, listener)
    set_var(volume_ambient_sound__event.handle, "dist", sqrt(distSq))
    if distSq > 0.
      set_pos(volume_ambient_sound__event.handle, clampedPos)
  elif isValidHandle
    release(volume_ambient_sound__event.handle)


[es(tag=sound, after=global_sound_listener_position_update)]
def volume_ambient_sound_update_event_pos(info : UpdateStageInfoAct;
                                          global_sound_listener_position : float3;
                                          volume_ambient_sound__closestDistSq : float;
                                          volume_ambient_sound__event : SoundEvent)
  if volume_ambient_sound__closestDistSq == 0.f && volume_ambient_sound__event.handle != invalid_sound_event_handle()
    set_pos(volume_ambient_sound__event.handle, global_sound_listener_position) // accurate bring event to camera(important)


[es(tag=sound, on_appear)]
def volume_ambient_sound_appear(evt : Event;
                                game_object_sound__shape : uint;
                                var transform : float3x4&;
                                var volume_ambient_sound__extent_maxRadiusSq : float4&)
  volume_ambient_sound__extent_maxRadiusSq = float4(length(transform[0]) * 0.5, length(transform[1]) * 0.5, length(transform[2]) * 0.5, 0.)
  if game_object_sound__shape == sound_hash("sphere")
    volume_ambient_sound__extent_maxRadiusSq.x = max(max(volume_ambient_sound__extent_maxRadiusSq.x, volume_ambient_sound__extent_maxRadiusSq.y), volume_ambient_sound__extent_maxRadiusSq.z)
  elif game_object_sound__shape == sound_hash("capsule")
    volume_ambient_sound__extent_maxRadiusSq.y = max(0., volume_ambient_sound__extent_maxRadiusSq.y - volume_ambient_sound__extent_maxRadiusSq.x)
  transform[0] = normalize(transform[0])
  transform[1] = normalize(transform[1])
  transform[2] = normalize(transform[2])


[es(tag=sound, on_appear, track=sound_bank_preset_state__isValid, after=volume_ambient_sound_appear)]
def volume_ambient_sound_toggle(evt : Event;
                                sound_bank_preset_state__isValid : bool;
                                game_object_sound__path : string;
                                game_object_sound__name : string;
                                var volume_ambient_sound__range : float&;
                                volume_ambient_sound__autoRange : bool;
                                var volume_ambient_sound__event : SoundEvent&;
                                var volume_ambient_sound__extent_maxRadiusSq : float4&)
  release_immediate(volume_ambient_sound__event.handle)
  if sound_bank_preset_state__isValid && volume_ambient_sound__autoRange
    volume_ambient_sound__range = get_max_distance("{game_object_sound__path}/{game_object_sound__name}")
    volume_ambient_sound__extent_maxRadiusSq.w = square(length(volume_ambient_sound__extent_maxRadiusSq.xyz) + volume_ambient_sound__range)
