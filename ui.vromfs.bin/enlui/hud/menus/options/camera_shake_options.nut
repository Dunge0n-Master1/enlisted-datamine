import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {get_setting_by_blk_path} = require("settings")
let {getOnlineSaveData, optionSlider, optionCtor} = require("%ui/hud/menus/options/options_lib.nut")
let {cameraShakeOptions, cameraShakeComps} = require("%enlSqGlob/camera_shake_options.nut")

let setCameraShakeOptionsQuery = ecs.SqQuery("setCameraShakeOptionsQuery", {
  comps_rw = cameraShakeComps
})

let mkWidgetCtor = @(compName) function(opt, group, xmbNode) {
  let optSetValue = opt.setValue
  let function setValue(val) {
    optSetValue(val)
    setCameraShakeOptionsQuery(function(_eid, comp) {
      comp[compName] = val
    })
  }
  opt = opt.__merge({ setValue })
  return optionSlider(opt, group, xmbNode)
}

let mkCameraOption = kwarg(function(blkPath, compName, unit = 0.05) {
  let { watch, setValue } = getOnlineSaveData(blkPath, @() get_setting_by_blk_path(blkPath) ?? 1.0)
  return optionCtor({
    name = loc(blkPath)
    tab = "Game"
    var = watch
    pageScroll = 1
    restart = false
    defVal = 1.0
    min = 0.0
    max = 1.0
    widgetCtor = mkWidgetCtor(compName)
    blkPath
    setValue
    unit
  })
})

return {
  cameraShakeOptions = cameraShakeOptions.map(mkCameraOption)
}