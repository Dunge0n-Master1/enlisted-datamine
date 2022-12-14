from "%enlSqGlob/ui_library.nut" import *

let platform = require("%dngscripts/platform.nut")
let {dgs_get_settings, get_arg_value_by_name} = require("dagor.system")
let {loc_opt, getOnlineSaveData, optionSpinner, optionCtor} = require("%ui/hud/menus/options/options_lib.nut")

let {get_setting_by_blk_path} = require("settings")
let {resolutionToString} = require("%ui/hud/menus/options/render_options.nut")
let { resolutionList } = require("%ui/hud/menus/options/resolution_state.nut")

let XB1_MODE_CHANGE_ENABLED = (platform.is_xboxone && !platform.is_xboxone_X) ? false : true

let dbgConsoles = [null, "ps4", "ps5", "ps4_pro", "xbox"]
let dbgConsolePreset = mkWatched(persist, "dbgConsolePreset", dgs_get_settings()?["debug/dbgConsolePreset"] ?? dbgConsoles[0])
console_register_command(function(pl="auto") {
  console_print("possible values:", ["'auto'"].extend(dbgConsoles))
  if (pl == "auto")
    dbgConsolePreset(dbgConsoles?[(dbgConsoles.indexof(dbgConsolePreset.value)??-1)+1] ?? dbgConsoles[0])
  else
    dbgConsolePreset(pl)
  console_print($"set dbgValue to {dbgConsolePreset.value}. Reload script to see changes")
}, "dbgConsolePresets")

local availableGraphicPresets = ["HighFPS"]
if (platform.is_xbox || dbgConsolePreset.value == "xbox")
  availableGraphicPresets = !XB1_MODE_CHANGE_ENABLED ? [ "HighFPS" ] : [ "HighQuality", "HighFPS" ]
else if (platform.is_ps4 || dbgConsolePreset.value == "ps4" || platform.is_ps4_pro || dbgConsolePreset.value == "ps4_pro")
  availableGraphicPresets = [ "HighFPS" ]
//else if (platform.is_ps4_pro || dbgConsolePreset.value == "ps4_pro")
//  availableGraphicPresets = [ "HighQuality", "HighFPS" ]
else if (platform.is_ps5 || dbgConsolePreset.value == "ps5")
  availableGraphicPresets = [ "HighFPS", "HighQuality" ]

let consoleGfxSettingsBlk = get_setting_by_blk_path("graphics/consoleGfxSettings")
let presetAvailable = (consoleGfxSettingsBlk == null) || (consoleGfxSettingsBlk == false)

let hfps_taa_mip_bias = (platform.is_xboxone_X || platform.is_xbox_scarlett || platform.is_ps4_pro || platform.is_ps5) ? -0.25 : 0.0
let hq_taa_mip_bias = (platform.is_xboxone_X || platform.is_xbox_scarlett) ? -0.5 : -0.25
const hfps_anisotropy = 2
const hq_anisotropy = 4

local forceGraphicPreset = platform.is_console ? get_arg_value_by_name("graphicPreset") : null
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

const ConsolePresetBlkPath = "graphics/consolePreset"

let consoleGraphicsPreset = getOnlineSaveData("video/xboxPreset", function() {
    let cur = get_setting_by_blk_path(ConsolePresetBlkPath)
    return (availableGraphicPresets.contains(cur)) ? cur : availableGraphicPresets[0]
  },
  @(p) availableGraphicPresets.contains(p) ? p : availableGraphicPresets[0])

