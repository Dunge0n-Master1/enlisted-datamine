from "%enlSqGlob/ui_library.nut" import *

let { optionCheckBox, optionCtor, getOnlineSaveData } = require("%ui/hud/menus/options/options_lib.nut")
let { get_setting_by_blk_path } = require("settings")
let { consoleLeaderboardOnlyUpdate, leaderboardOptionNeeded, savedMyConsoleOnlyId
} = require("%enlSqGlob/leaderboard_option_state.nut")
let { settings = Watched({}) } = require_optional("onlineStorage") ? require_optional("%enlist/options/onlineSettings.nut") : null
let locByPlatform = require("%enlSqGlob/locByPlatform.nut")

let function saveLeaderboardState(val, setValue) {
  settings.mutate(@(set) set[savedMyConsoleOnlyId] <- val)
  consoleLeaderboardOnlyUpdate(val)
  setValue(val)
}

let function mkOptionCrosschatOption() {
  let { watch, setValue } = getOnlineSaveData(savedMyConsoleOnlyId,
    @() get_setting_by_blk_path(savedMyConsoleOnlyId) ?? false)
  return optionCtor({
    name = locByPlatform("option/psn_only_leaderboards")
    tab = "Game"
    widgetCtor = optionCheckBox
    var = watch
    setValue = @(val) saveLeaderboardState(val, setValue)
    blkPath = savedMyConsoleOnlyId
  })
}

return {
  leaderboardOptions = leaderboardOptionNeeded
    ? [ mkOptionCrosschatOption() ]
    : []
}