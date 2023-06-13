require ecs
require replay
require enlisted.events_enlisted

[es(tag=playingReplay, on_event=CmdReplayRewind, before=replay_on_rewind_es)]
def replay_save_state_on_rewind_es(evt : Event)
  using() <| $(var obj : Object)
    query() <| $ [es] (replay__speed : float)
      obj |> set("replay__speed", replay__speed)
    query() <| $ [es] (dof__on : bool;
                       dof__focalLength_mm : float;
                       dof__focusDistance : float;
                       dof__fStop : float;
                       dof__bokehShape_bladesCount : float;
                       dof__bokehShape_kernelSize : float;
                       dof__is_filmic : bool)
      obj |> set("dof__on", dof__on)
      obj |> set("dof__is_filmic", dof__is_filmic)
      obj |> set("dof__focusDistance", dof__focusDistance)
      obj |> set("dof__focalLength_mm", dof__focalLength_mm)
      obj |> set("dof__fStop", dof__fStop)
      obj |> set("dof__bokehShape_bladesCount", dof__bokehShape_bladesCount)
      obj |> set("dof__bokehShape_kernelSize", dof__bokehShape_kernelSize)
    query() <| $ [es] (motion_blur__scale : float;
                       cinematic_mode__filmGrain : float3;
                       cinematic_mode__vignetteStrength : float;
                       cinematic_mode__chromaticAberration : float3;
                       cinematic_mode__dayTime : float;
                       cinematic_mode__weatherPreset : string;
                       cinematic_mode__rain : bool;
                       cinematic_mode__snow : bool;
                       cinematic_mode__lightning : bool;
                       cinematic_mode__hasSnow : bool;
                       cinematic_mode__hasRain : bool;
                       cinematic_mode__hasLightning : bool;
                       cinematic_mode__enablePostBloom : bool;
                       cinematic_mode__superPixels : int;
                       settings_override__useCustomSettings : bool;
                       cinematic_mode__lenseFlareIntensity : float;
                       cinematic_mode__bloomThreshold : float;
                       cinematic_mode_tag : Tag const?)
      obj |> set("cinematic_mode_on", cinematic_mode_tag != null)
      obj |> set("motion_blur__scale", motion_blur__scale)
      obj |> set("cinematic_mode__chromaticAberration", cinematic_mode__chromaticAberration.z)
      obj |> set("cinematic_mode__bloomThreshold", cinematic_mode__bloomThreshold)
      obj |> set("cinematic_mode__filmGrain", cinematic_mode__filmGrain.x)
      obj |> set("cinematic_mode__vignetteStrength", cinematic_mode__vignetteStrength)
      obj |> set("cinematic_mode__dayTime", cinematic_mode__dayTime)
      obj |> set("cinematic_mode__weatherPreset", cinematic_mode__weatherPreset)
      obj |> set("cinematic_mode__rain", cinematic_mode__rain)
      obj |> set("cinematic_mode__snow", cinematic_mode__snow)
      obj |> set("cinematic_mode__hasRain", cinematic_mode__hasRain)
      obj |> set("cinematic_mode__hasSnow", cinematic_mode__hasSnow)
      obj |> set("cinematic_mode__hasLightning", cinematic_mode__hasLightning)
      obj |> set("cinematic_mode__lightning", cinematic_mode__lightning)
      obj |> set("cinematic_mode__enablePostBloom", cinematic_mode__enablePostBloom)
      obj |> set("cinematic_mode__lenseFlareIntensity", cinematic_mode__lenseFlareIntensity)
      obj |> set("cinematic_mode__superPixels", cinematic_mode__superPixels)
      obj |> set("settings_override__useCustomSettings", settings_override__useCustomSettings)
    query() <| $ [es] (replay_camera__tpsLerpFactor : float)
      obj |> set("replay_camera__tpsLerpFactor", replay_camera__tpsLerpFactor)
    query() <| $ [es] (replay_camera__stopInertia : float)
      obj |> set("replay_camera__stopInertia", replay_camera__stopInertia)
    broadcastEventImmediate([[CmdReplayRewindSaveState state=ecs_addr(obj)]])

[es(tag=playingReplay)]
def replay_on_rewind_es(evt : CmdReplayRewind;
                        var replay__isRewinding : bool&;
                        var replay__isKeyFrameRewind : bool&)
  if replay__isRewinding
    return

  replay__isRewinding = true
  replay__isKeyFrameRewind = true

  let rewindToTime = float(evt.time) / 1000.0
  print("[Replay] Rewinding replay to {rewindToTime}")

  replay_play(replay_get_play_file(), rewindToTime)

[es(tag=playingReplay, on_disappear)]
def replay_on_end(evt : Event; replay__isKeyFrameRewind : bool)
  if !replay__isKeyFrameRewind
    replay_clear_current_play_file()
