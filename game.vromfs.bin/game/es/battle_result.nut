import "%dngscripts/ecs.nut" as ecs
let {TEAM_UNASSIGNED} = require("team")
let { mkEventOnBattleResult } = require("%enlSqGlob/sqevents.nut")
let logBR = require("%enlSqGlob/library_logs.nut").with_prefix("[BattleReward] ")
let {EventLevelLoaded} = require("gameevents")
let {EventTeamRoundResult, CmdGetBattleResult} = require("dasevents")
let isDedicated = require_optional("dedicated") != null
let { get_sync_time, INVALID_CONNECTION_ID } = require("net")
let sendToProfileServer = require("%scripts/game/utils/sendToProfileServer.nut")
let { INVALID_USER_ID } = require("matching.errors")
let { isDebugDebriefingMode } = require("%enlSqGlob/wipFeatures.nut")
let { calcExpReward, isBattleHeroMultApplied, shouldApplyBoosters } = !isDedicated && !isDebugDebriefingMode
  ? require("%scripts/game/utils/calcExpRewardSingle.nut")
  : require("%dedicated/calcExpReward.nut")
let { isNoBotsMode } = require("%enlSqGlob/missionType.nut")
let { getArmyExpBattleHeroMult } = require("%scripts/game/utils/battleHeroExpReward.nut")
let sendBqBattleResult = require("%scripts/game/utils/bq_send_Battle_result.nut")
let getSoldierStats = require("%scripts/game/utils/getSoldierStats.nut")
let calcBattleHeroes = require("%scripts/game/utils/calcBattleHeroes.nut")
let calcBattleHeroAwards = require("%scripts/game/utils/calcBattleHeroesAwards.nut")
let { scorePlayerInfoComps, scoringPlayerSoldiersStatsComps, scoringPlayerPlayerOnlyStatsComps,
  playerStatisticsFromComps } = require("%enlSqGlob/scoreTableStatistics.nut")
let calcScoringPlayerScore = require("%scripts/game/utils/calcPlayerScore.nut")
let { BattleResult } = require("%enlSqGlob/battleParams.nut")
let { server_broadcast_net_sqevent } = require("ecs.netevent")
let { getRank, advanceRank } = require("player_military_rank.nut")

let isResultSend = persist("isResultSend", @() { value = false })
let resultSendToProfile = persist("resultSendToProfile", @() {})
let resultSendToBq = persist("resultSendToBq", @() {})
let disconnectInfo = persist("disconnectInfo", @() {})
let boosterSentToProfile = persist("boosterSentToProfile", @() {})

let realPlayerQuery = ecs.SqQuery("realPlayerQuery", {
  comps_ro = [
    ["team", ecs.TYPE_INT, TEAM_UNASSIGNED],
    ["disconnected", ecs.TYPE_BOOL, false],
    ["scoring_player__isEnoughScoreForXpMultipliers", ecs.TYPE_BOOL, false],
    ["army", ecs.TYPE_STRING],
    ["armies", ecs.TYPE_OBJECT],
  ]
  comps_rq = ["player"],
  comps_no = ["playerIsBot"]
})
let squadStatQuery = ecs.SqQuery("squadStatQuery", { comps_ro = [["squadStats", ecs.TYPE_OBJECT]] })
let playerStatsQuery = ecs.SqQuery("playerStatsQuery", {
  comps_ro = [["team", ecs.TYPE_INT, TEAM_UNASSIGNED], ["player__wishAnyTeam", ecs.TYPE_BOOL, false]]
})
let setPlayerHeroQuery = ecs.SqQuery("setPlayerHeroQuery", { comps_rw = [["scoring_player__isBattleHero", ecs.TYPE_BOOL]] })
let playerInfoQuery = ecs.SqQuery("playerInfoQuery",
  { comps_ro = [
      ["name", ecs.TYPE_STRING, ""],
      ["decorators__nickFrame", ecs.TYPE_STRING],
      ["decorators__portrait", ecs.TYPE_STRING],
      ["userid", ecs.TYPE_UINT64, INVALID_USER_ID],
      ["scoring_player__battleTime", ecs.TYPE_FLOAT, 0.0],
      ["connid", ecs.TYPE_INT, INVALID_CONNECTION_ID],
    ]
  })
