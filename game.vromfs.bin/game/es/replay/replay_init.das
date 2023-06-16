require ecs
require ecs.safe
require app
require game.es.camera_common
require DngCamera
require DagorDataBlock
require DagorSystem
require replay
require rapidjson
require enlisted.events_enlisted
require daSkies

[es(tag=playingReplay, on_event=EventLevelLoaded)]
def camera_replay_init_es(evt : Event)
  let camEid = create_camera_by_name("replay_camera", INVALID_ENTITY_ID, null, uint(CreateCameraFlags CCF_SET_ENTITY))
  set_scene_camera_entity(camEid)

[es(tag=playingReplay, on_event=EventLevelLoaded)]
def replay_init_es(evt : Event)
  createEntity("replay_meta")
  createEntity("replay_input")

[es(tag=playingReplay, on_appear)]
def replay_create_cameras(evt : Event; replay_cameras : StringList)
  for cam in replay_cameras
    createEntity(string(cam)) <| $(var init : ComponentsInitializer)
      init |> set("camera__active", false)
      init |> set("camera__target", INVALID_ENTITY_ID)

[es(tag=playingReplay, on_appear, REQUIRE=replayCamera)]
def replay_camera_set_static_position_es(evt : Event; camera__target : EntityId; var transform aka replay_transform : float3x4&)
  if !!camera__target
    return

  find_query() <| $ [es(REQUIRE=initialCamTag)] (transform : float3x4)
    replay_transform = transform
    return true

[es(tag=playingReplay, after=(replay_speed_change_es, change_replay_speed_es))]
def replay_set_current_time_es(evt : UpdateStageInfoAct;
                               var replay__curTime : float&;
                               var replay__speed : float&)
  replay__curTime = evt.curTime
  replay__speed = get_timespeed()

[es(tag=playingReplay, on_appear)]
def replay_read_meta_es(evt : Event;
                        var replay__playTime : float&;
                        var replay__startAt : float&;
                        var replay__keyFrameTimes : IntList&)
  assume replayMeta = get_currently_playing_replay_meta_info()
  replay__playTime = replayMeta |> json_get_or("total_play_time", 0.)
  replay__startAt = replayMeta |> json_get_or("replay__startAt", 0.)

  FindMember(replayMeta, "keyFrames", JsonType kArrayType) <| $(key_frames_values : JsonValue)
    GetArray(key_frames_values) <| $(key_frames : JsonConstArray)
      for frame in key_frames
        replay__keyFrameTimes |> push(json_value_or(frame, 0))

