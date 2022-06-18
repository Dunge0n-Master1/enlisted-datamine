from "%enlSqGlob/ui_library.nut" import *

let { get_setting_by_blk_path } = require("settings")
let { get_low_latency_modes } = require("videomode")

const LOW_LATENCY_BLK_PATH = "video/latency"

// These values are matched to the enum in lowLatency/lowLatency.h
const LOW_LATENCY_OFF = 0
const LOW_LATENCY_NV_ON = 1
const LOW_LATENCY_NV_BOOST = 2

let lowLatencyToString = {
  [LOW_LATENCY_OFF] = "option/off",
  [LOW_LATENCY_NV_ON] = "option/on",
  [LOW_LATENCY_NV_BOOST] = "option/nv_boost",
}

let lowLatencyAvailable = Computed(function() {
  let supportedModes = get_low_latency_modes()
  let ret = [LOW_LATENCY_OFF]
  if (supportedModes & LOW_LATENCY_NV_ON)
    ret.append(LOW_LATENCY_NV_ON)
  if (supportedModes & LOW_LATENCY_NV_BOOST)
    ret.append(LOW_LATENCY_NV_BOOST)
  return ret
})

let lowLatencySupported = Computed(function() {
  return get_low_latency_modes() > 0
})

let lowLatencyValueChosen = Watched(get_setting_by_blk_path(LOW_LATENCY_BLK_PATH))

let lowLatencySetValue = @(v) lowLatencyValueChosen(v)

let lowLatencyValue = Computed(@() lowLatencyAvailable.value.indexof(lowLatencyValueChosen.value) != null
  ? lowLatencyValueChosen.value : LOW_LATENCY_OFF)

return {
  LOW_LATENCY_BLK_PATH
  LOW_LATENCY_OFF
  LOW_LATENCY_NV_ON
  LOW_LATENCY_NV_BOOST
  lowLatencyAvailable
  lowLatencyValue
  lowLatencySetValue
  lowLatencyToString
  lowLatencySupported
}