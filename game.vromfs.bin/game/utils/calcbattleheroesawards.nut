let { isNoBotsMode, getMissionType } = require("%enlSqGlob/missionType.nut")
let {
  BattleHeroesAward, requiredScoreTable, requiredValueTable, requiredSoldierKindScoreTable, getAwardBySoldierKind,
  awardScoreStats, tacticianStats, isBigAward, WINNING_TEAM_BATTLE_HEROES_COUNT, LOSING_TEAM_BATTLE_HEROES_COUNT
} = require("%enlSqGlob/ui/battleHeroesAwards.nut")
let { logerr } = require("dagor.debug")
let calcSoldierScore = require("%scripts/game/utils/calcSoldierScore.nut")

let getTop = @(comparator)
  @(data) data.filter(@(v) v != null).reduce(@(a, b) comparator(a, b) > 0 ? a : b)

let getTopScorePlayer = getTop(@(a,b) b.scoreIndex <=> a.scoreIndex)
let getTopScoreSoldier = getTop(@(a,b) a.score <=> b.score || a.time <=> b.time)
let getTopScoreSquad = getTop(@(a,b) a.score <=> b.score || b.playerScore <=> a.playerScore || a.averageTime <=> b.averageTime)
let getTopStatPlayer = getTop(@(a,b) a.stat <=> b.stat || b.player.scoreIndex <=> a.player.scoreIndex)
let getTopStatSoldier = getTop(@(a,b) a.stat <=> b.stat || a.soldier.score <=> b.soldier.score)

let statAwardConfig = {
  [BattleHeroesAward.TOP_VEHICLES_DESTROYED] = {
    playerStat = @(player) (player.stats?["scoring_player__tankKills"] ?? 0) + (player.stats?["scoring_player__planeKills"] ?? 0)
    soldierStat = @(soldier) (soldier.stats?["tankKills"] ?? 0) + (soldier.stats?["planeKills"] ?? 0)
  },
  [BattleHeroesAward.TOP_MELEE_KILLS] = {
    playerStat = @(player) (player.stats?["scoring_player__meleeKills"] ?? 0)
    soldierStat = @(soldier) (soldier.stats?["meleeKills"] ?? 0)
  },
  [BattleHeroesAward.TOP_GRENADE_KILLS] = {
    playerStat = @(player) (player.stats?["scoring_player__explosiveKills"] ?? 0)
    soldierStat = @(soldier) (soldier.stats?["explosiveKills"] ?? 0)
  },
  [BattleHeroesAward.TOP_LONG_RANGE_KILLS] = {
    playerStat = @(player) (player.stats?["scoring_player__longRangeKills"] ?? 0)
    soldierStat = @(soldier) (soldier.stats?["longRangeKills"] ?? 0)
  },
}

let function groupBy(data, field) {
  let res = {}
  foreach (v in data) {
    let key = v?[field]
    if (key != null)
      res[key] <- (res?[key] ?? []).append(v)
  }
  return res
}

let getSquads = @(data) data.reduce(@(res, player) res.extend(
  player.squads.map(@(squad) {playerEid = player.eid, playerScore = player.score, team = player.team, squad, averageTime = squad.averageTime, score = squad.score})
), [])

let function getTopScoreSoldierOfPlayer(player) {
  let topSoldier = getTopScoreSoldier(player.squads.map(@(squad) getTopScoreSoldier(squad.soldiers)))
  return {
    soldier = topSoldier
    score = topSoldier.score
    playerEid = player.eid
    team = player.team
  }
}

let getTopSoldierPerTeam = @(playersScore) groupBy(playersScore, "team")
  .map(getTopScorePlayer)
  .map(getTopScoreSoldierOfPlayer)
  .values()

let getSquadAwardInfo = @(data) {
 playerEid = data.playerEid,
 team = data.team,
 squadId = data.squad.squadId,
 score = data.score,
 soldier = getTopScoreSoldier(data.squad.soldiers)
}

let getRequiredValueForReward = @(award) requiredValueTable?[award] ?? 0

let getPlayerForAward = @(players, award, awardConfig)
  getTopStatPlayer(players
    .map(@(player) { stat = awardConfig.playerStat(player), player })
    .filter(@(player) player.stat >= getRequiredValueForReward(award))
  )?.player