let optXboxGraphicsPreset = optionCtor({
  name = loc("options/graphicsPreset")
  widgetCtor = optionSpinner
  tab = "Graphics"
  var = consoleGraphicsPreset.watch
  setValue = consoleGraphicsPreset.setValue
  defVal = (XB1_MODE_CHANGE_ENABLED ? forceGraphicPreset : null) ?? "HighFPS"
  isAvailable = @() presetAvailable
  available = availableGraphicPresets
  valToString = @(v) loc(platform.isXboxScarlett && v == "HighFPS" ? "option/HighFPSwithHint" : $"option/{v}")
  blkPath = ConsolePresetBlkPath
  getMoreBlkSettings = function(v){
    return [
      {blkPath = "video/resolution", val = resolutionToString(resolutionList.value?[v == "HighFPS" ? 0 : 1] ?? "auto")},
      {blkPath = "graphics/lodsShiftDistMul", val = (v == "HighFPS" ? 1.3 : 1.0)},
      {blkPath = "graphics/taa_mip_bias", val = (v == "HighFPS" ? hfps_taa_mip_bias : hq_taa_mip_bias)},
      {blkPath = "graphics/taaQuality",   val = (v == "HighQuality" || (platform.is_xboxone_X || platform.is_xbox_scarlett) ? 1 : 0)},
      {blkPath = "graphics/anisotropy", val = (v == "HighFPS" ? hfps_anisotropy : hq_anisotropy)},
      {blkPath = "graphics/aoQuality", val = (v == "HighFPS" ? ((platform.is_xboxone_X || platform.is_xbox_scarlett) ? "medium": "low") : "high")},
      {blkPath = "graphics/groundDeformations", val = (v == "HighQuality" && (platform.is_xboxone_X || platform.is_xbox_scarlett) ? "medium" : "off")},
      {blkPath = "graphics/shadowsQuality", val = (v == "HighQuality" && (platform.is_xboxone_X || platform.is_xbox_scarlett) ? "high" : "low")},
      {blkPath = "graphics/effectsShadows", val = (v == "HighQuality" || (platform.is_xboxone_X || platform.is_xbox_scarlett) ? true : false)},
      {blkPath = "graphics/dropletsOnScreen", val = (v == "HighQuality")},
      {blkPath = "graphics/scopeImageQuality", val = (v == "HighQuality" ? 1 : 0)},
      {blkPath = "graphics/fxTarget", val = (v == "HighQuality" ? "highres" : "lowres")},
      {blkPath = "graphics/shouldRenderHeroCockpit", val = true},
      {blkPath = "graphics/giQuality", val = ((v == "HighQuality" && platform.is_xboxone_X) || platform.is_xbox_scarlett) ? "medium" : "minimum"},
      {blkPath = "graphics/skiesQuality", val = (platform.is_xboxone_s ? "low" : (v == "HighFPS" ? "medium" : "high"))},
      {blkPath = "video/freqLevel", val = (v == "HighFPS" ? 3 : 1)},
      {blkPath = "video/antiAliasingMode", val = (platform.is_xboxone_X || platform.is_xbox_scarlett ? 3 : 2)}, //3 = TSR 2 = TAA
      {blkPath = "video/temporalUpsamplingRatio", val = (platform.is_xboxone_X || platform.is_xbox_scarlett ? 80.0 : 100.0)},
      {blkPath = "graphics/ssss", val = ((v == "HighQuality" && platform.is_xboxone_X) || platform.is_xbox_scarlett)},
      {blkPath = "graphics/cloudsQuality", val = (platform.is_xbox_scarlett ? (v == "HighQuality" && platform.is_xbox_anaconda ? "volumetric" : "highres") : "default")},
      {blkPath = "graphics/volumeFogQuality", val = "close"}
    ]
  }
})

let optPSGraphicsPreset = optionCtor({
  name = loc("options/graphicsPreset")
  widgetCtor = optionSpinner
  tab = "Graphics"
  var = consoleGraphicsPreset.watch
  setValue = consoleGraphicsPreset.setValue
  defVal = forceGraphicPreset ?? "HighFPS"
  isAvailable = @() presetAvailable
  available = availableGraphicPresets
  valToString = loc_opt
  blkPath = ConsolePresetBlkPath
  getMoreBlkSettings = function(v){
    return [
      {blkPath = "video/resolution", val = resolutionToString(resolutionList.value?[v == "HighFPS" ? 0 : 1] ?? "auto")},
      {blkPath = "graphics/lodsShiftDistMul", val = (v == "HighFPS" ? 1.3 : 1.0)},
      {blkPath = "graphics/taa_mip_bias", val = (v == "HighFPS" ? hfps_taa_mip_bias : hq_taa_mip_bias)},
      {blkPath = "graphics/taaQuality",   val = (platform.is_ps4_pro? 2 : ((v == "HighQuality" || platform.is_ps5)? 1:0))},
      {blkPath = "graphics/anisotropy", val = (v == "HighFPS" ? hfps_anisotropy : hq_anisotropy)},
      {blkPath = "graphics/aoQuality", val = (v == "HighFPS" ? (platform.is_ps4_pro ? "medium": "low") : "high")},
      {blkPath = "graphics/groundDeformations", val = (v == "HighQuality" && platform.is_ps4_pro ? "medium" : "off")},
      {blkPath = "graphics/shadowsQuality", val = (v == "HighQuality" ? "high" : "low")},
      {blkPath = "graphics/effectsShadows", val = (v == "HighQuality" ? true : false)},
      {blkPath = "graphics/dropletsOnScreen", val = (v == "HighQuality")},
      {blkPath = "graphics/scopeImageQuality", val = (v == "HighQuality" ? 1 : 0)},
      {blkPath = "video/vsync_tearing_tolerance_percents", val = 10},
      {blkPath = "video/freqLevel", val = (platform.is_ps5 && v == "HighFPS" ? 3 : 1)},
      {blkPath = "graphics/shouldRenderHeroCockpit", val = true},
      {blkPath = "graphics/skiesQuality", val = (platform.is_ps4_simple ? "low" : (v == "HighFPS" ? "medium" : "high"))},
      {blkPath = "video/antiAliasingMode", val = (platform.is_ps4_pro ? 3 : 2)}, //3 = TSR 2 = TAA
      {blkPath = "video/temporalUpsamplingRatio", val = (platform.is_ps4_pro ? 80.0 : 100.0)},
      {blkPath = "graphics/ssss", val = ((v == "HighQuality" && platform.is_ps4_pro) || platform.is_ps5)}
    ]
  }
})

return {
  optXboxGraphicsPreset
  optPSGraphicsPreset
  availableGraphicPresets
  forceGraphicPreset
  dbgConsolePreset
}