let scorePlayerInfoQuery = ecs.SqQuery("scorePlayerInfoQuery", {
  comps_ro = [
    ["scoring_player__battleTime", ecs.TYPE_FLOAT],
    ["scoring_player__battleTimeLastStartedAt", ecs.TYPE_FLOAT]
  ].extend(scorePlayerInfoComps, scoringPlayerPlayerOnlyStatsComps)
})
let playerAwardsQuery = ecs.SqQuery("playerAwardsQuery", { comps_ro = [["awards", ecs.TYPE_ARRAY]] })

let missionParamsQuery = ecs.SqQuery("missionParamsQuery", {
  comps_ro = [["mission_name", ecs.TYPE_STRING]]
})

let playerArmyQuery = ecs.SqQuery("playerArmyQuery",
  { comps_ro = [["army", ecs.TYPE_STRING], ["armies", ecs.TYPE_OBJECT]] })
let function getPlayerArmyInfo(playerEid) {
  local armyId = ""
  local armyData = {}
  playerArmyQuery(playerEid, function(_, comp) {
    armyId = comp.army
    armyData = comp.armies?[armyId].getAll() ?? {}
  })
  return { armyId, armyData }
}

let getArmyData = @(playerEid) getPlayerArmyInfo(playerEid).armyData

let sumScore = @(data) data.reduce(@(res, v) res + (v?.score ?? 0), 0)
let averageTime = @(data) data.len() > 0
  ? data.reduce(@(res, v) res + (v?.time ?? 0.0), 0.0) / data.len()
  : 0.0

let function getScoreForBattleHeroAwards(playerEid, team, playerSoldiers, armyData, isWinnerTeam) {
  let squads = (armyData?.squads ?? []).map(@(squad) {
    squadId = squad.squadId
    hasVehicle = squad?.curVehicle != null
    soldiers = (squad?.squad ?? []).map(function(soldier) {
      let soldierStat = playerSoldiers?[soldier?.guid ?? ""]
      return {
        kind = soldier?.sKind ?? ""
        guid = soldier?.guid ?? ""
        squadId = squad.squadId
        name = soldier?.name ?? ""
        surname = soldier?.surname ?? ""
        callname = soldier?.callname ?? ""
        time = soldierStat?.time ?? 0.0
        score = soldierStat?.awardScore ?? 0
        stats = soldierStat ?? {}
      }
    })
  })
  squads.each(function(squad) {
    squad.score <- sumScore(squad.soldiers)
    squad.averageTime <- averageTime(squad.soldiers)
  })
  return {
    eid = playerEid
    team
    squads
    isWinnerTeam
    score = sumScore(squads)
  }
}

let function getBattleHeroSoldierInfo(soldier, armyData) {
  let soldierData = armyData
    ?.squads.findvalue(@(s) s.squadId == soldier.squadId)
    ?.squad.findvalue(@(s) s.guid == soldier.guid)
  return {
    weapTemplates = soldierData?["human_weap__weapTemplates"]
    equipment = soldierData?.equipment
    gametemplate = soldierData?.gametemplate
  }
}

let function sendExpToProfileServer(playerEid, expReward) {
  if (playerEid in resultSendToProfile)
    return "Result already send"

  let params = {
    armyExp = expReward?.armyExp ?? 0
    squadsExp = expReward?.squadsExp ?? {}
    soldiersExp = expReward?.soldiersExp ?? {}
    battleInfo = {
      missionId = missionParamsQuery(@(_, comp) comp.mission_name) ?? ""
      result = expReward?.result ?? 0
      activity = expReward?.activity ?? 0.0
      playTimeSec = (expReward?.battleTimeSec ?? 0).tointeger()
    }
  }
  let errorStr = sendToProfileServer(playerEid, "reward_battle", params)
  if (errorStr == null) {
    resultSendToProfile[playerEid] <- true
    logBR($"Send player reward {playerEid}: {expReward?.armyExp ?? 0}")
  }
  return errorStr
}

