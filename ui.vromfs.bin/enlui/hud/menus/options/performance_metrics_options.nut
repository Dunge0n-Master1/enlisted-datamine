from "%enlSqGlob/ui_library.nut" import *

let { get_setting_by_blk_path } = require("settings")
let { get_performance_display_mode_support } = require("videomode")

const PERF_METRICS_BLK_PATH = "video/perfMetrics"

const PERF_METRICS_OFF = 0
const PERF_METRICS_FPS = 1
const PERF_METRICS_COMPACT = 2
const PERF_METRICS_FULL = 3

let perfMetricsToString = {
  [PERF_METRICS_OFF] = "options/off",
  [PERF_METRICS_FPS] = "options/perf_fps",
  [PERF_METRICS_COMPACT] = "options/perf_compact",
  [PERF_METRICS_FULL] = "options/perf_full"
}

let perfMetricsAvailable = Computed(function() {
  let ret = [
    PERF_METRICS_OFF
  ]
  let options = [
    PERF_METRICS_FPS,
    PERF_METRICS_COMPACT,
    PERF_METRICS_FULL
  ]
  foreach (mode in options) {
    if (get_performance_display_mode_support(mode))
      ret.append(mode)
  }
  return ret
})

let perfMetricsValueChosen = Watched(get_setting_by_blk_path(PERF_METRICS_BLK_PATH))

let perfMetricsSetValue = @(v) perfMetricsValueChosen(v)

let perfMetricsValue = Computed(function() {
  let available = perfMetricsAvailable.value
  let chosen = perfMetricsValueChosen.value
  return available.contains(chosen) ? chosen
    : available.contains(PERF_METRICS_FPS) ? PERF_METRICS_FPS
    : PERF_METRICS_OFF
})

return {
  PERF_METRICS_BLK_PATH
  PERF_METRICS_OFF
  PERF_METRICS_FPS
  PERF_METRICS_COMPACT
  PERF_METRICS_FULL
  perfMetricsAvailable
  perfMetricsValue
  perfMetricsToString
  perfMetricsSetValue
}
