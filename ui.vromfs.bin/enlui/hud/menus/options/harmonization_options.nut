from "%enlSqGlob/ui_library.nut" import *

let { set_setting_by_blk_path } = require("settings")
let { harmonizationRequired, harmonizationState, harmonizationStateUpdate } = require("%enlSqGlob/harmonizationState.nut")
let { optionCheckBox, optionCtor } = require("%ui/hud/menus/options/options_lib.nut")

let optionHarmonizationCtor = @(actionCb) function (opt, group, xmbNode) {
  let optSetValue = opt.setValue
  let function setValue(val) {
    optSetValue(val)
    actionCb(val)
  }
  opt = opt.__merge({ setValue })
  return optionCheckBox(opt, group, xmbNode)
}

let function mkOption(title, field, watch, actionCb) {
  let blkPath = $"{field}"
  let setValue = @(v) set_setting_by_blk_path(blkPath, v)
  return optionCtor({
    name = title
    tab = "Game"
    widgetCtor = optionHarmonizationCtor(actionCb)
    var = watch
    setValue = setValue
    blkPath = blkPath
    restart = true
  })
}

let harmonizationOption = harmonizationRequired ? null :
  mkOption(loc("options/harmonization"), "harmonizationEnabled", harmonizationState, harmonizationStateUpdate)

return {
  harmonizationOption
}