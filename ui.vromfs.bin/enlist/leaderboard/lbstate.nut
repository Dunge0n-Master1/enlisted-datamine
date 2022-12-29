from "%enlSqGlob/ui_library.nut" import *

let userInfo = require("%enlSqGlob/userInfo.nut")
let { appId } = require("%enlSqGlob/clientState.nut")
let { curLbData, curLbSelfRow, curLbRequestData, setLbRequestData, curLbErrName,
  refreshLbData, requestSelfRow
} = require("%enlist/leaderboard/lbStateBase.nut")
let { lbStatsModes } = require("%enlist/userstat/userstatModes.nut")
let { RANK, NAME, KILL_DEATH_RATIO, BATTLES, KILLS, KILLS_USING_AIRCRAFT,
  KILLS_USING_TANK, VICTORIES_PERCENT, SCORE, TOURNAMENT_BATTLE_RATING,
  BATTLE_GROUP_SCORE, BATTLE_RATING, BATTLE_TIME, BATTLE_RATING_PENALTY,
  TIME_AFTER_BATTLE, VICTORY_BOOL
} = require("lbCategory.nut")
let { separateLeaderboardPlatformName } = require("%enlSqGlob/leaderboard_option_state.nut")
let { eventGameModes } = require("%enlist/gameModes/gameModeState.nut")
let { userstatStats } = require("%enlSqGlob/userstats/userstat.nut")
let { selEvent, selLbMode } = require("%enlist/gameModes/eventModesState.nut")


let LB_PAGE_ROWS = 25
const REFRESH_PERIOD = 10.0

let lbPage = mkWatched(persist, "lbPage", 0)
let lbCurrentTable = mkWatched(persist, "lbCurrentTable", null)
let isLbWndOpened = mkWatched(persist, "isLbWndOpened", false)
let isRefreshLbEnabled = mkWatched(persist, "isRefreshLbEnabled", false)

let lbPlayersCount = Computed(function() {
  if (curLbData.value == null)
    return 0
  let { total = 0 } = curLbData.value.findvalue(@(val) "$" in val)?["$"]
  return total > 0 ? total : curLbData.value.len()
})

let curLbPlacement = Computed(function(){
  if (curLbData.value == null)
    return -1
  return (curLbData.value.findindex(@(val) (val?.self)) ?? -1)
})

let curSeasons = Computed(function() {
  let res = {}
  foreach (mode in lbStatsModes.value)
    res[mode] <- userstatStats.value?.stats[lbCurrentTable.value?.mode]["$index"] ?? 0
  return res
})

let curLbIdx = Computed(@() (curSeasons.value?[lbCurrentTable.value?.mode] ?? 0))
let hasLbHistory = Computed(@() curLbIdx.value == 0
  || (selEvent.value?.leaderboardTableIdx ?? curLbIdx.value) < curLbIdx.value)

let requestDataInternal = keepref(Computed(function() {
  let reqData = lbCurrentTable.value
  let reqMode = reqData?.mode
  let reqSort = reqData?.sortCategory.field
  if (reqMode == null || reqSort == null
      || userInfo.value?.token == null
      || appId.value < 0
      || !lbStatsModes.value.contains(reqMode))
    return null

  let newData =  {
    appid = appId.value
    category = reqSort
    gameMode = reqMode
    count = LB_PAGE_ROWS
    start = lbPage.value * LB_PAGE_ROWS
    resolveNick = 1
    group = ""
    table = reqMode
    platformFilter = separateLeaderboardPlatformName.value
  }
  if (hasLbHistory.value)
    newData.__update({ history = 1 })

  return newData
}))

requestDataInternal.subscribe(setLbRequestData)
setLbRequestData(requestDataInternal.value)

curLbData.subscribe(function(v) {
  if (v != null && curLbSelfRow.value == null)
    requestSelfRow()
})

let lbCatByGroup = {
  unknown = {
    full = [
      RANK, NAME, BATTLE_RATING, SCORE, BATTLES, VICTORIES_PERCENT,
      KILLS_USING_AIRCRAFT, KILLS_USING_TANK, KILL_DEATH_RATIO, KILLS, BATTLE_TIME,
      BATTLE_RATING_PENALTY
    ]
    best = [TIME_AFTER_BATTLE, BATTLE_RATING, VICTORY_BOOL, SCORE, KILLS, BATTLE_TIME]
    short = [RANK, NAME, BATTLE_RATING]
    sortBy = BATTLE_RATING
  }
  new_year_tournament = {
    full = [
      RANK, NAME, TOURNAMENT_BATTLE_RATING, BATTLE_GROUP_SCORE, SCORE,
      VICTORIES_PERCENT, BATTLES, KILLS_USING_AIRCRAFT, KILLS_USING_TANK, KILLS, BATTLE_TIME
    ]
    best = [TIME_AFTER_BATTLE, TOURNAMENT_BATTLE_RATING, VICTORY_BOOL, SCORE, KILLS, BATTLE_TIME]
    short = [RANK, NAME, TOURNAMENT_BATTLE_RATING]
    sortBy = TOURNAMENT_BATTLE_RATING
  }
}

let getCategoriesByGroup = @(mode) lbCatByGroup?[mode] ?? lbCatByGroup.unknown

let lbSelCategories = Computed(@() getCategoriesByGroup(selLbMode.value))

let updateLbMode = function(_) {
  lbCurrentTable({
    mode = selLbMode.value
    sortCategory = lbSelCategories.value?.sortBy
  })
}

foreach (v in [selLbMode, lbSelCategories])
  v.subscribe(updateLbMode)

updateLbMode(selLbMode.value)

let ratingBattlesCountByMode = Computed(function() {
  let res = {}
  foreach (mode in eventGameModes.value) {
    let modeId = mode?.queue.extraParams.leaderboardTables[0]
    if (modeId != null)
      res[modeId] <- userstatStats.value?.stats[modeId]["ratingSessions"] ?? 0
  }
  return res
})

let bestBattlesByMode = Computed(function() {
  let res = {}
  foreach (mode in eventGameModes.value) {
    let modeId = mode?.queue.extraParams.leaderboardTables[0]
    if (modeId == null)
      continue
    let battles = userstatStats.value?.stats[modeId]["$sessions"] ?? []
    if (battles.len() > 0)
      res[modeId] <- battles
  }
  return res
})

let function updateRefreshTimer() {
  if (isRefreshLbEnabled.value) {
    refreshLbData()
    gui_scene.setInterval(REFRESH_PERIOD, refreshLbData)
  }
  else
    gui_scene.clearTimer(refreshLbData)
}
updateRefreshTimer()
isRefreshLbEnabled.subscribe(@(_) updateRefreshTimer())

console_register_command(@() lbPage(lbPage.value + 1), "lb.page_next")
console_register_command(@() lbPage.value > 0 && lbPage(lbPage.value - 1), "lb.page_prev")

return {
  LB_PAGE_ROWS

  curLbData
  curLbSelfRow
  curLbErrName
  lbCurrentTable
  isLbWndOpened
  getCategoriesByGroup
  lbSelCategories
  curLbIdx
  curLbPlacement
  lbPlayersCount

  bestBattlesByMode
  ratingBattlesCountByMode
  hasLbHistory
  refreshLbData
  curLbRequestData
  isRefreshLbEnabled
  openLbWnd = @() isLbWndOpened(true)
}