let function getSoldierOfPlayerForAward(player, awardConfig) {
  let topSoldier = getTopStatSoldier(player.squads.map(@(squad)
    getTopStatSoldier(squad.soldiers.map(@(soldier)
      { stat = awardConfig.soldierStat(soldier), soldier }))))
  return {
    soldier = topSoldier.soldier
    score = topSoldier.soldier.score
    playerEid = player.eid
    team = player.team
  }
}

let function getRequiredScoreForReward(award = null) {
  let requiredScore = requiredScoreTable?[award] ?? requiredSoldierKindScoreTable
  local missionType = getMissionType()
  if (missionType not in requiredScore) {
    logerr($"Battle Heroes reward requirement for mission type {missionType} not found")
    missionType = "no_mode"
  }
  return requiredScore[missionType][isNoBotsMode() ? "noBots" : "withBots"]
}

let compareSoldiersOfSameKind = @(a,b)
  a.score <=> b.score
  || a.playerScore <=> b.playerScore
  || a.soldier.time <=> b.soldier.time

let function getTopSoldierPerKind(detailedPlayersScore) {
  let res = {}
  foreach (player in detailedPlayersScore)
    foreach (squad in player.squads)
      foreach (soldier in squad.soldiers) {
        let { kind, score } = soldier
        if (kind not in res || compareSoldiersOfSameKind({score, playerScore=player.score, soldier}, res[kind]) > 0)
          res[kind] <- {playerEid=player.eid, playerScore=player.score, soldier, team=player.team, score}
      }
  return res
}

let getPlayerStatSum = @(player, stats)
  stats.map(@(stat) player.stats?[stat] ?? 0.0).reduce(@(a,b) a + b, 0) ?? 0

let function getTacticianAward(players, awards) {
  let award = BattleHeroesAward.TACTICIAN
  let { statsA, requiredA, statsB, requiredB, statsA2, requiredA2 } = tacticianStats
  let awardCompetitors = players
    .filter(@(player) player.isWinnerTeam)
    .map(function(player) {
      return {
        statA = getPlayerStatSum(player, statsA)
        statB = getPlayerStatSum(player, statsB)
        player
      }
    })
  local awardCompetitorsStatA = awardCompetitors.filter(@(competitor) competitor.statA >= requiredA)
  if (awardCompetitorsStatA.len() == 0) {
    awardCompetitors.each(@(competitor) competitor.statA = getPlayerStatSum(competitor.player, statsA2))
    awardCompetitorsStatA = awardCompetitors.filter(@(competitor) competitor.statA >= requiredA2)
  }
  local awardedPlayerStatA = getTop(@(a,b) a.statA <=> b.statA || a.statB <=> b.statB || b.player.scoreIndex <=> a.player.scoreIndex)(awardCompetitorsStatA)?.player
  let awardCompetitorsStatB = awardCompetitors.filter(@(competitor) competitor.statB >= requiredB)
  local awardedPlayerStatB = getTop(@(a,b) a.statB <=> b.statB || a.statA <=> b.statA || b.player.scoreIndex <=> a.player.scoreIndex)(awardCompetitorsStatB)?.player

  local awardedPlayer = null
  if (awardedPlayerStatA == awardedPlayerStatB && awardedPlayerStatA != null) {
    awardedPlayer = awardedPlayerStatA
  } else {
    if (awardedPlayerStatA != null && awards.findvalue(@(award) award.playerEid == awardedPlayerStatA.eid) != null)
      awardedPlayerStatA = null
    if (awardedPlayerStatB != null && awards.findvalue(@(award) award.playerEid == awardedPlayerStatB.eid) != null)
      awardedPlayerStatB = null
    awardedPlayer = getTopScorePlayer([awardedPlayerStatA, awardedPlayerStatB])
  }
  if (awardedPlayer == null)
    return null
  return getSoldierOfPlayerForAward(awardedPlayer, {
    soldierStat = @(soldier) calcSoldierScore(soldier.stats.filter(@(_, key) key in awardScoreStats[award]), isNoBotsMode())
  }).__merge({award})
}

