import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *

let dedicated = require_optional("dedicated")
if (dedicated == null)
  return

let {floor} = require("math")
let {TEAM_UNASSIGNED} = require("team")
let {get_matching_mode_info} = dedicated
let {EventTeamRoundResult} = require("dasevents")
let {EventLevelLoaded} = require("gameevents")
let {userstatsSend, userstatsFlush} = require("%scripts/game/utils/userstats.nut")
let {getPlayerCurrentUserstats} = require("%scripts/game/utils/getPlayerCurrentUserstats.nut")
let {INVALID_USER_ID} = require("matching.errors")

let isResultSend = persist("isResultSend", @() { value = false })
let resultSendToProfile = persist("resultSendToProfile", @() {})


let function sendToUserStats(userid, appId, armyId, stats) {
  if (stats.len() == 0)
    return
  let {extraParams=null, sessionId=null} = get_matching_mode_info()
  let userstatGroups = extraParams?.userstatGroups ?? []
  userstatGroups.each(@(userstatGroup)
    userstatsSend(userid, appId, stats, userstatGroup, sessionId))
  if (armyId != null)
    userstatsSend(userid, appId, stats, armyId, sessionId)
}

let function sendPlayerUserstats(comp, roundResult) {
  let userid = comp.userid
  let appId = comp.appId
  if (userid == INVALID_USER_ID)
    return
  assert(appId > 0)

  if (userid in resultSendToProfile) {
    log($"Userstat for {userid} already sent")
    return
  }
  resultSendToProfile[userid] <- true

  let stats = getPlayerCurrentUserstats(comp, roundResult)

  let platformUid = comp?.platformUid
  if (platformUid != null && platformUid != "")
    stats["$platformUid"] <- platformUid

  stats["$finalResult"] <- true
  sendToUserStats(userid, appId, comp.army, stats)
  userstatsFlush(userid)
}

let playerStatQuery = ecs.SqQuery("playerStatQuery", {
  comps_ro=[
    ["userid", ecs.TYPE_UINT64],
    ["platformUid", ecs.TYPE_STRING],
    ["groupId", ecs.TYPE_INT64, null],
    ["team", ecs.TYPE_INT, TEAM_UNASSIGNED],
    ["army", ecs.TYPE_STRING],
    ["userstats", ecs.TYPE_OBJECT, null],
    ["userstats__bestWeaponKillStreak", ecs.TYPE_OBJECT, null],
    ["scoring_player__bestPossessedInfantryKillstreak", ecs.TYPE_INT, 0],
    ["userstatsFilter", ecs.TYPE_SHARED_OBJECT, null],
    ["scoring_player__isGameFinished", ecs.TYPE_BOOL, true],
    ["scoring_player__kills", ecs.TYPE_INT, 0],
    ["scoring_player__killsByPlayer", ecs.TYPE_INT, 0],
    ["scoring_player__tankKills", ecs.TYPE_INT, 0],
    ["scoring_player__planeKills", ecs.TYPE_INT, 0],
    ["scoring_player__battleTime", ecs.TYPE_FLOAT, 0.0],
    ["scoring_player__soldierDeaths", ecs.TYPE_INT, 0],
    ["scoring_player__squadDeaths", ecs.TYPE_INT, 0],
    ["scoring_player__assists", ecs.TYPE_INT, 0],
    ["scoring_player__attackKills", ecs.TYPE_INT, 0],
    ["scoring_player__defenseKills", ecs.TYPE_INT, 0],
    ["scoring_player__builtAmmoBoxRefills", ecs.TYPE_INT, 0],
    ["scoring_player__builtRallyPointUses", ecs.TYPE_INT, 0],
    ["scoring_player__builtGunKills", ecs.TYPE_INT, 0],
    ["scoring_player__builtGunKillAssists", ecs.TYPE_INT, 0],
    ["scoring_player__builtGunTankKills", ecs.TYPE_INT, 0],
    ["scoring_player__builtGunTankKillAssists", ecs.TYPE_INT, 0],
    ["scoring_player__builtGunPlaneKills", ecs.TYPE_INT, 0],
    ["scoring_player__builtGunPlaneKillAssists", ecs.TYPE_INT, 0],
    ["scoring_player__builtBarbwireActivations", ecs.TYPE_INT, 0],
    ["scoring_player__builtCapzoneFortificationActivations", ecs.TYPE_INT, 0],
    ["scoring_player__enemyBuiltFortificationDestructions", ecs.TYPE_INT, 0],
    ["scoring_player__enemyBuiltGunDestructions", ecs.TYPE_INT, 0],
    ["scoring_player__enemyBuiltUtilityDestructions", ecs.TYPE_INT, 0],
    ["scoring_player__friendlyFirePenalty", ecs.TYPE_INT, 0],
    ["squads__spawnCount", ecs.TYPE_INT, 0],
    ["scoring_player__score", ecs.TYPE_INT, 0],
    ["scoring_player__isBattleHero", ecs.TYPE_BOOL, false],
    ["appId", ecs.TYPE_INT],
  ]
})

let playerScoreQuery = ecs.SqQuery("playerScoreQuery", {comps_ro=[["team", ecs.TYPE_INT, TEAM_UNASSIGNED],["scoring_player__score", ecs.TYPE_INT]]})

let indexByPercent = @(totalPlaces, percent) max(0, floor(totalPlaces * percent).tointeger() - 1)

let function collectScoreStats() {
  let scores = {}
  playerScoreQuery.perform(function(_eid, comp) {
    if (comp.team not in scores)
      scores[comp.team] <- []
    scores[comp.team].append(comp["scoring_player__score"])
  })
  return scores.map(function(teamScore) {
    teamScore.sort(@(a, b) b <=> a) // descending
    let totalPlaces = teamScore.len()
    return {
      team_score_top_1          = teamScore?[0] ?? 0
      team_score_top_20_percent = teamScore?[indexByPercent(totalPlaces, 0.2)] ?? 0
      team_score_top_30_percent = teamScore?[indexByPercent(totalPlaces, 0.3)] ?? 0
      team_score_top_50_percent = teamScore?[indexByPercent(totalPlaces, 0.5)] ?? 0
    }
  })
}

let function onRoundResult(evt, _, __) {
  if (isResultSend.value)
    return
  isResultSend.value = true

  let roundResult = { team = evt.team, isWon = evt.isWon, scoreStats = collectScoreStats() }
  playerStatQuery.perform(@(_, comp) sendPlayerUserstats(comp, roundResult))
}

ecs.register_es("send_userstats_es",
  { [EventTeamRoundResult] = onRoundResult }, {}, {tags="server", after="send_battle_result_es"}) //EventTeamRoundResult is a broadcast

ecs.register_es("user_stats_on_level_load_es", {
  [EventLevelLoaded] = function(...) {
    isResultSend.value = false
    resultSendToProfile.clear()
  }
}, {})
