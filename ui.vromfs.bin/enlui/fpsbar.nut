from "%enlSqGlob/ui_library.nut" import *

let fontSize = hdpx(13)
let { perfMetricsValue,
  PERF_METRICS_OFF,
  PERF_METRICS_FPS,
  PERF_METRICS_COMPACT,
  PERF_METRICS_FULL
} = require("%ui/hud/menus/options/performance_metrics_options.nut")

let fpsBarStyle = {
  rendObj = ROBJ_TEXT
  margin = 0
  fontFxFactor = min(24, hdpx(24))
  fontFxColor = 0xA0000000
  fontFx = FFT_SHADOW
  zOrder = Layers.Tooltip
  fontSize
}

let fpsTextMap = {
  [PERF_METRICS_OFF] = "",
  [PERF_METRICS_FPS] = "Direct X 11 FPS:  15.5 (505.5<508.5 500.0)",
  [PERF_METRICS_COMPACT] = "FPS:  888.8",
  [PERF_METRICS_FULL] = "Direct X 11 FPS:  15.5 (505.5<508.5 500.0)"
}.map(@(v) calc_str_box({text=v}.__update(fpsBarStyle)))

let latencyTextMap = {
  [PERF_METRICS_OFF] = "",
  [PERF_METRICS_FPS] = "",
  [PERF_METRICS_COMPACT] = "Latency: 888.8ms",
  [PERF_METRICS_FULL] = "Latency: 888.8ms (A:999.9ms R: 999.9ms)"
}.map(@(v) calc_str_box({text=v}.__update(fpsBarStyle)))

let fpsBar = @(){
  behavior = Behaviors.FpsBar
  size = fpsTextMap?[perfMetricsValue.value] ?? [sw(20), SIZE_TO_CONTENT]
  watch = perfMetricsValue
}.__update(fpsBarStyle)

let latencyBar = @(){
  behavior = Behaviors.LatencyBar
  size = latencyTextMap?[perfMetricsValue.value] ?? [sw(20), SIZE_TO_CONTENT]
  watch = perfMetricsValue
}.__update(fpsBarStyle)

return {fpsBar, latencyBar}
