require ecs
require MotionMatching
require %danetlibs/motion_matching/es/mm_events


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
