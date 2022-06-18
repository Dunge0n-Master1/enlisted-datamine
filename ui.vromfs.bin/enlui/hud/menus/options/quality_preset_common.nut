from "%enlSqGlob/ui_library.nut" import *

let {get_setting_by_blk_path} = require("settings")

const BARE_MINIMUM = "bare minimum"
const MINIMUM = "minimum"
const LOW = "low"
const MEDIUM = "medium"
const HIGH = "high"
const ULTRA = "ultra"
const CUSTOM = "custom"

const QualityPresetBlkPath = "graphics/preset"

let savedGraphicsPreset = Watched(get_setting_by_blk_path(QualityPresetBlkPath) ?? MEDIUM)
let setGraphicsPreset = @(v) savedGraphicsPreset(v)
let curGraphicsPreset = Computed(@() savedGraphicsPreset.value)

let isBareMinimum = Computed(@() savedGraphicsPreset.value == BARE_MINIMUM)

let wasPresetSet = get_setting_by_blk_path(QualityPresetBlkPath)!=null

if (!wasPresetSet){
  setGraphicsPreset(CUSTOM)
}

return {
  BARE_MINIMUM, MINIMUM, LOW, MEDIUM, HIGH, ULTRA, CUSTOM,
  QualityPresetBlkPath,
  savedGraphicsPreset, setGraphicsPreset, curGraphicsPreset,
  isBareMinimum
}