let function sendBoostersApplied(playerEid, battleBoosters) {
  if (playerEid in boosterSentToProfile)
    return
  if (battleBoosters.len() == 0)
    return

  let err = sendToProfileServer(playerEid, "apply_booster_in_battle", { battleBoosters })
  boosterSentToProfile[playerEid] <- true
  if (err == null)
    logBR($"Boosters applied for player {playerEid}")
  else
    logBR($"Failed to apply boosters for player {playerEid}, reason: {err}")
}

let function getPlayerDebriefingAwards(playerEid, kills) {
  let playerAwards = playerAwardsQuery(playerEid, @(_, comp) comp.awards.getAll()) ?? []
  let awards = [{id="kill", value=kills}]

  let awardTable = {}
  foreach (award in playerAwards) {
    if (award.type in awardTable)
      awardTable[award.type].count++
    else
      awardTable[award.type] <- {count = 1}
  }
  foreach (awardName, award in awardTable)
    awards.append({id=awardName, value=award.count})

  return awards
}

let function markLocalHero(heroes, eid) {
  let res = clone heroes
  if (eid in res)
    res[eid] <- res?[eid].__merge({isLocalPlayer=true})
  return res
}

let function sendPlayerBattleResult(playerEid, squadStats, playerData, playerBattleResult, scoringPlayers, teamHeroes = {}, playerAwards = [], needSendToBq = false) {
  let { armyId, armyData } = getPlayerArmyInfo(playerEid)
  if (armyId == "" || armyData.len() == 0)
    // ignore bots and other data that cannot be applied to statistics
    return

  let {
    userid = INVALID_USER_ID,
    scoring_player__battleTime = 0.0,
    connid = INVALID_CONNECTION_ID } = playerInfoQuery(playerEid, @(_, c) c)
  if (userid == INVALID_USER_ID)
    logBR($"Unknown player {playerEid}")
  if (connid == INVALID_CONNECTION_ID)
    logBR($"Invalid connection of {playerEid}")

  let playerBattleHero = teamHeroes?[playerEid]
  let isBattleHero = playerBattleHero != null
  let dataToSend = {
    players = scoringPlayers.map(@(playerScore, eid) playerScore.__update({eid})).values(),
    stats = playerData,
    awards = getPlayerDebriefingAwards(playerEid, scoringPlayers?[playerEid]?["scoring_player__kills"] ?? 0)
    heroes = markLocalHero(teamHeroes, playerEid).values()
    battleHeroAwards = playerAwards
    isBattleHero
    battleHeroSoldier = playerBattleHero?.soldier.guid
    isArmyProgressLocked = armyData?.isArmyProgressLocked ?? false
  }

  let wasPlayerRank = getRank(userid)
  let playerRank = advanceRank(userid, !playerBattleResult?.isDeserter, playerBattleResult?.isWinner, isBattleHero)
  if (wasPlayerRank > 0 || playerRank > 0) {
    dataToSend.wasPlayerRank <- wasPlayerRank
    dataToSend.playerRank <- playerRank
  }

  let expReward = calcExpReward(squadStats, playerData, armyData, playerBattleResult, scoring_player__battleTime, playerAwards, playerBattleHero)
  if (expReward.len() == 0)
    logBR($"Player {playerEid} has no exp rewards.", playerData)
  else if (!isDedicated)
    dataToSend.expReward <- expReward
  else {
    let result = (playerBattleResult?.isDeserter ?? false) ? BattleResult.DESERTION
      : (playerBattleResult?.isWinner ?? false) ? BattleResult.WIN
      : BattleResult.DEFEAT
    let expRewardExt = {
      baseExp = expReward.baseExp
      armyExp = expReward.armyExp
      activity = expReward.activity
      battleTimeSec = (expReward?.battleTimeSec ?? 0).tointeger()
      squadsExp = expReward.squadsExp.map(@(s) s.exp).filter(@(exp) exp > 0)
      soldiersExp = expReward.soldiersExp.map(@(s) s.exp).filter(@(exp) exp > 0)
    }
    let errText = sendExpToProfileServer(playerEid, expRewardExt.__merge({ result }))
    if (errText != null)
      logBR($"Player {playerEid} no rewards error: {errText}")
    else
      dataToSend.expReward <- expReward
    if (needSendToBq && playerEid not in resultSendToBq) {
      sendBqBattleResult(userid, playerData, expRewardExt, armyData, armyId)
      resultSendToBq[playerEid] <- true
    }
  }

  server_broadcast_net_sqevent(mkEventOnBattleResult(dataToSend), [connid])

  if (expReward.len() > 0) {
    logBR($"Player {userid} reward (army = {armyId}), result = ", playerBattleResult,
      "\nexpReward: ", expReward, "\nsoldiersStats: ",
      playerData.map(@(s, guid) s.__merge({ exp = expReward?.soldiersExp[guid] ?? 0 })))
  }
}
let DESERTER_STATE = {
  isDeserter = true
  isFinished = false
  isWinner = false
}
let UNFINISHED_STATE = {
  isDeserter = false
  isFinished = false
  isWinner = false
}
let WIN_STATE = {
  isDeserter = false
  isFinished = true
  isWinner = true
}
let DEFEAT_STATE = {
  isDeserter = false
  isFinished = true
  isWinner = false
}

