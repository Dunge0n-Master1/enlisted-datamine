from "%enlSqGlob/ui_library.nut" import *

let {get_setting_by_blk_path} = require("settings")
let isDmm = require("%enlSqGlob/dmm_distr.nut")

let hudMarkerEnable = mkWatched(persist, "hudMarkerEnable", get_setting_by_blk_path("gameplay/hud_markers") ?? true)
let minimalistHud = mkWatched(persist, "minimalistHud", get_setting_by_blk_path("gameplay/minimalist_hud") ?? false)
let showBattleChat = mkWatched(persist, "showChat", get_setting_by_blk_path("gameplay/show_battle_chat") ?? true)
let showSelfAwards = mkWatched(persist, "showActions", get_setting_by_blk_path("gameplay/show_self_awards") ?? true)
let showTeammateName = mkWatched(persist, "showTeammateName", get_setting_by_blk_path("gameplay/show_teammate_name") ?? true)
let showTeammateMarkers = mkWatched(persist, "showTeammateMarkers", get_setting_by_blk_path("gameplay/show_teammate_markers") ?? true)
let showCrosshairHints = mkWatched(persist, "showCrosshairHints", get_setting_by_blk_path("gameplay/show_crosshair_hints") ?? true)
let showTips = mkWatched(persist, "showTips", get_setting_by_blk_path("gameplay/show_tips") ?? true)
let showGameModeHints = mkWatched(persist, "showGameModeHints", get_setting_by_blk_path("gameplay/show_game_mode_hints") ?? true)
let showPlayerUI = mkWatched(persist, "showPlayerUI", get_setting_by_blk_path("gameplay/show_player_ui") ?? true)


let forceDisableBattleChat = isDmm || (get_setting_by_blk_path("gameplay/force_disable_battle_chat") ?? false)

let setShowBattleChat = @(val) showBattleChat(val)

return {
  hudMarkerEnable
  minimalistHud
  showBattleChat = Computed(@() !forceDisableBattleChat && showBattleChat.value)
  showSelfAwards
  setShowBattleChat
  forceDisableBattleChat
  showTeammateName
  showTeammateMarkers
  showCrosshairHints
  showTips
  showGameModeHints
  showPlayerUI
}