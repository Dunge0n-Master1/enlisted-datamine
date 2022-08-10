from "%enlSqGlob/ui_library.nut" import *

let logRG = require("%enlSqGlob/library_logs.nut").with_prefix("[RateGame]")
let platform = require("%dngscripts/platform.nut")
let onlineSettings = require("%enlist/options/onlineSettings.nut")
let debriefingState = require("%enlist/debriefing/debriefingStateInMenu.nut")

let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let { armyStats } = require("%enlist/meta/servProfile.nut")


const ASKED_ID = "is_rate_asked"
const REQ_BATTLES_TO_RATE = 5
const MIN_BATTLE_TIME_TO_RATE = 300
const MIN_KILLS_TO_RATE = 2
const POS_FACTOR_TO_RATE = 4


let { request_review =  @(fn) fn(false) } = platform.is_xbox ? require("%xboxLib/impl/store.nut")
                                            : null

let function checkRate(_) {
  if (!onlineSettings.onlineSettingUpdated.value
      || onlineSettings.settings.value?[ASKED_ID]
      || isInBattleState.value
      || debriefingState.show.value
      || debriefingState.data.value == null)
    return

  let battlesCount = armyStats.value.reduce(@(res, val) res + val.battlesCount, 0)
  if (battlesCount < REQ_BATTLES_TO_RATE)
    return logRG($"not enough battles {battlesCount} / {REQ_BATTLES_TO_RATE}")

  let debData = debriefingState.data.value
  let hasWon = debData?.result.success ?? false
  if (!hasWon)
    return logRG("need win battle to display rate")

  let spentTime = debData?.result.time ?? 0
  if (spentTime < MIN_BATTLE_TIME_TO_RATE)
    return logRG($"not enough spent time {spentTime} / {MIN_BATTLE_TIME_TO_RATE}")

  let killsCount = (debData?.awards ?? [])
    .findvalue(@(award) award?.id == "kill")?.value ?? 0
  if (killsCount < MIN_KILLS_TO_RATE)
    return logRG($"not enough kills {killsCount} / {MIN_KILLS_TO_RATE}")

  let playerEid = debData?.localPlayerEid
  let playerTeam = debData?.myTeam
  if (playerEid == null || playerTeam == null)
    return logRG($"wrong player eid = {playerEid} or team = {playerTeam}")

  let players = debData?.players ?? {}
  let playerScore = players?[playerEid].score ?? 0
  let totalScores = players.filter(@(s) s?.team == playerTeam)
  let playerPosition = totalScores.filter(@(s) (s?.score ?? 0) > playerScore).len() + 1
  let minPositionToRate = max(totalScores.len() / POS_FACTOR_TO_RATE, 1)
  if (playerPosition > minPositionToRate)
    return logRG($"bad rating position {playerPosition}, should be among the first {minPositionToRate} players")

  request_review(function(succ) {
    if (succ) {
      onlineSettings.settings.mutate(@(s) s[ASKED_ID] <- true)
    }
  })
}

onlineSettings.onlineSettingUpdated.subscribe(function(val) {
  if (val)
    logRG(onlineSettings.settings.value?[ASKED_ID] ?? false
      ? "is already asked"
      : "not asked yet")
})

console_register_command(@() checkRate(null), "xbox.check_rate")
console_register_command(function() {onlineSettings.settings.mutate(@(s) s[ASKED_ID] <- false)}, "meta.resetSeenRateUs")

foreach (w in [isInBattleState, debriefingState.show, onlineSettings.onlineSettingUpdated, armyStats])
  w.subscribe(checkRate)
