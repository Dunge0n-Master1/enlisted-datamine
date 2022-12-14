from "%enlSqGlob/ui_library.nut" import *

let {floor} = require("math")
let {get_setting_by_blk_path} = require("settings")
let {safeAreaAmount, safeAreaBlkPath, safeAreaList, safeAreaSetAmount,
  safeAreaCanChangeInOptions} = require("%enlSqGlob/safeArea.nut")
let platform = require("%dngscripts/platform.nut")
let {DBGLEVEL} = require("dagor.system")

let {loc_opt, defCmp, getOnlineSaveData, mkSliderWithText,
  optionPercentTextSliderCtor, optionCheckBox, optionCombo, optionSlider,
  mkDisableableCtor, optionSpinner,
  optionCtor
} = require("options_lib.nut")
let { resolutionList, resolutionValue } = require("resolution_state.nut")
let { DLSS_BLK_PATH, DLSS_OFF, dlssAvailable, dlssValue, dlssToString,
  dlssSetValue, dlssNotAllowLocId
} = require("dlss_state.nut")
let { XESS_BLK_PATH, XESS_OFF, xessAvailable, xessValue, xessToString,
  xessSetValue, xessNotAllowLocId
} = require("xess_state.nut")
let { LOW_LATENCY_BLK_PATH, LOW_LATENCY_OFF, LOW_LATENCY_NV_ON,
  LOW_LATENCY_NV_BOOST, lowLatencyAvailable, lowLatencyValue,
  lowLatencySetValue, lowLatencyToString, lowLatencySupported
} = require("low_latency_options.nut")
let { PERF_METRICS_BLK_PATH, PERF_METRICS_FPS,
  perfMetricsAvailable, perfMetricsValue, perfMetricsSetValue, perfMetricsToString
} = require("performance_metrics_options.nut")
let { is_inline_rt_supported, is_dx12, is_hdr_available, is_hdr_enabled, change_paper_white_nits,
  change_gamma, get_default_static_resolution_scale
} = require("videomode")
let { availableMonitors, monitorValue, get_friendly_monitor_name } = require("monitor_state.nut")
let { fpsList, UNLIMITED_FPS_LIMIT } = require("fps_list.nut")
let {isBareMinimum} = require("quality_preset_common.nut")

let resolutionToString = @(v) typeof v == "string" ? v : $"{v[0]} x {v[1]}"

let gammaBlkPath = "graphics/gamma_correction"
let gammaCorrectionSave = getOnlineSaveData(gammaBlkPath,
  @() get_setting_by_blk_path(gammaBlkPath) ?? 1.0,
  @(p) clamp(p, 0.5, 1.5)
)

let bareOffText = Computed(@() isBareMinimum.value ? loc("option/off") : null)
let bareLowText = Computed(@() isBareMinimum.value ? loc("option/low") : null)
let bareMinimumText = Computed(@() isBareMinimum.value ? loc("option/minimum") : null)

let consoleGfxSettingsBlk = get_setting_by_blk_path("graphics/consoleGfxSettings")
let consoleSettingsEnabled = (consoleGfxSettingsBlk != null) && (consoleGfxSettingsBlk == true)

let isOptAvailable = @() platform.is_pc || (DBGLEVEL > 0 && (platform.is_sony || platform.is_xbox) && consoleSettingsEnabled)
let isPcDx12 = @() platform.is_pc && is_dx12()

let optSafeArea = optionCtor({
  name = loc("options/safeArea")
  widgetCtor = optionSpinner
  tab = "Graphics"
  isAvailable = safeAreaCanChangeInOptions
  blkPath = safeAreaBlkPath
  var = safeAreaAmount
  setValue = safeAreaSetAmount
  defVal = 1.0
  available = safeAreaList
  valToString = @(s) $"{s*100}%"
  isEqual = defCmp
})

const defVideoMode = "fullscreen"
let originalValVideoMode = get_setting_by_blk_path("video/mode") ?? defVideoMode
let videoModeVar = Watched(originalValVideoMode)