[es(tag=playingReplay, after=replay_read_meta_es)]
def replay_load_rewind_state_es(evt : CmdReplayRewindLoadState; var replay__savedState : Object&)
  assume state = *evt.state
  replay__savedState := state
  query() <| $ [es] (var battle_music__shouldStartIntro : bool&)
    battle_music__shouldStartIntro = false

  query() <| $ [es] (var replay__speed : float&)
    replay__speed = state.replay__speed ?? replay__speed
    set_timespeed(replay__speed)

  query() <| $ [es] (dof__on : bool;
                     dof__focalLength_mm : float;
                     dof__focusDistance : float;
                     dof__fStop : float;
                     dof__bokehShape_bladesCount : float;
                     dof__bokehShape_kernelSize : float;
                     dof__is_filmic : bool)
    broadcastEvent([[CmdSetCameraDofEnabled enabled = state.dof__on ?? dof__on]])
    broadcastEvent([[CmdSetDofIsFilmic isFilmic = state.dof__is_filmic ?? dof__is_filmic]])
    broadcastEvent([[CmdSetDofFocusDistance focusDistance = state.dof__focusDistance ?? dof__focusDistance]])
    broadcastEvent([[CmdSetDofFocalLength focalLength = state.dof__focalLength_mm ?? dof__focalLength_mm]])
    broadcastEvent([[CmdSetDofFStop fStop = state.dof__fStop ?? dof__fStop]])
    broadcastEvent([[CmdSetDofBokehCorners bokehCorners = state.dof__bokehShape_bladesCount ?? dof__bokehShape_bladesCount]])
    broadcastEvent([[CmdSetDofBokehSize bokehSize = state.dof__bokehShape_kernelSize ?? dof__bokehShape_kernelSize]])

  broadcastEvent([[CmdSetCinematicModeEnabled enabled=state.cinematic_mode_on ?? false]])

  query() <| $ [es] (motion_blur__scale : float;
                     cinematic_mode__filmGrain : float3;
                     cinematic_mode__vignetteStrength : float;
                     cinematic_mode__chromaticAberration : float3;
                     cinematic_mode__dayTime : float;
                     cinematic_mode__weatherPreset : string;
                     cinematic_mode__rain : bool;
                     cinematic_mode__snow : bool;
                     cinematic_mode__lightning : bool;
                     cinematic_mode__enablePostBloom : bool;
                     cinematic_mode__superPixels : int;
                     settings_override__useCustomSettings : bool;
                     cinematic_mode__lenseFlareIntensity : float;
                     cinematic_mode__bloomThreshold : float)
    broadcastEvent([[CmdSetMotionBlurScale scale = state.motion_blur__scale ?? motion_blur__scale]])
    broadcastEvent([[CmdSetFilmGrain strength = state.cinematic_mode__filmGrain ?? cinematic_mode__filmGrain.x]])
    broadcastEvent([[CmdSetVignetteStrength strength = state.cinematic_mode__vignetteStrength ?? cinematic_mode__vignetteStrength]])
    broadcastEvent([[CmdSetChromaticAberrationOffset offset = state.cinematic_mode__chromaticAberration ?? cinematic_mode__chromaticAberration.z]])
    broadcastEvent([[CmdChangeTimeOfDay timeOfDay = state.cinematic_mode__dayTime ?? cinematic_mode__dayTime]])
    broadcastEvent([[CmdWeather preset = state.cinematic_mode__weatherPreset ?? cinematic_mode__weatherPreset]])
    broadcastEvent([[CmdSetRain enabled = state.cinematic_mode__rain ?? cinematic_mode__rain]])
    broadcastEvent([[CmdSetSnow enabled = state.cinematic_mode__snow ?? cinematic_mode__snow]])
    broadcastEvent([[CmdSetLightning enabled = state.cinematic_mode__lightning ?? cinematic_mode__lightning]])
    broadcastEvent([[CmdSetCinematicPostFxBloom enabled = state.cinematic_mode__enablePostBloom ?? cinematic_mode__enablePostBloom]])
    broadcastEvent([[CmdSetCinematicSetSuperPixels super_pixels = state.cinematic_mode__superPixels ?? cinematic_mode__superPixels]])
    broadcastEvent([[CmdSetCinematicCustomSettings enabled = state.settings_override__useCustomSettings ?? settings_override__useCustomSettings]])
    broadcastEvent([[CmdSetLenseFlareIntensity intensity = state.cinematic_mode__lenseFlareIntensity ?? cinematic_mode__lenseFlareIntensity]])
    broadcastEvent([[CmdSetBloomThreshold threshold = state.cinematic_mode__bloomThreshold ?? cinematic_mode__bloomThreshold]])

    set_daskies_time(state.cinematic_mode__dayTime ?? cinematic_mode__dayTime)
    query() <| $ [es] (var level__weather : das_string&)
      level__weather := state.cinematic_mode__weatherPreset ?? cinematic_mode__weatherPreset

  query() <| $ [es] (replay_camera__tpsLerpFactor : float)
    broadcastEvent([[CmdSetCameraLerpFactor lerpFactor = state.replay_camera__tpsLerpFactor ?? replay_camera__tpsLerpFactor]])

  query() <| $ [es] (replay_camera__stopInertia : float)
    broadcastEvent([[CmdSetCameraStopLerpFactor stopLerpFactor = state.replay_camera__stopInertia ?? replay_camera__stopInertia]])
