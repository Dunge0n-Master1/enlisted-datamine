import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {get_setting_by_blk_path} = require("settings")
let {getOnlineSaveData, mkSliderWithText, optionCtor} = require("options_lib.nut")

let setCameraFovQuery = ecs.SqQuery("setCameraFovQuery", {
  comps_rw = [ ["fovSettings", ecs.TYPE_FLOAT] ],
  comps_ro = [ ["fovLimits", ecs.TYPE_POINT2], ["camera__fovSettingsPath", ecs.TYPE_STRING] ]
})

local function optionCameraFovTextSliderCtor(opt, group, xmbNode, optionPath) {
  let optSetValue = opt.setValue
  let function setValue(val) {
    optSetValue(val)
    setCameraFovQuery.perform(function(_eid, comp) {
        if (optionPath == comp["camera__fovSettingsPath"])
          comp["fovSettings"] = clamp(val, comp.fovLimits.x, comp.fovLimits.y)
      })
  }
  opt = opt.__merge({setValue})
  return mkSliderWithText(opt, group, xmbNode)
}

let function mkCameraFovOption(title, field, settings={}) {
  let blkPath = $"gameplay/{field}"
  let { watch, setValue } = getOnlineSaveData(blkPath,
    @() get_setting_by_blk_path(blkPath) ?? settings?.defVal ?? 90.0)
  return optionCtor({
    name = title
    tab = "Game"
    widgetCtor = @(opt, group, xmbNode) optionCameraFovTextSliderCtor(opt, group, xmbNode, field)
    var = watch
    setValue = setValue
    defVal = settings?.defVal ?? 90.0
    min = settings?.minVal ?? 50.0
    max = settings?.maxVal ?? 100.0
    unit = 0.05
    pageScroll = 1
    restart = false
    blkPath = blkPath
  })
}

return mkCameraFovOption
