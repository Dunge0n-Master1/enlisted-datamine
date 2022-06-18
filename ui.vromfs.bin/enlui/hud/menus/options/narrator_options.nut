from "%enlSqGlob/ui_library.nut" import *

let {get_setting_by_blk_path} = require("settings")
let {getOnlineSaveData, optionCheckBox, optionCtor} = require("%ui/hud/menus/options/options_lib.nut")
let narratorNativeLang = require("%enlSqGlob/narratorState.nut")

let optionNarratorCtor = @(actionCb) function (opt, group, xmbNode) {
  let optSetValue = opt.setValue
  let function setValue(val) {
    optSetValue(val)
    actionCb(val)
  }
  opt = opt.__merge({ setValue })
  return optionCheckBox(opt, group, xmbNode)
}

let function mkOption(title, field, actionCb) {
  let blkPath = $"gameplay/{field}"
  let { watch, setValue } = getOnlineSaveData(blkPath,
    @() get_setting_by_blk_path(blkPath) ?? false)
  return optionCtor({
    name = title
    tab = "Game"
    widgetCtor = optionNarratorCtor(actionCb)
    var = watch
    setValue = setValue
    blkPath = blkPath
  })
}

return [
  mkOption(loc("gameplay/narrator_language"), "narrator_nativeLanguage", @(enabled) narratorNativeLang(enabled))
]