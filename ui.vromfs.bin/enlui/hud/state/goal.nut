from "%enlSqGlob/ui_library.nut" import *

let { debounce } = require("%sqstd/timers.nut")
let { briefingState } = require("briefingState.nut")
let { localPlayerTeamInfo } = require("%ui/hud/state/teams.nut")
let { hints } = require("%ui/hud/state/eventlog.nut")
let { needSpawnMenu, respawnsInBot } = require("%ui/hud/state/respawnState.nut")

let isWaitToShow = Watched(false)

let goalText = Computed(function() {
  local locId = localPlayerTeamInfo.value?["team__briefing"] ?? ""
  if (locId == "")
    locId = briefingState.value?.briefing_common ?? ""
  return locId == "" ? "" : loc($"{locId}/short", loc(locId))
})

let showGoal = @() hints.pushEvent({ uid = "goal", text = goalText.value })
let function showGoalWhenReady() {
  if (needSpawnMenu.value)
    isWaitToShow(true)
  else
    showGoal()
}

goalText.subscribe(@(_) showGoalWhenReady())
needSpawnMenu.subscribe(function(show) {
  if (show || !isWaitToShow.value)
    return
  isWaitToShow(false)
  showGoal()
})


let markShowAfterSpawn = debounce(function() {
  if (needSpawnMenu.value && !respawnsInBot.value)
    isWaitToShow(true)
}, 0.5)
needSpawnMenu.subscribe(@(_) markShowAfterSpawn())
respawnsInBot.subscribe(@(_) markShowAfterSpawn())

console_register_command(showGoal, "ui.add_goal_msg")