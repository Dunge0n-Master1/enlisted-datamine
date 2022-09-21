require ecs
require enlisted.events_enlisted

[es(tag=playingReplay, on_event=EventLevelLoaded)]
def replay_create_cinematic_mode_settings_entity(evt : Event)
  createEntity("cinematic_mode_settings")

[es(tag=render)]
def set_all_camera_fov_es(evt : CmdSetCameraFov; var fovSettings : float&)
  fovSettings = evt.fov

[es(tag=render)]
def set_free_tps_camera_speed_es(evt : CmdSetFreeTpsCameraSpeed; var free_cam__move_speed : float&)
  free_cam__move_speed = evt.speed

[es(tag=render)]
def enable_camera_dof(evt : CmdSetCameraDofEnabled)
  query() <| $ [es] (var dof__on : bool&)
    dof__on = evt.enabled

[es(tag=render, REQUIRE=cinematic_mode__fps)]
def set_cinematic_mode_enabled_es(evt : CmdSetCinematicModeEnabled; eid : EntityId)
  if evt.enabled
    addSubTemplate(eid, "cinematic_mode_manager")
  else
    removeSubTemplate(eid, "cinematic_mode_manager")

[es(tag=render)]
def set_motion_blur_scale_es(evt : CmdSetMotionBlurScale; var cinematic_mode__mb_scale : float&)
  cinematic_mode__mb_scale = evt.scale

[es(tag=render)]
def set_bloom_threshold_es(evt : CmdSetBloomThreshold; var cinematic_mode__bloomThreshold : float&)
  cinematic_mode__bloomThreshold = evt.threshold

[es(tag=render)]
def set_chromatic_aberration_offset_es(evt : CmdSetChromaticAberrationOffset; var cinematic_mode__chromaticAberration : float3&)
  cinematic_mode__chromaticAberration.z = evt.offset

[es(tag=render)]
def set_film_grain_es(evt : CmdSetFilmGrain; var cinematic_mode__filmGrain : float3&)
  cinematic_mode__filmGrain.x = evt.strength

[es(tag=render)]
def set_vignette_strength_es(evt : CmdSetVignetteStrength; var cinematic_mode__vignetteStrength : float&)
  cinematic_mode__vignetteStrength = evt.strength

[es(tag=render)]
def set_dof_filmic_es(evt : CmdSetDofIsFilmic; var dof__is_filmic : bool&)
  dof__is_filmic = evt.isFilmic

[es(tag=render)]
def set_dof_focus_distance_es(evt : CmdSetDofFocusDistance; var dof__focusDistance : float&)
  dof__focusDistance = evt.focusDistance

[es(tag=render)]
def set_dof_focal_length_es(evt : CmdSetDofFocalLength; var dof__focalLength : float&)
  dof__focalLength = evt.focalLength

[es(tag=render)]
def set_dof_fstop_es(evt : CmdSetDofFStop; var dof__fStop : float&)
  dof__fStop = evt.fStop

[es(tag=render)]
def set_dof_bokeh_corners_es(evt : CmdSetDofBokehCorners; var dof__bokehShape_bladesCount : float&)
  dof__bokehShape_bladesCount = evt.bokehCorners

[es(tag=render)]
def set_dof_bokeh_size_es(evt : CmdSetDofBokehSize; var dof__bokehShape_kernelSize : float&)
  dof__bokehShape_kernelSize = evt.bokehSize

[es(tag=render)]
def set_change_time_of_day_es(evt : CmdChangeTimeOfDay; var cinematic_mode__dayTime : float&)
  cinematic_mode__dayTime = evt.timeOfDay

[es(tag=render)]
def set_weather_preset_of_day_es(evt : CmdWeather; var cinematic_mode__weatherPreset : das_string&)
  cinematic_mode__weatherPreset := evt.preset

[es(tag=render)]
def cinematic_enable_rain_es(evt : CmdSetRain; var cinematic_mode__rain : bool&)
  cinematic_mode__rain = evt.enabled

[es(tag=render)]
def cinematic_enable_show_es(evt : CmdSetSnow; var cinematic_mode__snow : bool&)
  cinematic_mode__snow = evt.enabled

[es(tag=render)]
def cinematic_enable_lightning_es(evt : CmdSetLightning; var cinematic_mode__lightning : bool&)
  cinematic_mode__lightning = evt.enabled

[es(tag=render)]
def cinematic_set_lense_flare_intensity_es(evt : CmdSetLenseFlareIntensity; var cinematic_mode__lenseFlareIntensity : float&)
  cinematic_mode__lenseFlareIntensity = evt.intensity