let optVideoMode = optionCtor({
  name = loc("options/mode")
  widgetCtor = optionSpinner
  tab = "Graphics"
  blkPath = "video/mode"
  isAvailable = isOptAvailable
  defVal = defVideoMode
  available = platform.is_windows ? ["windowed", "fullscreenwindowed", "fullscreen"] : ["windowed", "fullscreen"]
  originalVal = originalValVideoMode
  var = videoModeVar
  restart = !platform.is_windows
  valToString = @(s) loc($"options/mode_{s}")
  isEqual = defCmp
})

let optMonitorSelection = optionCtor({
  name = loc("options/monitor", "Monitor")
  widgetCtor = mkDisableableCtor(
    Computed(@() videoModeVar.value == "windowed" ? loc("options/auto") : null),
    optionSpinner)
  tab = "Graphics"
  blkPath = "video/monitor"
  isAvailable = isOptAvailable
  defVal = availableMonitors.current
  available = availableMonitors.list
  originalVal = availableMonitors.current
  var = monitorValue
  valToString = @(v) (v == "auto") ? loc("options/auto") : get_friendly_monitor_name(v)
  isEqual = defCmp
})

videoModeVar.subscribe(function(val){
  if (["fullscreenwindowed", "fullscreen"].indexof(val)!=null)
    resolutionValue("auto")
  else
    monitorValue("auto")
})

let normalize_res_string = @(res) typeof res == "string" ? res.replace(" ", "") : res

let optResolution = optionCtor({
  name = loc("options/resolution")
  widgetCtor = optionCombo
  tab = "Graphics"
  originalVal = resolutionValue
  blkPath = "video/resolution"
  isAvailable = isOptAvailable
  var = resolutionValue
  defVal = resolutionValue
  available = resolutionList
  restart = !(platform.is_windows || platform.is_xboxone)
  valToString = @(v) (v == "auto") ? loc("options/auto") : "{0} x {1}".subst(v[0], v[1])
  isEqual = function(a, b) {
    if (typeof a == "string" || typeof b == "string")
      return normalize_res_string(a) == normalize_res_string(b)
    return a[0]==b[0] && a[1]==b[1]
  }
  convertForBlk = resolutionToString
})

let optHdr = optionCtor({
  name = loc("options/hdr", "HDR")
  tab = "Graphics"
  blkPath = "video/enableHdr"
  isAvailable = isPcDx12
  widgetCtor = mkDisableableCtor(
    Computed(@() is_hdr_available(monitorValue.value) ? null : "{0} ({1})".subst(loc("option/off"), loc("option/monitor_does_not_support", "Monitor doesn't support"))),
    optionCheckBox)
  defVal = false
})

const MIN_PAPER_WHITE_NITS = 100
const MAX_PAPER_WHITE_NITS = 1000
const PAPER_WHITE_NITS_STEP = 10
const DEF_PAPER_WHITE_NITS = 200

let optionPaperWhiteNitsSliderCtor = mkSliderWithText

let originalValPaperWhiteNits = get_setting_by_blk_path("video/paperWhiteNits") ?? DEF_PAPER_WHITE_NITS
let paperWhiteNitsVar = Watched(originalValPaperWhiteNits)

paperWhiteNitsVar.subscribe(change_paper_white_nits)

let optPaperWhiteNits = optionCtor({
  name = loc("options/paperWhiteNits", "Paper White Nits")
  tab = "Graphics"
  blkPath = "video/paperWhiteNits"
  isAvailable = is_hdr_enabled
  widgetCtor = optionPaperWhiteNitsSliderCtor
  var = paperWhiteNitsVar
  min = MIN_PAPER_WHITE_NITS
  max = MAX_PAPER_WHITE_NITS
  pageScroll = PAPER_WHITE_NITS_STEP
  step = PAPER_WHITE_NITS_STEP.tofloat()
  convertForBlk = @(v) (v < MIN_PAPER_WHITE_NITS || v > MAX_PAPER_WHITE_NITS) ? DEF_PAPER_WHITE_NITS : (v).tointeger()
})

