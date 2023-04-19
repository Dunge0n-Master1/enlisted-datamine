from "%enlSqGlob/ui_library.nut" import *

let { get_setting_by_blk_path } = require("settings")
let { getOnlineSaveData, optionCheckBox, optionCtor } = require("%ui/hud/menus/options/options_lib.nut")
let { headshotSoundEnabled, battleMusicEnabled, humanCapzoneCapturingSoundEnabled } = require("%ui/hud/state/sound_options_state.nut")

let mkWidgetCtor = @(actionCb) function (opt, group, xmbNode) {
  let optSetValue = opt.setValue
  let function setValue(val) {
    optSetValue(val)
    actionCb(val)
  }
  opt = opt.__merge({ setValue })
  return optionCheckBox(opt, group, xmbNode)
}

let function mkOption(title, field, defVal, actionCb, isAvailable = @() true) {
  let blkPath = $"sound/{field}"
  let { watch, setValue } = getOnlineSaveData(blkPath,
    @() get_setting_by_blk_path(blkPath) ?? defVal)
  return optionCtor({
    name = title
    tab = "Sound"
    widgetCtor = mkWidgetCtor(actionCb)
    var = watch
    setValue
    defVal
    blkPath
    isAvailable
  })
}

return {
  headshotSoundOption = mkOption(
    loc("sound/headshot_sound_enabled"), "headshot_sound_enabled", true, headshotSoundEnabled
  )
  battleMusicOption = mkOption(
    loc("sound/battle_music_enabled"), "battle_music_enabled", true, battleMusicEnabled
  )
  humanCapzoneCapturingSoundOption = mkOption(
    loc("sound/human_capzone_capturing_sound_enabled"), "human_capzone_capturing_sound_enabled", true, humanCapzoneCapturingSoundEnabled
  )
}