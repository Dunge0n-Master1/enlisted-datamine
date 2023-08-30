require ecs
require app
require math.base
require math
require DagorMath
require soundEvent
require soundSystem
require soundHash
require sound_utils_net.modules.sound_utils_net_events
require environment_sounds.modules.game_object_sound_common
require DngCamera


[es(tag=sound, after=reverb_sound_update)]
def compound_ambient_sound_update(info : ParallelUpdateFrameDelayed;
                                  sound_banks_state__isPresetLoaded : bool;
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
                                  var compound_ambient_sound__event : SoundEvent&;

                                  var compound_ambient_sound__volume : float&;
                                  compound_ambient_sound__fadeInOutSpeed : float2;
                                  compound_ambient_sound__reverb_intensity_roomSize_absorption_weight : float4)

  assume totalVolumes = length(game_object_compound_sound__transforms)
  if !sound_banks_state__isPresetLoaded || totalVolumes <= 0 || length(compound_ambient_sound__extents_maxRadiusSq) != totalVolumes
    return

  let listener = (get_cur_cam_entity() |> get_TMatrix("transform") ?? IDENT_TM)[3]
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

      compound_ambient_sound__event.enabled = inRange
      if inRange && compound_ambient_sound__event.handle != invalid_sound_event_handle()
        set_var(compound_ambient_sound__event.handle, "dist", sqrt(compound_ambient_sound__closestDistSq))
        if compound_ambient_sound__closestDistSq > 0.
          set_pos(compound_ambient_sound__event.handle, compound_ambient_sound__closestPt)

  if compound_ambient_sound__event.enabled
    if !is_playing(compound_ambient_sound__event.handle)
      release_immediate(compound_ambient_sound__event.handle)
      compound_ambient_sound__event.handle = play(game_object_sound__name, game_object_sound__path, listener)
      set_var(compound_ambient_sound__event.handle, "dist", sqrt(compound_ambient_sound__closestDistSq))
      set_volume(compound_ambient_sound__event.handle, compound_ambient_sound__volume)
      if compound_ambient_sound__closestDistSq > 0.
        set_pos(compound_ambient_sound__event.handle, compound_ambient_sound__closestPt)
    if compound_ambient_sound__volume < 1.
      compound_ambient_sound__volume = min(compound_ambient_sound__volume + compound_ambient_sound__fadeInOutSpeed.x * info.dt, 1.)
      set_volume(compound_ambient_sound__event.handle, compound_ambient_sound__volume)
  else
    if compound_ambient_sound__event.handle != invalid_sound_event_handle()
      compound_ambient_sound__volume -= compound_ambient_sound__fadeInOutSpeed.y * info.dt
      if compound_ambient_sound__volume > 0.
        set_volume(compound_ambient_sound__event.handle, compound_ambient_sound__volume)
      else
        compound_ambient_sound__volume = 0.
        release_immediate(compound_ambient_sound__event.handle)
    else
      compound_ambient_sound__volume = 0.

  if compound_ambient_sound__volume > 0. && compound_ambient_sound__reverb_intensity_roomSize_absorption_weight.w > 0.
    find_query() <| $ [es] (var reverb_sound__intensity_roomSize_absorption_weight : float4&)
      reverb_sound__intensity_roomSize_absorption_weight.x = compound_ambient_sound__reverb_intensity_roomSize_absorption_weight.x
      reverb_sound__intensity_roomSize_absorption_weight.y = compound_ambient_sound__reverb_intensity_roomSize_absorption_weight.y
      reverb_sound__intensity_roomSize_absorption_weight.z = compound_ambient_sound__reverb_intensity_roomSize_absorption_weight.z
      reverb_sound__intensity_roomSize_absorption_weight.w = compound_ambient_sound__volume * compound_ambient_sound__reverb_intensity_roomSize_absorption_weight.w
      return true


// NOT ParallelUpdateFrameDelayed because should accurate bring event to camera(important)
// (AFTER camera tm update && fmod listener setup) and (BEFORE fmod::update)
[es(tag=sound, after=sound_listener_update_es)]
def compound_ambient_sound_update_event_pos(info : UpdateStageInfoAct;
                                            compound_ambient_sound__closestDistSq : float;
                                            compound_ambient_sound__event : SoundEvent)
  if compound_ambient_sound__closestDistSq == 0.f && compound_ambient_sound__event.handle != invalid_sound_event_handle()
    set_pos(compound_ambient_sound__event.handle, get_listener_pos())


[es(tag=sound, on_appear)]
def compound_ambient_sound_appear(evt : Event;
                                  var game_object_compound_sound__shapes : UInt32List&;
                                  var game_object_compound_sound__transforms : TMatrixList&;
                                  var compound_ambient_sound__extents_maxRadiusSq : Point4List&)
  resize(compound_ambient_sound__extents_maxRadiusSq, length(game_object_compound_sound__transforms))
  if empty(game_object_compound_sound__shapes)
    resize(game_object_compound_sound__shapes, length(game_object_compound_sound__transforms))
    for shape in game_object_compound_sound__shapes
      shape = sound_hash("box")

  for transform, extentsMaxRadiusSq, shape in game_object_compound_sound__transforms, compound_ambient_sound__extents_maxRadiusSq, game_object_compound_sound__shapes
    extentsMaxRadiusSq.xyz = make_sound_shape(transform, shape)


[es(tag=sound, on_appear, track=sound_banks_state__isPresetLoaded, after=compound_ambient_sound_appear)]
def compound_ambient_sound_toggle(evt : Event;
                                  sound_banks_state__isPresetLoaded : bool;
                                  game_object_sound__path : string;
                                  game_object_sound__name : string;
                                  var compound_ambient_sound__range : float&;
                                  compound_ambient_sound__autoRange : bool;
                                  var compound_ambient_sound__curVolIdx : int&;
                                  var compound_ambient_sound__event : SoundEvent&;
                                  var compound_ambient_sound__volume : float&;
                                  var compound_ambient_sound__extents_maxRadiusSq : Point4List&;
                                  game_object_compound_sound__shapes : UInt32List)
  release_immediate(compound_ambient_sound__event.handle)
  compound_ambient_sound__event.enabled = false
  compound_ambient_sound__volume = 0.
  compound_ambient_sound__curVolIdx = 0
  if sound_banks_state__isPresetLoaded
    if compound_ambient_sound__autoRange
      compound_ambient_sound__range = get_max_distance("{game_object_sound__path}/{game_object_sound__name}")
    for extentsMaxRadiusSq, shape in compound_ambient_sound__extents_maxRadiusSq, game_object_compound_sound__shapes
      extentsMaxRadiusSq.w = square(find_sound_shape_radius(extentsMaxRadiusSq.xyz, shape) + compound_ambient_sound__range)
