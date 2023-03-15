from "%enlSqGlob/ui_library.nut" import *

let { get_setting_by_blk_path } = require("settings")
let { get_arg_value_by_name, DBGLEVEL } = require("dagor.system")
let { is_xboxone, is_xboxone_X, is_xbox, is_xboxone_s,
  is_ps4, is_ps5, is_console } = require("%dngscripts/platform.nut")
let { globalWatched } = require("%dngscripts/globalState.nut")

const ConsolePresetBlkPath = "graphics/consolePreset"
let XB1_MODE_CHANGE_ENABLED = (is_xboxone && !is_xboxone_X) ? false : true

local availableGraphicPresets = ["HighFPS"]
if (is_xbox) {
  if (is_xboxone_s && DBGLEVEL > 0)
    availableGraphicPresets = ["UltraHighFPS", "HighFPS"]
  else if (XB1_MODE_CHANGE_ENABLED)
    availableGraphicPresets = [ "HighFPS", "HighQuality" ]
  else
    availableGraphicPresets = [ "HighFPS" ]
}
else if (is_ps4)
  availableGraphicPresets = [ "HighFPS" ]
else if (is_ps5)
  availableGraphicPresets = [ "HighFPS", "HighQuality" ]

local forceGraphicPreset = is_console ? get_arg_value_by_name("graphicPreset") : null
if (forceGraphicPreset != null) {
  if (availableGraphicPresets.contains(forceGraphicPreset)) {
    log("force graphic preset {0}".subst(forceGraphicPreset))
    availableGraphicPresets = [forceGraphicPreset]
  }
  else {
    log("unknown graphic preset {0}, allowed presets: {1}".subst(forceGraphicPreset), availableGraphicPresets)
    forceGraphicPreset = null
  }
}


let { consoleGraphicsPreset, consoleGraphicsPresetUpdate } = globalWatched("consoleGraphicsPreset",
  @() get_setting_by_blk_path(ConsolePresetBlkPath) ?? availableGraphicPresets[0])

wlog(consoleGraphicsPreset, "consoleGraphicsPreset")

return {
  ConsolePresetBlkPath
  consoleGraphicsPreset
  consoleGraphicsPresetUpdate
  forceGraphicPreset
  availableGraphicPresets
  XB1_MODE_CHANGE_ENABLED
}