let function getUniversalAwards(players, awards) {
  let awardedPlayers = awards.reduce(function(res, award) {
    res[award.playerEid] <- true
    return res
  }, {})
  let bigAwards = awards.filter(@(a) isBigAward(a.award))
  let bigAwardCountByTeam = groupBy(bigAwards, "team").map(@(teamBigAwards) groupBy(teamBigAwards,"playerEid").len())
  return groupBy(players, "team").map(function(teamPlayers, team) {
    teamPlayers.sort(@(a,b) a.scoreIndex <=> b.scoreIndex)
    local universalPlayer = teamPlayers
      .slice(1, 3) // 2nd and 3rd place
      .filter(@(player, index) index <= (player.isWinnerTeam ? 1 : 0)) // 2nd place only in defeated team
      .filter(@(player) player.eid not in awardedPlayers)
      .filter(@(player) teamPlayers.findvalue(@(anotherPlayer)
        anotherPlayer.scoreIndex > player.scoreIndex && anotherPlayer.eid in awardedPlayers) != null)
      .filter(@(player)
        bigAwardCountByTeam[team] < (player.isWinnerTeam ? WINNING_TEAM_BATTLE_HEROES_COUNT : LOSING_TEAM_BATTLE_HEROES_COUNT))
    universalPlayer = universalPlayer?[0]
    return universalPlayer != null ? getTopScoreSoldierOfPlayer(universalPlayer).__merge({award=BattleHeroesAward.UNIVERSAL}) : null
  }).values().filter(@(a) a != null)
}

let function sanitize(award) {
  if (award?.soldier.stats != null)
    delete award.soldier.stats
}

let function calcBattleHeroAwards(detailedPlayersScore) {
  let requiredTopScore = getRequiredScoreForReward(BattleHeroesAward.TOP_PLACE)
  let requiredVehicleSquadScore = getRequiredScoreForReward(BattleHeroesAward.TOP_VEHICLE_SQUAD)
  let requiredInfantrySquadScore = getRequiredScoreForReward(BattleHeroesAward.TOP_INFANTRY_SQUAD)
  let requiredKindScore = getRequiredScoreForReward()

  let topSoldiersPerTeam = getTopSoldierPerTeam(detailedPlayersScore.filter(@(s) s.score >= requiredTopScore))
  let squads = getSquads(detailedPlayersScore)
  let topVehicleSquad = getTopScoreSquad(squads.filter(@(s) s.squad.hasVehicle && s.score >= requiredVehicleSquadScore))
  let topInfantrySquad = getTopScoreSquad(squads.filter(@(s) !s.squad.hasVehicle && s.score >= requiredInfantrySquadScore))
  let topSoldiersPerKind = getTopSoldierPerKind(detailedPlayersScore).filter(@(s) s.score >= requiredKindScore)

  let awards = topSoldiersPerTeam.map(@(v) v.__merge({award=BattleHeroesAward.TOP_PLACE}))
  if (topVehicleSquad != null)
    awards.append(getSquadAwardInfo(topVehicleSquad).__merge({award=BattleHeroesAward.TOP_VEHICLE_SQUAD}))
  if (topInfantrySquad != null)
    awards.append(getSquadAwardInfo(topInfantrySquad).__merge({award=BattleHeroesAward.TOP_INFANTRY_SQUAD}))
  awards.extend(
    topSoldiersPerKind.map(@(soldier, kind) soldier.__merge({award=getAwardBySoldierKind(kind)}))
    .values().filter(@(s) s?.award != null))
  foreach (award, awardConfig in statAwardConfig) {
    let awardedPlayer = getPlayerForAward(detailedPlayersScore, award, awardConfig)
    if (awardedPlayer != null)
      awards.append(getSoldierOfPlayerForAward(awardedPlayer, awardConfig).__merge({award}))
  }

  let tacticianAward = getTacticianAward(detailedPlayersScore, awards)
  if (tacticianAward != null)
    awards.append(tacticianAward)

  let universalAwards = getUniversalAwards(detailedPlayersScore, awards)
  awards.extend(universalAwards)

  awards.each(sanitize)
  return groupBy(awards, "team").map(@(teamAwards) groupBy(teamAwards, "playerEid"))
}

return calcBattleHeroAwards