from "%enlSqGlob/ui_library.nut" import *

let platform = require("%dngscripts/platform.nut")
let {get_setting_by_blk_path} = require("settings")
let {getOnlineSaveData, optionCheckBox, optionCtor} = require("%ui/hud/menus/options/options_lib.nut")
let {
  hudMarkerEnable, minimalistHud, setShowBattleChat, forceDisableBattleChat, showSelfAwards,
  showTeammateName, showTeammateMarkers, showCrosshairHints, showTips, showGameModeHints,
  showPlayerUI
} = require("%ui/hud/state/hudOptionsState.nut")

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
  let blkPath = $"gameplay/{field}"
  let { watch, setValue } = getOnlineSaveData(blkPath,
    @() get_setting_by_blk_path(blkPath) ?? defVal)
  return optionCtor({
    name = title
    tab = "Game"
    widgetCtor = mkWidgetCtor(actionCb)
    var = watch
    setValue
    defVal
    blkPath
    isAvailable
  })
}

return {
  hudOptions = [
    mkOption(loc("gameplay/hud_markers"), "hud_markers", true, @(enabled) hudMarkerEnable(enabled))
    mkOption(loc("gameplay/show_teammate_name"), "show_teammate_name", true,
      @(enabled) showTeammateName(enabled))
    mkOption(loc("gameplay/show_teammate_markers"), "show_teammate_markers", true,
      @(enabled) showTeammateMarkers(enabled))
    mkOption(loc("gameplay/show_crosshair_hints"), "show_crosshair_hints", true,
      @(enabled) showCrosshairHints(enabled))
    mkOption(loc("gameplay/show_tips"), "show_tips", true,
      @(enabled) showTips(enabled))
    mkOption(loc("gameplay/show_game_mode_hints"), "show_game_mode_hints", true,
      @(enabled) showGameModeHints(enabled))
    mkOption(loc("gameplay/show_player_ui"), "show_player_ui", true,
      @(enabled) showPlayerUI(enabled))
    mkOption(loc("gameplay/minimalist_hud"), "minimalist_hud", false,
      @(enabled) minimalistHud(enabled))
    !platform.is_pc || forceDisableBattleChat.value
      ? null
      : mkOption(loc("gameplay/show_battle_chat", "Show Battle Chat"), "show_battle_chat", true, setShowBattleChat)
    mkOption(loc("gameplay/self_awards"), "show_self_awards", true, @(enabled) showSelfAwards(enabled))
  ]
}