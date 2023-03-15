require ecs
require app
require math.base
require math
require soundEvent
require soundSystem
require soundHash
require sound_utils_net.modules.sound_utils_net_events
require environment_sounds.modules.game_object_sound_common


[es(tag=sound)]
def compound_ambient_sound_update(info : ParallelUpdateFrameDelayed;
                                  sound_bank_preset_state__isValid : bool;
                                  global_sound_listener_position : float3;
                                  game_object_compound_sound__shapes : UInt32List;
                                  game_object_compound_sound__transforms : TMatrixList;
                                  compound_ambient_sound__extents_maxRadiusSq : Point4List;
                                  game_object_sound__path : string;
                                  game_object_sound__name : string;
                                  compound_ambient_sound__range : float;
                                  var compound_ambient_sound__curVolIdx : int&;
                                  var compound_ambient_sound__curDistSq : float&;
                                  var compound_ambient_sound__curPt : float3&;
                                  var compound_ambient_sound__closestDistSq : float&;
                                  var compound_ambient_sound__closestPt : float3&;
                                  var compound_ambient_sound__event : SoundEvent&)

  assume totalVolumes = length(game_object_compound_sound__transforms)
  if !sound_bank_preset_state__isValid || totalVolumes <= 0 || length(compound_ambient_sound__extents_maxRadiusSq) != totalVolumes
    return

  assume listener = global_sound_listener_position
  let maxSubSteps = 16
  var updateVolumes = max(1, totalVolumes / maxSubSteps)

  while --updateVolumes >= 0

    let clampedPos = place_game_object_sound(listener,
                                             compound_ambient_sound__extents_maxRadiusSq[compound_ambient_sound__curVolIdx],
                                             game_object_compound_sound__shapes[compound_ambient_sound__curVolIdx],
                                             game_object_compound_sound__transforms[compound_ambient_sound__curVolIdx])

    let distSq = distance_sq(listener, clampedPos)

    if compound_ambient_sound__curVolIdx == 0 || distSq <= compound_ambient_sound__curDistSq
      compound_ambient_sound__curDistSq = distSq
      compound_ambient_sound__curPt = clampedPos

    ++compound_ambient_sound__curVolIdx
    if compound_ambient_sound__curVolIdx >= int(totalVolumes)
      compound_ambient_sound__curVolIdx = 0
      compound_ambient_sound__closestPt = compound_ambient_sound__curPt
      compound_ambient_sound__closestDistSq = compound_ambient_sound__curDistSq

      let isValidHandle = compound_ambient_sound__event.handle != invalid_sound_event_handle()
      let inRange = (isValidHandle ? (compound_ambient_sound__closestDistSq < square(compound_ambient_sound__range)) :
                                      (compound_ambient_sound__closestDistSq < square(compound_ambient_sound__range * 0.9)))

      if inRange
        if !is_playing(compound_ambient_sound__event.handle)
          release_immediate(compound_ambient_sound__event.handle)
          compound_ambient_sound__event.handle = play(game_object_sound__name, game_object_sound__path, listener)
        set_var(compound_ambient_sound__event.handle, "dist", sqrt(compound_ambient_sound__closestDistSq))
        if compound_ambient_sound__closestDistSq > 0.
          set_pos(compound_ambient_sound__event.handle, compound_ambient_sound__closestPt)
      elif isValidHandle
        release(compound_ambient_sound__event.handle)


[es(tag=sound, after=global_sound_listener_position_update)]
def compound_ambient_sound_update_event_pos(info : UpdateStageInfoAct;
                                            global_sound_listener_position : float3;
                                            compound_ambient_sound__closestDistSq : float;
                                            compound_ambient_sound__event : SoundEvent)
  if compound_ambient_sound__closestDistSq == 0.f && compound_ambient_sound__event.handle != invalid_sound_event_handle()
    set_pos(compound_ambient_sound__event.handle, global_sound_listener_position) // accurate bring event to camera(important)


[es(tag=sound, on_appear)]
def compound_ambient_sound_appear(evt : Event;
                                  game_object_compound_sound__shapes : UInt32List;
                                  var game_object_compound_sound__transforms : TMatrixList&;
                                  var compound_ambient_sound__extents_maxRadiusSq : Point4List&)
  resize(compound_ambient_sound__extents_maxRadiusSq, length(game_object_compound_sound__transforms))
  for i in range(0, length(game_object_compound_sound__transforms))
    compound_ambient_sound__extents_maxRadiusSq[i] = float4(length(game_object_compound_sound__transforms[i][0]) * 0.5, length(game_object_compound_sound__transforms[i][1]) * 0.5, length(game_object_compound_sound__transforms[i][2]) * 0.5, 0.)
    compound_ambient_sound__extents_maxRadiusSq[i].w = max(max(compound_ambient_sound__extents_maxRadiusSq[i].x, compound_ambient_sound__extents_maxRadiusSq[i].y), compound_ambient_sound__extents_maxRadiusSq[i].z)
    if game_object_compound_sound__shapes[i] == sound_hash("sphere")
      compound_ambient_sound__extents_maxRadiusSq[i].x = max(max(compound_ambient_sound__extents_maxRadiusSq[i].x, compound_ambient_sound__extents_maxRadiusSq[i].y), compound_ambient_sound__extents_maxRadiusSq[i].z)
    elif game_object_compound_sound__shapes[i] == sound_hash("capsule")
      compound_ambient_sound__extents_maxRadiusSq[i].y = max(0., compound_ambient_sound__extents_maxRadiusSq[i].y - compound_ambient_sound__extents_maxRadiusSq[i].x)
    game_object_compound_sound__transforms[i][0] = normalize(game_object_compound_sound__transforms[i][0])
    game_object_compound_sound__transforms[i][1] = normalize(game_object_compound_sound__transforms[i][1])
    game_object_compound_sound__transforms[i][2] = normalize(game_object_compound_sound__transforms[i][2])


[es(tag=sound, on_appear, track=sound_bank_preset_state__isValid, after=compound_ambient_sound_appear)]
def compound_ambient_sound_toggle(evt : Event;
                                  sound_bank_preset_state__isValid : bool;
                                  game_object_sound__path : string;
                                  game_object_sound__name : string;
                                  var compound_ambient_sound__range : float&;
                                  compound_ambient_sound__autoRange : bool;
                                  var compound_ambient_sound__curVolIdx : int&;
                                  var compound_ambient_sound__event : SoundEvent&;
                                  var compound_ambient_sound__extents_maxRadiusSq : Point4List&)
  release_immediate(compound_ambient_sound__event.handle)
  compound_ambient_sound__curVolIdx = 0
  if sound_bank_preset_state__isValid && compound_ambient_sound__autoRange
    compound_ambient_sound__range = get_max_distance("{game_object_sound__path}/{game_object_sound__name}")
    for i in range(0, length(compound_ambient_sound__extents_maxRadiusSq))
      compound_ambient_sound__extents_maxRadiusSq[i].w = square(length(compound_ambient_sound__extents_maxRadiusSq[i].xyz) + compound_ambient_sound__range)