let getPlayerBattleState = @(state, time, realEnemyPlayerCount, realPlayerCount, realPlayerWithEnoughScoreCount, anyTeam)
  state.__merge({time, realEnemyPlayerCount, realPlayerCount, realPlayerWithEnoughScoreCount, anyTeam})

let function getPlayerScoreFromSquadStats(stats, isNoBots) {
  let playerScore = scoringPlayerSoldiersStatsComps.map(@(compInfo) [compInfo[0], 0]).totable()
  stats.each(function(soldier) {
    soldier.each(function(val, stat) {
      let scoringStat = $"scoring_player__{stat}"
      if (scoringStat in playerScore)
        playerScore[scoringStat] += val
    })
  })
  playerScore["scoring_player__score"] <- calcScoringPlayerScore(playerScore, isNoBots)
  return playerScore
}

let playersScoreTableOrder = @(a, b)
  b.score <=> a.score
  || b.battleTime <=> a.battleTime
  || b.eid <=> a.eid

let finalizeBattleTime = @(time, comp) comp.__merge({
  battleTime = comp["scoring_player__battleTime"] + (comp["scoring_player__battleTimeLastStartedAt"] >= 0.0 ? time - comp["scoring_player__battleTimeLastStartedAt"] : 0.0)
})

let getScoringPlayers = @(playersStats, isNoBots, time)
  playersStats.map(@(stats, eid)
    playerStatisticsFromComps(
      getPlayerScoreFromSquadStats(stats, isNoBots)
        .__merge(finalizeBattleTime(time, scorePlayerInfoQuery(eid, @(_, comp) comp) ?? {})) ))

let function getRealPlayerCountInfo() {
  local realPlayerCount = 0
  let realPlayerCountByTeam = {}
  local realPlayerWithEnoughScoreCount = 0
  realPlayerQuery(function(_, comp) {
    if (comp.team != TEAM_UNASSIGNED) {
      realPlayerCount++
      realPlayerCountByTeam[comp.team] <- (realPlayerCountByTeam?[comp.team] ?? 0) + 1
      if (comp.scoring_player__isEnoughScoreForXpMultipliers)
        realPlayerWithEnoughScoreCount++
    }
  })
  return {realPlayerCount, realPlayerCountByTeam, realPlayerWithEnoughScoreCount}
}

let isWinningTeam = @(team, evt)
  evt.isWon == (evt.team == team)

