require ecs
require MotionMatching
require %danetlibs/motion_matching/es/mm_events


[es]
def mm_lod_selector(info : ParallelUpdateFrameDelayed;
                    var motion_matching__distanceFactor : float&;
                    transform aka character_transform : float3x4)
  motion_matching__distanceFactor = 1.f
  find_query() <| $ [es] (camera__active : bool; transform aka camera_transform : float3x4)
    if !camera__active
      return false
    let distance = length(camera_transform[3] - character_transform[3])
    motion_matching__distanceFactor += 0.2f * sqrt(distance)
    return true

[es]
def mm_update_metrica_tolerance(info : ParallelUpdateFrameDelayed;
                                motion_matching__controller : MotionMatchingController;
                                motion_matching__presetIdx : int;
                                var motion_matching__metricaTolerance : float&)
  assume presets = motion_matching__controller.dataBase.tagsPresets
  if motion_matching__presetIdx >= 0 && motion_matching__presetIdx < length(presets)
    assume preset = presets[motion_matching__presetIdx]
    let decaySpeed = (preset.metricaToleranceMax - preset.metricaToleranceMin) / (preset.metricaToleranceDecayTime + 0.0001)
    motion_matching__metricaTolerance = max(motion_matching__metricaTolerance - decaySpeed * info.dt, preset.metricaToleranceMin);
