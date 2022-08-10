from "%enlSqGlob/ui_library.nut" import *

let { get_setting_by_blk_path } = require("settings")
let { resolutionValue } = require("resolution_state.nut")
let { get_xess_state, is_xess_quality_available_at_resolution } = require("videomode")

const XESS_BLK_PATH = "video/xessQuality"
const XESS_OFF = -1
const XESS_PERFORMANCE = 0
const XESS_BALANCED = 1
const XESS_QUALITY = 2
const XESS_ULTRA_QUALITY = 3

// Values match with enum class XessState in dag_drv3dConsts.h
const UNSUPPORTED_DEVICE = 0
const UNSUPPORTED_DRIVER = 1
const INIT_ERROR_UNKNOWN = 2
const DISABLED = 3
const SUPPORTED = 4
const READY = 5

let xessToString = {
  [XESS_OFF] = "option/off",
  [XESS_PERFORMANCE] = "option/performance",
  [XESS_BALANCED] = "option/balanced",
  [XESS_QUALITY]  = "option/quality",
  [XESS_ULTRA_QUALITY]  = "option/ultraquality",
}

let xessSupportLocId = {
  // These are the cases that can happen in production and we want to feedback users about why is XeSS unavailable
  [UNSUPPORTED_DEVICE] = "xess/unsupportedDevice",
  [UNSUPPORTED_DRIVER] = "xess/unsupportedDriver",
  [INIT_ERROR_UNKNOWN] = "xess/initErrorUnknown",
  [DISABLED] = "xess/disabled"
}
let curXessSupportStateLocId = xessSupportLocId?[get_xess_state()]
let xessNotAllowLocId = Computed(@() curXessSupportStateLocId)

let xessAllQualityModes = [XESS_PERFORMANCE, XESS_BALANCED, XESS_QUALITY, XESS_ULTRA_QUALITY]

let xessAvailable = Computed(function() {
  let xessState = get_xess_state()
  if (xessState != SUPPORTED && xessState != READY)
    return [XESS_OFF]
  local res = resolutionValue.value
  if (type(res) != "array")
    res = [0, 0]
  return xessAllQualityModes.filter(@(q) is_xess_quality_available_at_resolution(res[0], res[1], q))
})

let xessValueChosen = Watched(get_setting_by_blk_path(XESS_BLK_PATH) ?? XESS_QUALITY)

let xessSetValue = @(v) xessValueChosen(v)

let xessValue = Computed(@() xessNotAllowLocId.value != null ? XESS_OFF
  : xessAvailable.value.indexof(xessValueChosen.value) != null ? xessValueChosen.value
  : XESS_OFF)

return {
  XESS_BLK_PATH
  XESS_OFF
  xessAvailable
  xessValue
  xessSetValue
  xessToString
  xessNotAllowLocId
}