let function onRoundResult(evt, _eid, _comp) {
  if (isResultSend.value)
    return
  isResultSend.value = true

  let isNoBots = isNoBotsMode()

  local playersStats = getSoldierStats(isNoBots)
  let scoringPlayers = getScoringPlayers(playersStats, isNoBots, get_sync_time())
  playersStats = playersStats.map(@(soldiers, eid)
    {
      soldiers
    }.__merge(playerStatsQuery(eid, @(_, comp) {
      team = comp.team
      wishAnyTeam = comp.player__wishAnyTeam
    }) ?? {
      team = TEAM_UNASSIGNED
      wishAnyTeam = false
    })
  )
  let scoreDetailed = playersStats.map(@(playerData, eid)
    getScoreForBattleHeroAwards(eid, playerData.team, playerData.soldiers, getArmyData(eid), isWinningTeam(playerData.team, evt))
    .__merge({stats = scoringPlayers[eid]})
  )
  scoringPlayers.map(@(v, eid) {eid, battleTime = v.battleTime, score = v.score}).values()
    .sort(playersScoreTableOrder)
    .each(function(player, index) {
      scoreDetailed[player.eid].scoreIndex <- index
      scoringPlayers[player.eid].scoreIndex <- index
    })
  scoringPlayers.each(@(player, playerEid)
    player.isDeserter <- (disconnectInfo?[playerEid].isDeserter ?? false))
  let playersScoreIndex = scoreDetailed.map(@(v) v.scoreIndex)
  let {realPlayerCount, realPlayerCountByTeam, realPlayerWithEnoughScoreCount} = getRealPlayerCountInfo()
  let awards = isDedicated ? calcBattleHeroAwards(scoreDetailed) : {}
  let heroes = awards.map(@(playersAwards, team)
    calcBattleHeroes(playersAwards, playersScoreIndex, isWinningTeam(team, evt)))
  awards.each(@(teamAwards) teamAwards.each(function(playerAwards, playerEid) {
    let player = scoringPlayers?[playerEid] ?? {}
    player.awards <- playerAwards.map(@(a) a.award)
  }))
  heroes.each(@(teamHeroes) teamHeroes.each(function(hero) {
    let player = scoringPlayers?[hero.playerEid] ?? {}
    player.isBattleHero <- true
  }))
  heroes.each(@(teamHeroes) teamHeroes.each(function(hero) {
    setPlayerHeroQuery(hero.playerEid, @(_, comp) comp.scoring_player__isBattleHero = true)
    let pInfo = playerInfoQuery(hero.playerEid, @(_, comp) comp)
    hero.playerName <- pInfo?.name ?? ""
    hero.nickFrame <- pInfo?["decorators__nickFrame"] ?? ""
    hero.portrait <- pInfo?["decorators__portrait"] ?? ""
    hero.isFinished <- (disconnectInfo?[hero.playerEid].isFinished ?? true)
    hero.expMult <- isBattleHeroMultApplied(hero.isFinished, realPlayerCount, realPlayerWithEnoughScoreCount) ? getArmyExpBattleHeroMult(hero.awards, hero) : 1.0
    hero.soldier.__update(getBattleHeroSoldierInfo(hero.soldier, getArmyData(hero.playerEid)))
    hero.playerRank <- getRank(hero.playerEid)
    delete hero.playerEid
  }))
  let battleEndTime = get_sync_time()
  foreach (playerEid, playerData in playersStats) {
    let team = playerData.team
    let teamHeroes = heroes?[team] ?? {}
    let playerAwards = awards?[team]?[playerEid] ?? []
    let result = isWinningTeam(team, evt) ? WIN_STATE : DEFEAT_STATE
    let realEnemyPlayersCount = realPlayerCountByTeam.reduce(@(res, count, playersTeam) res + ((playersTeam != team) ? count : 0), 0)
    let wishAnyTeam = playerData?.wishAnyTeam
    local playerBattleResult = disconnectInfo?[playerEid] ?? getPlayerBattleState(result, battleEndTime, realEnemyPlayersCount, realPlayerCount, realPlayerWithEnoughScoreCount, wishAnyTeam)
    playerBattleResult = playerBattleResult.__merge({boostersApplied= playerEid in boosterSentToProfile})
    local squadStat = squadStatQuery.perform(playerEid, @(_, comp) comp.squadStats)
    sendPlayerBattleResult(playerEid, squadStat, playerData.soldiers, playerBattleResult, scoringPlayers, teamHeroes, playerAwards, true/*needSendToBq*/)
  }
}

