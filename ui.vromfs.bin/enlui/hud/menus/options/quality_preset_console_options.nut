from "%enlSqGlob/ui_library.nut" import *

let { is_xboxone_X, is_xbox_scarlett, isXboxScarlett, is_xboxone_s, is_xbox_anaconda,
  is_ps4_simple, is_ps4_pro, is_ps5 } = require("%dngscripts/platform.nut")
let { loc_opt, optionSpinner, optionCtor } = require("%ui/hud/menus/options/options_lib.nut")

let { resolutionToString } = require("%ui/hud/menus/options/render_options.nut")
let { resolutionList } = require("%ui/hud/menus/options/resolution_state.nut")
let { get_setting_by_blk_path } = require("settings")
let { ConsolePresetBlkPath, consoleGraphicsPreset, consoleGraphicsPresetUpdate, forceGraphicPreset, availableGraphicPresets,
  XB1_MODE_CHANGE_ENABLED } = require("%ui/hud/menus/options/quality_preset_console_common.nut")

const hfps_anisotropy = 2
const hq_anisotropy = 4
let hfps_taa_mip_bias = (is_xboxone_X || is_xbox_scarlett || is_ps4_pro || is_ps5) ? -0.25 : 0.0
let hq_taa_mip_bias = (is_xboxone_X || is_xbox_scarlett) ? -0.5 : -0.25

let consoleGfxSettingsBlk = get_setting_by_blk_path("graphics/consoleGfxSettings")
let presetAvailable = (consoleGfxSettingsBlk == null) || (consoleGfxSettingsBlk == false)

let optXboxGraphicsPreset = optionCtor({
  name = loc("options/graphicsPreset")
  widgetCtor = optionSpinner
  tab = "Graphics"
  var = consoleGraphicsPreset
  setValue = consoleGraphicsPresetUpdate
  defVal = (XB1_MODE_CHANGE_ENABLED ? forceGraphicPreset : null) ?? "HighFPS"
  isAvailable = @() presetAvailable
  available = availableGraphicPresets
  valToString = @(v) loc(isXboxScarlett && v == "HighFPS" ? "option/HighFPSwithHint" : $"option/{v}")
  blkPath = ConsolePresetBlkPath
  getMoreBlkSettings = function(v){
    return [
      {blkPath = "video/resolution", val = resolutionToString(v == "UltraHighFPS" ? [1280, 720] : resolutionList.value?[v == "HighFPS" ? 0 : 1] ?? "auto")},
      {blkPath = "graphics/lodsShiftDistMul", val = (v == "HighFPS" ? 1.3 : 1.0)},
      {blkPath = "graphics/taa_mip_bias", val = (v == "HighFPS" ? hfps_taa_mip_bias : hq_taa_mip_bias)},
      {blkPath = "graphics/taaQuality",   val = (v == "HighQuality" || (is_xboxone_X || is_xbox_scarlett) ? 1 : 0)},
      {blkPath = "graphics/anisotropy", val = (v == "HighFPS" ? hfps_anisotropy : hq_anisotropy)},
      {blkPath = "graphics/aoQuality", val = (v == "HighFPS" ? ((is_xboxone_X || is_xbox_scarlett) ? "medium": "low") : "high")},
      {blkPath = "graphics/groundDeformations", val = (v == "HighQuality" && (is_xboxone_X || is_xbox_scarlett) ? "medium" : "off")},
      {blkPath = "graphics/shadowsQuality", val = (v == "HighQuality" && (is_xboxone_X || is_xbox_scarlett) ? "high" : "low")},
      {blkPath = "graphics/effectsShadows", val = (v == "HighQuality" || (is_xboxone_X || is_xbox_scarlett) ? true : false)},
      {blkPath = "graphics/dropletsOnScreen", val = (v == "HighQuality")},
      {blkPath = "graphics/scopeImageQuality", val = (v == "HighQuality" ? 1 : 0)},
      {blkPath = "graphics/fxTarget", val = (v == "HighQuality" ? "highres" : "lowres")},
      {blkPath = "graphics/shouldRenderHeroCockpit", val = true},
      {blkPath = "graphics/giQuality", val = ((v == "HighQuality" && is_xboxone_X) || is_xbox_scarlett) ? "medium" : "minimum"},
      {blkPath = "graphics/skiesQuality", val = (is_xboxone_s ? "low" : (v == "HighFPS" ? "medium" : "high"))},
      {blkPath = "video/freqLevel", val = (v == "HighFPS" ? 3 : 1)},
      {blkPath = "video/antiAliasingMode", val = (is_xboxone_X || is_xbox_scarlett ? 3 : 2)}, //3 = TSR 2 = TAA
      {blkPath = "video/temporalUpsamplingRatio", val = (is_xboxone_X || is_xbox_scarlett ? 80.0 : 100.0)},
      {blkPath = "graphics/ssss", val = ((v == "HighQuality" && is_xboxone_X) || is_xbox_scarlett ? "high" : "off")},
      {blkPath = "graphics/cloudsQuality", val = (is_xbox_scarlett ? (v == "HighQuality" && is_xbox_anaconda ? "volumetric" : "highres") : "default")},
      {blkPath = "graphics/volumeFogQuality", val = "close"}
    ]
  }
})

let optPSGraphicsPreset = optionCtor({
  name = loc("options/graphicsPreset")
  widgetCtor = optionSpinner
  tab = "Graphics"
  var = consoleGraphicsPreset
  setValue = consoleGraphicsPresetUpdate
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
      {blkPath = "graphics/taaQuality",   val = (is_ps4_pro? 2 : ((v == "HighQuality" || is_ps5)? 1:0))},
      {blkPath = "graphics/anisotropy", val = (v == "HighFPS" ? hfps_anisotropy : hq_anisotropy)},
      {blkPath = "graphics/aoQuality", val = (v == "HighFPS" ? (is_ps4_pro ? "medium": "low") : "high")},
      {blkPath = "graphics/groundDeformations", val = (v == "HighQuality" && is_ps4_pro ? "medium" : "off")},
      {blkPath = "graphics/shadowsQuality", val = (v == "HighQuality" ? "high" : "low")},
      {blkPath = "graphics/effectsShadows", val = (v == "HighQuality" ? true : false)},
      {blkPath = "graphics/dropletsOnScreen", val = (v == "HighQuality")},
      {blkPath = "graphics/scopeImageQuality", val = (v == "HighQuality" ? 1 : 0)},
      {blkPath = "video/vsync_tearing_tolerance_percents", val = 10},
      {blkPath = "video/freqLevel", val = (is_ps5 && v == "HighFPS" ? 3 : 1)},
      {blkPath = "graphics/shouldRenderHeroCockpit", val = true},
      {blkPath = "graphics/skiesQuality", val = (is_ps4_simple ? "low" : (v == "HighFPS" ? "medium" : "high"))},
      {blkPath = "video/antiAliasingMode", val = (is_ps4_pro ? 3 : 2)}, //3 = TSR 2 = TAA
      {blkPath = "video/temporalUpsamplingRatio", val = (is_ps4_pro ? 80.0 : 100.0)},
      {blkPath = "graphics/ssss", val = ((v == "HighQuality" && is_ps4_pro) || is_ps5 ? "high" : "off")}
    ]
  }
})

return {
  optXboxGraphicsPreset
  optPSGraphicsPreset
}