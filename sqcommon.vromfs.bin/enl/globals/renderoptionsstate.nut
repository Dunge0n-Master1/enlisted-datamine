let {globalWatched} = require("%dngscripts/globalState.nut")
let {get_setting_by_blk_path} = require("settings")
let {get_default_static_resolution_scale} = require("videomode")

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

let renderSettingsTbl = freeze({
  shadowsQuality = {
    defVal = "low"
    blkPath = "graphics/shadowsQuality"
  }
  effectsShadows = {
    defVal = true
    blkPath = "graphics/effectsShadows"
  }
  giQuality = {
    defVal = "low"
    blkPath = "graphics/giQuality"
  }
  rtgiEnabled = {
    defVal = false
    blkPath = "graphics/gi/inlineRaytracing"
  }
  skiesQuality = {
    defVal = "low"
    blkPath = "graphics/skiesQuality"
  }
  aoQuality = {
    defVal = "medium"
    blkPath = "graphics/aoQuality"
  }
  objectsDistanceMul = {
    defVal = 1.0
    blkPath = "graphics/objectsDistanceMul"
  }
  cloudsQuality = {
    defVal = "default"
    blkPath = "graphics/cloudsQuality"
  }
  volumeFogQuality = {
    defVal = "close"
    blkPath = "graphics/volumeFogQuality"
  }
  waterQuality = {
    defVal = "low"
    blkPath = "graphics/waterQuality"
  }
  groundDisplacementQuality = {
    defVal = 1
    blkPath = "graphics/groundDisplacementQuality"
  }
  groundDeformations = {
    defVal = "medium"
    blkPath = "graphics/groundDeformations"
  }
  impostor = {
    defVal = 0
    blkPath = "graphics/impostor"
  }
  antiAliasingModeChosen = {
    defVal = antiAliasingMode.TAA
    blkPath = "video/antiAliasingMode"
  }
  taaQuality = {
    defVal = 1
    blkPath = "graphics/taaQuality"
  }
  taaMipBias = {
    defVal = -0.5
    blkPath = "graphics/taa_mip_bias"
  }
  temporalUpsamplingRatio = {
    defVal = 100.0
    blkPath = "video/temporalUpsamplingRatio"
  }
  staticResolutionScale = {
    defVal = get_default_static_resolution_scale()
    blkPath = "video/staticResolutionScale"
  }
  staticUpsampleQuality = {
    defVal = "catmullrom"
    blkPath = "graphics/staticUpsampleQuality"
  }
  texQuality = {
    defVal = "high"
    blkPath = "graphics/texquality"
  }
  anisotropy = {
    defVal = 4
    blkPath = "graphics/anisotropy"
  }
  onlyHighResFx = {
    defVal = "lowres"
    blkPath = "graphics/fxTarget"
  }
  dropletsOnScreen = {
    defVal = true
    blkPath = "graphics/dropletsOnScreen"
  }
  fxaaQuality = {
    defVal = "medium"
    blkPath = "graphics/fxaaQuality"
  }
  ssrQuality = {
    defVal = "low"
    blkPath = "graphics/ssrQuality"
  }
  scopeImageQuality = {
    defVal = 0
    blkPath = "graphics/scopeImageQuality"
  }
  uncompressedScreenshots = {
    defVal = false
    blkPath = "screenshots/uncompressedScreenshots"
  }
  fsr = {
    defVal = "off"
    blkPath = "video/fsr"
  }
  fftWaterQuality = {
    defVal = "high"
    blkPath = "graphics/fftWaterQuality"
  }
  hqProbeReflections = {
    defVal = true
    blkPath = "graphics/HQProbeReflections"
  }
  ssss = {
    defVal = "low"
    blkPath = "graphics/ssss"
  }
}.map(function(options, name) {
  let gw = globalWatched(name,
      @() get_setting_by_blk_path(options.blkPath) ?? options.defVal)
  options.var <- gw[name]
  options.setValue <- gw[$"{name}Update"]
  return options
}))

return {
  renderSettingsTbl
  antiAliasingMode
  antiAliasingModeToString
}
