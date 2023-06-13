from "%enlSqGlob/ui_library.nut" import *

let { get_setting_by_blk_path } = require("settings")
let { get_fsr2_state } = require("videomode")

const FSR2_BLK_PATH = "video/fsr2Quality"
const FSR2_OFF = -1
const FSR2_QUALITY = 0
const FSR2_BALANCED = 1
const FSR2_PERFORMANCE = 2
const FSR2_ULTRA_PERFORMANCE = 3

// Values match with enum class Fsr2State in dag_drv3dConsts.h
const NOT_CHECKED = 0
const INIT_ERROR = 1
const SUPPORTED = 2
const READY = 3

let fsr2ToString = {
  [FSR2_OFF] = "option/off",
  [FSR2_QUALITY] = "option/quality",
  [FSR2_BALANCED] = "option/balanced",
  [FSR2_PERFORMANCE]  = "option/performance",
  [FSR2_ULTRA_PERFORMANCE]  = "option/ultraperformance",
}

let fsr2AllQualityModes = [FSR2_QUALITY, FSR2_BALANCED, FSR2_PERFORMANCE, FSR2_ULTRA_PERFORMANCE]

let fsr2Supported = Computed(@() get_fsr2_state() >= SUPPORTED )

let fsr2Available = Computed(function() {
  if (!fsr2Supported.value)
    return [FSR2_OFF]
  return fsr2AllQualityModes
})

let fsr2ValueChosen = Watched(get_setting_by_blk_path(FSR2_BLK_PATH) ?? FSR2_QUALITY)

let fsr2SetValue = @(v) fsr2ValueChosen(v)

let fsr2Value = Computed(@() !fsr2Supported.value ? FSR2_OFF : fsr2ValueChosen.value)

return {
  FSR2_BLK_PATH
  FSR2_OFF
  fsr2Supported
  fsr2Available
  fsr2Value
  fsr2SetValue
  fsr2ToString
}