let function onGetBattleResult(_evt, eid, comp) {
  let isNoBots = isNoBotsMode()
  let playersStats = getSoldierStats(isNoBots)
  let currentTime = get_sync_time()
  let scoringPlayers = getScoringPlayers(playersStats, isNoBots, currentTime)
  scoringPlayers.map(@(v, eid) {eid, battleTime = v.battleTime, score = v.score}).values()
    .sort(playersScoreTableOrder)
    .each(function(player, index) { scoringPlayers[player.eid].scoreIndex <- index })
  let playerData = playersStats[eid]
  let isDeserter = !comp["scoring_player__isGameFinished"]
  let result = isDeserter ? DESERTER_STATE : UNFINISHED_STATE
  let {realPlayerCount, realPlayerCountByTeam, realPlayerWithEnoughScoreCount} = getRealPlayerCountInfo()
  let realEnemyPlayersCount = realPlayerCountByTeam.reduce(@(res, count, playersTeam) res + ((playersTeam != comp.team) ? count : 0), 0)
  let wishAnyTeam = comp.player__wishAnyTeam
  local playerBattleState = getPlayerBattleState(result, currentTime, realEnemyPlayersCount, realPlayerCount, realPlayerWithEnoughScoreCount, wishAnyTeam)
  scoringPlayers.each(@(player, playerEid)
    player.isDeserter <- playerEid == eid ? isDeserter : (disconnectInfo?[playerEid].isDeserter ?? false) )
  disconnectInfo[eid] <- playerBattleState
  playerBattleState = playerBattleState.__merge({boostersApplied = eid in boosterSentToProfile})
  sendPlayerBattleResult(eid, comp.squadStats, playerData, playerBattleState, scoringPlayers)
}

let function onDisconnectChange(_evt, eid, comp) {
  if (!comp.disconnected) {
    if (eid in disconnectInfo)
      delete disconnectInfo[eid]
    return
  }
  let result = !comp["scoring_player__isGameFinished"] ? DESERTER_STATE : UNFINISHED_STATE
  let {realPlayerCount, realPlayerCountByTeam, realPlayerWithEnoughScoreCount} = getRealPlayerCountInfo()
  let realEnemyPlayersCount = realPlayerCountByTeam.reduce(@(res, count, playersTeam) res + ((playersTeam != comp.team) ? count : 0), 0)
  let wishAnyTeam = comp.player__wishAnyTeam
  disconnectInfo[eid] <- getPlayerBattleState(result, get_sync_time(), realEnemyPlayersCount, realPlayerCount, realPlayerWithEnoughScoreCount, wishAnyTeam)
}

let function onLevelLoaded(_evt, _eid, _comp) {
  isResultSend.value = false
  resultSendToProfile.clear()
  resultSendToBq.clear()
  disconnectInfo.clear()
}

ecs.register_es("send_battle_result_es",
  { [EventTeamRoundResult] = onRoundResult }, {}, {tags="server"}) //EventTeamRoundResult is a broadcast

ecs.register_es("get_battle_result_es",
  {
    [CmdGetBattleResult] = onGetBattleResult,
    onChange = onDisconnectChange,
  },
  {
    comps_track = [["disconnected", ecs.TYPE_BOOL]],
    comps_ro = [
      ["scoring_player__isGameFinished", ecs.TYPE_BOOL, false],
      ["team", ecs.TYPE_INT],
      ["player__wishAnyTeam", ecs.TYPE_BOOL, false],
      ["squadStats", ecs.TYPE_OBJECT],
    ]
    comps_rq = ["player"],
  },
  {tags="server"})

ecs.register_es("battle_result_on_level_load_es", {
  [EventLevelLoaded] = onLevelLoaded
}, {})

ecs.register_es("battle_result_try_apply_boosters", {
  [["onInit", "onChange"]] = function(...) {
    let {realPlayerCount, realPlayerWithEnoughScoreCount} = getRealPlayerCountInfo()
    if (shouldApplyBoosters(realPlayerCount, realPlayerWithEnoughScoreCount))
      realPlayerQuery(function(eid, comp) {
        if (!comp.disconnected) {
          let army = comp.armies?[comp.army] ?? {}
          let boosters = army?.boosters.getAll().map(@(b) b.guid) ?? []
          sendBoostersApplied(eid, boosters)
        }
      })
  }
}, {
  comps_track = [
    ["disconnected", ecs.TYPE_BOOL],
    ["armiesReceivedTime", ecs.TYPE_FLOAT],
    ["scoring_player__isEnoughScoreForXpMultipliers", ecs.TYPE_BOOL]
  ],
  comps_rq = ["player"],
  comps_no = ["playerIsBot"]
}, {tags="server"})