let optVsync = optionCtor({
  name = loc("options/vsync")
  tab = "Graphics"
  isAvailable = isOptAvailable
  widgetCtor = mkDisableableCtor(
    Computed(@() lowLatencyValue.value != LOW_LATENCY_NV_ON && lowLatencyValue.value != LOW_LATENCY_NV_BOOST ? null
                   : "{0} ({1})".subst(loc("option/off"), loc("option/off_by_reflex"))),
    optionCheckBox)
  restart = !platform.is_windows
  blkPath = "video/vsync"
  defVal = false
})

let optFpsLimit = optionCtor({
  name = loc("options/fpsLimit")
  tab = "Graphics"
  isAvailable = isOptAvailable
  widgetCtor = optionCombo
  blkPath = "video/fpsLimit"
  defVal = UNLIMITED_FPS_LIMIT
  available = fpsList
  restart = false
  valToString = @(v) (v == UNLIMITED_FPS_LIMIT) ? loc("option/off") : loc("options/fpsLimit/hertz", { value = v })
  convertForBlk = @(v) (v == UNLIMITED_FPS_LIMIT) ? 0 : floor(v + 0.5).tointeger()
  convertFromBlk = @(v) (v == 0) ? UNLIMITED_FPS_LIMIT : v
})

let optLatency = optionCtor({
  name = loc("option/latency", "NVIDIA Reflex Low Latency")
  tab = "Graphics"
  widgetCtor = mkDisableableCtor(
    Computed(@() isBareMinimum.value ? loc("option/off")
      : lowLatencySupported.value ? null
      : "{0} ({1})".subst(loc("option/off"), loc("option/unavailable"))),
    optionSpinner)
  isAvailable = isOptAvailable
  blkPath = LOW_LATENCY_BLK_PATH
  defVal = LOW_LATENCY_OFF
  var = lowLatencyValue
  setValue = lowLatencySetValue
  available = lowLatencyAvailable
  valToString = @(v) loc(lowLatencyToString[v])
})
let isDevBuild = @() platform.is_pc && DBGLEVEL != 0
let optPerformanceMetrics = optionCtor({
  name = loc("options/perfMetrics", "Performance Metrics")
  tab = "Graphics"
  widgetCtor = optionSpinner
  isAvailable = isOptAvailable
  blkPath = PERF_METRICS_BLK_PATH
  defVal = PERF_METRICS_FPS
  var = perfMetricsValue
  setValue = perfMetricsSetValue
  available = perfMetricsAvailable
  valToString = @(v) loc(perfMetricsToString[v])
})
let optShadowsQuality = optionCtor({
  name = loc("options/shadowsQuality", "Shadow Quality")
  widgetCtor = mkDisableableCtor(bareMinimumText, optionSpinner)
  tab = "Graphics"
  isAvailable = isOptAvailable
  blkPath = "graphics/shadowsQuality"
  defVal = "low"
  available = DBGLEVEL > 0 ? [ "minimum",  "low", "medium", "high", "ultra" ] : [  "minimum", "low", "medium", "high" ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
})
let optEffectsShadows = optionCtor({
  name = loc("options/effectsShadows", "Shadows from Effects")
  tab = "Graphics"
  isAvailable = isOptAvailable
  widgetCtor = mkDisableableCtor(bareOffText, optionCheckBox)
  blkPath = "graphics/effectsShadows"
  defVal = true
  restart = false
})

let giQuality = Watched(get_setting_by_blk_path("graphics/giQuality") ?? (isBareMinimum.value ? "minimum" : "low"))

let optGiQuality = optionCtor({
  name = loc("options/giQuality", "Global Illumination Quality")
  widgetCtor = mkDisableableCtor(bareMinimumText, optionSpinner)
  tab = "Graphics"
  isAvailable = isOptAvailable
  blkPath = "graphics/giQuality"
  available = [ "minimum", "low", "medium", "high" ]
  var = giQuality
  valToString = loc_opt
})

let rtgiValueChosen = Watched(get_setting_by_blk_path("graphics/gi/inlineRaytracing") ?? false)

let rtgiSetValue = @(v) rtgiValueChosen(v)

let rtGIDisabled = Computed(@() giQuality.value == "minimum" || giQuality.value == "low")

let rtGIValue = Computed(@() ((is_inline_rt_supported() && !rtGIDisabled.value) ? rtgiValueChosen.value : false))

let optRTGi = optionCtor({
  name = loc("options/RTGI", "Ray Tracing Enhanced Global Illumination")
  tab = "Graphics"
  isAvailable = isPcDx12
  widgetCtor = mkDisableableCtor(Computed(@() !is_inline_rt_supported()
        ? loc("options/inlne_rt_not_supported", "Inline Raytracing not supported")
      : rtGIDisabled.value
        ? loc("options/disabled_by_gi_quality", "Disabled by 'Global Illumination Quality'")
      : null),
    optionCheckBox)
  blkPath = "graphics/gi/inlineRaytracing"
  var = rtGIValue
  setValue = rtgiSetValue
})

let optSkiesQuality = optionCtor({
  name = loc("options/skiesQuality", "Atmospheric Scattering Quality")
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  tab = "Graphics"
  isAvailable = isOptAvailable
  blkPath = "graphics/skiesQuality"
  defVal = "medium"
  available = [ "low", "medium", "high" ]
  restart = false
  valToString = loc_opt
})

let optSsaoQuality = optionCtor({
  name = loc("options/ssaoQuality", "Ambient Occlusion Quality")
  widgetCtor = mkDisableableCtor(bareOffText, optionSpinner)
  tab = "Graphics"
  isAvailable = isOptAvailable
  blkPath = "graphics/aoQuality"
  available = [ "low", "medium", "high" ]
  valToString = loc_opt
  defVal = "medium"
  restart = false
  isEqual = defCmp
})
let optObjectsDistanceMul = optionCtor({
  name = loc("options/objectsDistanceMul")
  widgetCtor = optionSlider
  isAvailable = isDevBuild
  tab = "Graphics"
  blkPath = "graphics/objectsDistanceMul"
  defVal = 1.0
  min = 0.0 max = 1.5 unit = 0.05 pageScroll = 0.05
  restart = false
  getMoreBlkSettings = function(val){
    return [
      {blkPath = "graphics/rendinstDistMul", val = val},
      {blkPath = "graphics/riExtraMulScale", val = val}
    ]
  }
})

let optCloudsQuality = optionCtor({
  name = loc("options/cloudsQuality", "Clouds Quality")
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  tab = "Graphics"
  isAvailable = isOptAvailable
  blkPath = "graphics/cloudsQuality"
  defVal = "default"
  available = [ "default", "highres", "volumetric" ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
})

let optVolumeFogQuality = optionCtor({
  name = loc("options/volumeFogQuality", "Volumetric Fog Quality")
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  tab = "Graphics"
  isAvailable = isOptAvailable
  blkPath = "graphics/volumeFogQuality"
  defVal = "close"
  available = [ "close", "far" ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
})

let optWaterQuality = optionCtor({
  name = loc("options/waterQuality", "Water Quality")
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  tab = "Graphics"
  isAvailable = isOptAvailable
  blkPath = "graphics/waterQuality"
  defVal = "low"
  available = [ "low", "medium", "high" ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
})

let optGroundDisplacementQuality = optionCtor({
  name = loc("options/groundDisplacementQuality", "Terrain Tessellation Quality")
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  tab = "Graphics"
  isAvailable = isOptAvailable
  blkPath = "graphics/groundDisplacementQuality"
  defVal = 1
  available = [ 0, 1, 2 ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
})

let optGroundDeformations = optionCtor({
  name = loc("options/groundDeformations", "Dynamic Terrain Deformations")
  widgetCtor = mkDisableableCtor(bareOffText, optionSpinner)
  tab = "Graphics"
  isAvailable = isOptAvailable
  blkPath = "graphics/groundDeformations"
  defVal = "medium"
  available = [ "off", "low", "medium", "high" ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
})

let optImpostor = optionCtor({
  name = loc("options/impostor", "Impostor quality")
  widgetCtor = optionSpinner
  isAvailable = isDevBuild
  tab = "Graphics"
  blkPath = "graphics/impostor"
  defVal = 0
  available = [ 0, 1, 2 ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
})

enum antiAliasingMode {
  OFF = 0
  FXAA = 1,
  TAA = 2,
  TSR = 3,
  DLSS = 4,
  XESS = 6
};

let antiAliasingModeToString = {
  [antiAliasingMode.OFF]  = { optName = "option/off",  defLocString = "Off" },
  [antiAliasingMode.FXAA] = { optName = "option/fxaa", defLocString = "FXAA" },
  [antiAliasingMode.TAA]  = { optName = "option/taa",  defLocString = "Temporal Anti-aliasing" },
  [antiAliasingMode.TSR]  = { optName = "option/tsr",  defLocString = "Temporal Super Resolution" },
  [antiAliasingMode.DLSS] = { optName = "option/dlss", defLocString = "NVIDIA DLSS" },
  [antiAliasingMode.XESS] = { optName = "option/xess", defLocString = "Intel XeSS" },
}

let antiAliasingModeChoosen = Watched(get_setting_by_blk_path("video/antiAliasingMode")
    ?? (platform.is_nswitch || isBareMinimum.value ? antiAliasingMode.FXAA : antiAliasingMode.TAA))
let antiAliasingModeSetValue = @(v) antiAliasingModeChoosen(v)
let antiAliasingModeValue = Computed(@() isBareMinimum.value ? antiAliasingMode.FXAA
                                                             : max(antiAliasingModeChoosen.value, antiAliasingMode.TAA))


let optAntiAliasingMode = optionCtor({
  name = loc("options/antiAliasingMode", "Anti-aliasing Mode")
  widgetCtor = mkDisableableCtor(Computed(@() isBareMinimum.value ? loc("option/fxaa", "FXAA") : null), optionSpinner)
  tab = "Graphics"
  originalVal = antiAliasingModeValue
  blkPath = "video/antiAliasingMode"
  isAvailable = @() platform.is_pc || platform.is_nswitch
  var = antiAliasingModeValue
  defVal = antiAliasingMode.TAA
  available = Computed(@() [ platform.is_nswitch ? antiAliasingMode.OFF : null,
                platform.is_nswitch || isBareMinimum.value ? antiAliasingMode.FXAA : null,
                !platform.is_nswitch ? antiAliasingMode.TAA : null,
                !platform.is_nswitch ? antiAliasingMode.TSR : null,
                dlssNotAllowLocId.value == null ? antiAliasingMode.DLSS : null,
                xessNotAllowLocId.value == null && isPcDx12 ? antiAliasingMode.XESS : null ].filter(@(q) q != null))
  valToString = @(v) loc(antiAliasingModeToString[v].optName, antiAliasingModeToString[v].defLocString)
  setValue = antiAliasingModeSetValue
})

let optTaaQuality = optionCtor({
  name = loc("options/taaQuality", "Temporal Antialiasing Quality")
  isAvailableWatched = Computed(@() isOptAvailable() && antiAliasingModeValue.value == antiAliasingMode.TAA)
  widgetCtor = mkDisableableCtor(bareOffText, optionSpinner)
  tab = "Graphics"
  blkPath = "graphics/taaQuality"
  defVal = 1
  available = [ 0, 1, 2]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
})

let optDlss = optionCtor({
  name = loc("options/dlssQuality", "NVIDIA DLSS Quality")
  tab = "Graphics"
  widgetCtor = mkDisableableCtor(
    Computed(@() dlssNotAllowLocId.value == null ? null : "{0} ({1})".subst(loc("option/off"), loc(dlssNotAllowLocId.value))),
    optionSpinner)
  isAvailableWatched = Computed(@() isOptAvailable() && antiAliasingModeValue.value == antiAliasingMode.DLSS)
  blkPath = DLSS_BLK_PATH
  defVal = DLSS_OFF
  var = dlssValue
  setValue = dlssSetValue
  available = dlssAvailable
  valToString = @(v) loc(dlssToString[v])
})

let optXess = optionCtor({
  name = loc("options/xessQuality", "Intel XeSS Quality")
  tab = "Graphics"
  widgetCtor = mkDisableableCtor(
    Computed(@() xessNotAllowLocId.value == null ? null : "{0} ({1})".subst(loc("option/off"), loc(xessNotAllowLocId.value))),
    optionSpinner)
  isAvailableWatched = Computed(@() isOptAvailable() && antiAliasingModeValue.value == antiAliasingMode.XESS)
  blkPath = XESS_BLK_PATH
  defVal = XESS_OFF
  var = xessValue
  setValue = xessSetValue
  available = xessAvailable
  valToString = @(v) loc(xessToString[v])
})

let optTaaMipBias = optionCtor({
  name = loc("options/taa_mip_bias", "Enhanced Texture Filtering")
  tab = "Graphics"
  isAvailableWatched = Computed(@() isOptAvailable() && !isBareMinimum.value)
  widgetCtor = optionSlider
  blkPath = "graphics/taa_mip_bias"
  defVal = -0.5
  min = 0 max = -1.2 unit = 0.05 pageScroll = 0.05
  restart = false
})

let optTemporalUpsamplingRatio = optionCtor({
  name = loc("options/temporal_upsampling_ratio", "Temporal Resolution Scale")
  tab = "Graphics"
  isAvailableWatched = Computed(@() isOptAvailable() && antiAliasingModeValue.value == antiAliasingMode.TSR)
  widgetCtor = optionPercentTextSliderCtor
  blkPath = "video/temporalUpsamplingRatio"
  defVal = 100.0
  min = 25.0
  max = 100.0
  unit = 5.0/75.0
  pageScroll = 5.0
  restart = false
})

let optStaticResolutionScale = optionCtor({
  name = loc("options/static_resolution_scale", "Static Resolution Scale")
  tab = "Graphics"
  isAvailableWatched = Computed(@() isOptAvailable() && isBareMinimum.value)
  widgetCtor = optionPercentTextSliderCtor
  blkPath = "video/staticResolutionScale"
  defVal = get_default_static_resolution_scale()
  min = 50.0
  max = 100.0
  unit = 5.0/50.0
  pageScroll = 5.0
  restart = false
})

let staticResolutionScaleWatched = optStaticResolutionScale.var

let optStaticUplsamplingQuality = optionCtor({
  name = loc("options/static_upsampling_quality", "Static Upsampling Quality")
  tab = "Graphics"
  widgetCtor = optionSpinner
  isAvailableWatched = Computed(@() isOptAvailable() && isBareMinimum.value && staticResolutionScaleWatched.value < 100.0)
  blkPath = "graphics/staticUpsampleQuality"
  available = ["bilinear", "catmullrom", "sharpen"]
  defVal = "catmullrom"
  restart = false
  valToString = loc_opt
})

let optGammaCorrection = optionCtor({
  name = loc("options/gamma_correction", "Gamma correction")
  tab = "Graphics"
  isAvailable = @() !is_hdr_enabled()
  widgetCtor = optionSlider
  blkPath = "graphics/gamma_correction"
  var = gammaCorrectionSave.watch
  setValue = function(v) {
      gammaCorrectionSave.setValue(v)
      change_gamma(v)
    }
  defVal = 1.0
  min = 0.5 max = 1.5 unit = 0.05 pageScroll = 0.05
  restart = false
})

let optTexQuality = optionCtor({
  name = loc("options/texQuality")
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  isAvailable = isOptAvailable
  tab = "Graphics"
  blkPath = "graphics/texquality"
  defVal = "high"
  available = ["low", "medium", "high"]
  restart = true
  valToString = loc_opt
  isEqual = defCmp
  tooltipText = loc("guiHints/texQuality")
})

let optAnisotropy = optionCtor({
  name = loc("options/anisotropy")
  widgetCtor = mkDisableableCtor(bareOffText, optionSpinner)
  tab = "Graphics"
  isAvailable = isOptAvailable
  blkPath = "graphics/anisotropy"
  defVal = 4
  available = [1, 2, 4, 8, 16]
  restart = false
  valToString = @(v) (v==1) ? loc("option/off") : $"{v}X"
  isEqual = defCmp
})

let optOnlyonlyHighResFx = optionCtor({
  name = loc("options/onlyHighResFx")
  tab = "Graphics"
  isAvailable = isOptAvailable
  widgetCtor = mkDisableableCtor(bareOffText, optionSpinner)
  defVal = "combined"
  blkPath = "graphics/fxTarget"
  available = ["lowres", "combined", "highres"]
  restart = false
  valToString = loc_opt
})

let optDropletsOnScreen = optionCtor({
  name = loc("options/dropletsOnScreen")
  tab = "Graphics"
  isAvailable = @() platform.is_pc || platform.is_nswitch
  widgetCtor = mkDisableableCtor(bareOffText, optionCheckBox)
  blkPath = "graphics/dropletsOnScreen"
  defVal = true
  restart = false
})

let optFXAAQuality = optionCtor({
  name = loc("options/FXAAQuality")
  tab = "Graphics"
  isAvailableWatched = Computed(@() antiAliasingModeValue.value == antiAliasingMode.FXAA)
  widgetCtor = optionSpinner
  defVal = "medium"
  blkPath = "graphics/fxaaQuality"
  available = ["low", "medium", "high"]
  restart = false
  valToString = loc_opt
})

let optSSRQuality = optionCtor({
  name = loc("options/SSRQuality")
  tab = "Graphics"
  isAvailable = isOptAvailable
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  blkPath = "graphics/ssrQuality"
  available = is_dx12() ? ["low", "medium", "high", "ultra"] : ["low", "medium", "high"]
  defVal = "low"
  restart = false
  valToString = loc_opt
})

let optScopeImageQuality = optionCtor({
  name = loc("options/scopeImageQuality", "Scope Image Quality")
  tab = "Graphics"
  isAvailable = isOptAvailable
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  blkPath = "graphics/scopeImageQuality"
  defVal = 0
  available = [0, 1, 2, 3]
  valToString = loc_opt
  restart = false
  isEqual = defCmp
})

let optUncompressedScreenshots = optionCtor({
  name = loc("options/uncompressedScreenshots")
  tab = "Graphics"
  isAvailable = isOptAvailable
  widgetCtor = optionCheckBox
  blkPath = "screenshots/uncompressedScreenshots"
  defVal = false
  restart = false
})

let optFSR = optionCtor({
  name = loc("options/optFSR", "AMD FidelityFX Super Resolution 1.0")
  tab = "Graphics"
  isAvailableWatched = Computed(@() isOptAvailable() && antiAliasingModeValue.value == antiAliasingMode.TAA)
  widgetCtor = mkDisableableCtor(bareOffText, optionSpinner)
  defVal = "off"
  blkPath = "video/fsr"
  available = ["off", "ultraquality", "quality", "balanced", "performance"]
  restart = false
  valToString = loc_opt
})


let optFFTWaterQuality = optionCtor({
  name = loc("options/fft_water_quality", "Water Ripples Quality")
  tab = "Graphics"
  isAvailable = isOptAvailable
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  defVal = "high"
  blkPath = "graphics/fftWaterQuality"
  available = ["low", "medium", "high", "ultra"]
  restart = false
  valToString = loc_opt
})

let optHQProbeReflections = optionCtor({
  name = loc("options/HQProbeReflections")
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  widgetCtor = mkDisableableCtor(bareOffText, optionCheckBox)
  blkPath = "graphics/HQProbeReflections"
  defVal = true
  restart = false
})

let optSSSS = optionCtor({
  name = loc("options/ssss")
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  widgetCtor = mkDisableableCtor(bareOffText, optionCheckBox)
  blkPath = "graphics/ssss"
  defVal = false
  restart = false
})

return {
  resolutionToString
  optResolution
  optSafeArea
  optVideoMode
  optMonitorSelection
  optHdr
  optPaperWhiteNits
  optPerformanceMetrics
  optLatency
  optVsync
  optFpsLimit
  optShadowsQuality
  optEffectsShadows
  optGiQuality
  optRTGi
  optSkiesQuality
  optSsaoQuality
  optObjectsDistanceMul
  optCloudsQuality
  optVolumeFogQuality
  optWaterQuality
  optGroundDisplacementQuality
  optGroundDeformations
  optImpostor
  optTaaQuality
  optTaaMipBias
  optGammaCorrection
  optTexQuality
  optAnisotropy
  optOnlyonlyHighResFx
  optDropletsOnScreen
  optSSRQuality
  optScopeImageQuality
  optUncompressedScreenshots
  optDlss
  optXess
  optTemporalUpsamplingRatio
  optStaticResolutionScale
  optStaticUplsamplingQuality
  optFSR
  optFFTWaterQuality
  optHQProbeReflections
  optSSSS
  optAntiAliasingMode

  renderOptions = [
    optSafeArea,

    // Display
    {name = loc("group/display", "Display") isSeparator=true tab="Graphics"},
    optResolution,
    optVideoMode,
    optMonitorSelection,
    optHdr,
    optPaperWhiteNits,
    optGammaCorrection,
    optPerformanceMetrics,
    optLatency,
    optVsync,
    optFpsLimit,

    //Antialiasing
    {name = loc("group/antialiasing", "Antialiasing") isSeparator=true tab="Graphics"},
    optAntiAliasingMode,
    optTaaQuality,
    optTaaMipBias,
    optTemporalUpsamplingRatio,
    optStaticResolutionScale,
    optStaticUplsamplingQuality,
    optFXAAQuality,
    optFSR,
    optDlss,
    optXess,

    // Shadows & lighting
    {name = loc("group/shadows_n_lighting", "Shadows & Lighting") isSeparator=true tab="Graphics"},
    optShadowsQuality,
    optEffectsShadows,

    // Lighting
    optGiQuality,
    optRTGi,
    optSkiesQuality,
    optSsaoQuality,
    optSSRQuality,
    optHQProbeReflections,
    optSSSS,

    {name = loc("group/details_n_textures", "Details & Textures") isSeparator=true tab="Graphics"},
    // Texture
    optTexQuality,
    optAnisotropy,
    // Details
    optCloudsQuality,
    optVolumeFogQuality,
    optWaterQuality,
    optFFTWaterQuality,
    optGroundDisplacementQuality,
    optGroundDeformations,
    optOnlyonlyHighResFx,
    optDropletsOnScreen,
    optScopeImageQuality,

    // Other
    {name = loc("group/other", "Other")
     isSeparator=true
     tab="Graphics"
     isAvailable = optUncompressedScreenshots.isAvailable },  // to hide last block's header if it's empty
    optUncompressedScreenshots,

    // Dev builds only
    {name = "Dev options" isSeparator=true tab="Graphics" isAvailable = isDevBuild },
    optImpostor,
    optObjectsDistanceMul,
  ]
}
