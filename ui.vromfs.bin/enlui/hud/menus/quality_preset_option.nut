from "%enlSqGlob/ui_library.nut" import *

let platform = require("%dngscripts/platform.nut")
let {is_dx12} = require("videomode")
let {file_exists} = require("dagor.fs")
let {logerr} = require("dagor.debug")
let {optionCtor, optionSpinner, loc_opt} = require("%ui/hud/menus/options/options_lib.nut")
let {
    BARE_MINIMUM, MINIMUM, LOW, MEDIUM, HIGH, ULTRA, CUSTOM,
    QualityPresetBlkPath,
    setGraphicsPreset, curGraphicsPreset
} = require("%ui/hud/menus/options/quality_preset_common.nut")

let {
  optShadowsQuality
  ,optEffectsShadows
  ,optGiQuality
  ,optSkiesQuality
  ,optSsaoQuality
  ,optCloudsQuality
  ,optVolumeFogQuality
  ,optWaterQuality
  ,optGroundDisplacementQuality
  ,optGroundDeformations
  ,optTaaQuality
  ,optTaaMipBias
  ,optAnisotropy
  ,optOnlyonlyHighResFx
  ,optDropletsOnScreen
  ,optSSRQuality
  ,optScopeImageQuality
  ,optTexQuality
  ,optFFTWaterQuality
  ,optHQProbeReflections
  ,optSSSS
  } = require("%ui/hud/menus/options/render_options.nut")

/*
  TODO:
    * check min\max ranges if there are
*/
let presetsRequired = freeze([BARE_MINIMUM, MINIMUM, LOW, MEDIUM, HIGH, ULTRA])
let numPresets = presetsRequired.len()
let bareShaderFile = $"compiledShaders/compatPC/game{is_dx12() ? "DX12" : ""}.ps50.shdump.bin"
let hasBareMinimum = platform.is_pc && file_exists(bareShaderFile)
let avPresets = freeze((hasBareMinimum ? [BARE_MINIMUM] : []).append(MINIMUM, LOW, MEDIUM, HIGH, ULTRA, CUSTOM))

let mapOptionsByPreset = {
   //!!! MEDIUM preset is preset with 'default settings' as they are set in render_options.
   //it is important to keep it for old players (that have installed game before we introduce presets.
   // also it is just common sense - there should be reason why settings are set by default in certain values.
   //It is like an 'optimum value'
   //we need HIGH preset to have 'medium' shadows and it should be fast in terms of performance (so not ULTRA)
   // and we need preset with medium textures - and it should not be by default - so it is 'low' now
   //                               BARE_MINIMUM,  MINIMUM,   LOW,      MEDIUM,   HIGH,       ULTRA
  [optTexQuality]                = ["low",         "low",     "medium", "high",   "high",     "high"],
  [optGiQuality]                 = ["minimum",     "low",     "medium", "medium", "high",     "high"],
  [optAnisotropy]                = [1,             1,         2,        4,        8,          16],
  [optTaaQuality]                = [0,             0,         0,        1,        1,          2],
  [optSkiesQuality]              = ["low",         "low",     "low",    "medium", "high",     "high"],
  [optSsaoQuality]               = ["low",         "low",     "low",    "medium", "high",     "high"],
  [optShadowsQuality]            = ["minimum",     "minimum", "low",    "low",    "medium",   "high"],
  [optEffectsShadows]            = [false,         false,     false,    false,    true,       true],
  [optCloudsQuality]             = ["default",     "default", "default","default","highres",  "volumetric"],
  [optVolumeFogQuality]          = ["close",       "close",   "close",  "close",  "close",    "far"],
  [optWaterQuality]              = ["low",         "low",     "low",    "low",    "medium",   "high"],
  [optGroundDisplacementQuality] = [0,             0,         0,        1,        1,          2],
  [optGroundDeformations]        = ["off",         "off",     "low",    "medium", "high",     "high"],
  [optTaaMipBias]                = [0.0,           0.0,       -0.15,    -0.5,     -0.5,       -1.0],
  [optOnlyonlyHighResFx]         = ["lowres",      "lowres",  "lowres", "lowres", "combined", "highres"],
  [optDropletsOnScreen]          = [false,         false,     false,    true,     true,       true],
  [optSSRQuality]                = ["low",         "low",     "low",    "low",    "medium",   "high"],
  [optScopeImageQuality]         = [0,             0,         0,        1,        2,          3],
  [optFFTWaterQuality]           = ["low",         "low",     "medium", "high",   "ultra",    "ultra"],
  [optHQProbeReflections]        = [false,         false,     false,    true,     true,       true],
  [optSSSS]                      = [false,         false,     false,    false,    true,       true],
}

let optGraphicsQualityPreset = optionCtor({
  name = loc("options/graphicsPreset")
  isAvailable = @() platform.is_pc
  widgetCtor = optionSpinner
  var = curGraphicsPreset
  setValue = setGraphicsPreset
  defVal = MEDIUM
  tab = "Graphics"
  available = avPresets
  valToString = loc_opt
  blkPath = QualityPresetBlkPath
})

foreach (o, q in mapOptionsByPreset){
  let opt = o
  let qualities = q
  let qNum = qualities.len()
  assert(qNum <= numPresets, "preset is missed")
  if (numPresets > qNum){
    qualities.resize(numPresets, qualities[qNum-1])
  }
  foreach (v in qualities){
    if ("available" in opt && !opt.available.contains(v)) {
      logerr($"incorrect preset value: '{v}'")
    }
  }
  opt.var.subscribe(function(_optVal){
    if (curGraphicsPreset.value == CUSTOM)
      return
    if ("isAvailable" in opt && !opt.isAvailable())
      return
    defer(function() {
      if (opt.var.value == qualities?[presetsRequired.indexof(curGraphicsPreset.value)])
        return
      setGraphicsPreset(CUSTOM)
    })
  })
}

let function setOptionsByPreset(...){
  let gp = curGraphicsPreset.value
  if (gp == CUSTOM || !optGraphicsQualityPreset.isAvailable())
    return
  let idx = presetsRequired.indexof(gp)
  foreach (o, q in mapOptionsByPreset){
    let opt = o
    let qualities = q
    if ("isAvailable" in opt && !opt.isAvailable())
      continue
    if ("isDisabled" in opt && opt.isDisabled())
      continue
    let val = qualities[idx]
    if (opt?.var.value ==  val)
      continue
    if ("setValue" in opt)
      opt.setValue(val)
    else if ("var" in opt)
      opt.var(val)
  }
}

curGraphicsPreset.subscribe(setOptionsByPreset)
setOptionsByPreset()

return {
  optGraphicsQualityPreset
}
