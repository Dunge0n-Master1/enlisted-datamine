from "%enlSqGlob/ui_library.nut" import *

let { globalWatched } = require("%dngscripts/globalState.nut")
let { get_setting_by_blk_path } = require("settings")

const BARE_MINIMUM = "bare minimum"
const MINIMUM = "minimum"
const LOW = "low"
const MEDIUM = "medium"
const HIGH = "high"
const ULTRA = "ultra"
const CUSTOM = "custom"

const graphicsPresetBlkPath = "graphics/preset"

let { graphicsPreset, graphicsPresetUpdate } = globalWatched("graphicsPreset", @() get_setting_by_blk_path(graphicsPresetBlkPath) ?? MEDIUM)
let isBareMinimum = Computed(@() graphicsPreset.value == BARE_MINIMUM)

return {
  BARE_MINIMUM, MINIMUM, LOW, MEDIUM, HIGH, ULTRA, CUSTOM,
  graphicsPresetBlkPath,
  graphicsPreset,
  graphicsPresetUpdate,
  isBareMinimum
}
