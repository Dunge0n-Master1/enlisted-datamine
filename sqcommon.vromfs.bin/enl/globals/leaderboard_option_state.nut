from "%enlSqGlob/ui_library.nut" import *

let sharedWatched = require("%dngscripts/sharedWatched.nut")
let { is_sony, is_xbox } = require("%dngscripts/platform.nut")
let { get_setting_by_blk_path } = require("settings")

let savedMyConsoleOnlyId = "gameplay/psn_only_leaderboards"
let consoleLeaderboardOnly = sharedWatched("consoleLeaderboardOnly",
  @() get_setting_by_blk_path(savedMyConsoleOnlyId) ?? false)
// These names are set in config on leaderboard server. [ "", "pc", "psn", "live" ]
let separateLeaderboardPlatformName = Computed(@() !consoleLeaderboardOnly.value ? ""
  : is_sony ? "psn"
  : is_xbox ? "live"
  : ""
)

return {
  savedMyConsoleOnlyId
  consoleLeaderboardOnly
  separateLeaderboardPlatformName
  leaderboardOptionNeeded = is_sony || is_xbox
}