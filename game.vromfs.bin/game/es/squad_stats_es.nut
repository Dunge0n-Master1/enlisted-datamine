import "%dngscripts/ecs.nut" as ecs
let logBR = require("%enlSqGlob/library_logs.nut").with_prefix("[BattleReward] ")
let { mkEventOnSquadStats, EventSquadMembersStats } = require("%enlSqGlob/sqevents.nut")
let {EventAnyEntityDied} = require("dasevents")
let { get_sync_time, INVALID_CONNECTION_ID, has_network } = require("net")
let {find_local_player} = require("%dngscripts/common_queries.nut")
let { isNoBotsMode } = require("%enlSqGlob/missionType.nut")
let { scoreSquads, scoreAlone} = require("%enlSqGlob/expScoringValues.nut")
let {server_send_net_sqevent} = require("ecs.netevent")
let calcSoldierScore = require("%scripts/game/utils/calcSoldierScore.nut")

let soldierStatsQuery = ecs.SqQuery("soldierStatsQuery", { comps_rw = [["soldierStats", ecs.TYPE_OBJECT]] })
let getMemberData = @(playerEid, guid) soldierStatsQuery(playerEid, @(_, comp) comp.soldierStats)[guid]

let getSoldierInfoQuery = ecs.SqQuery("getSoldierInfoQuery", { comps_ro = [["guid", ecs.TYPE_STRING], ["squad_member__playerEid", ecs.TYPE_EID]] })

let function onEntityDied(evt, _eid, _comp) {
  let victimEid = evt.victim

  let victim = getSoldierInfoQuery(victimEid, @(_, comp) comp) ?? {}
  let victimGuid = victim?.guid ?? ""
  let victimOwnerPlayer = victim?["squad_member__playerEid"]
  if (victimOwnerPlayer == null || victimGuid == "" || !ecs.g_entity_mgr.doesEntityExist(victimOwnerPlayer))
    return

  logBR("onMemberDied ", victimOwnerPlayer, victimGuid)
  let victimData = getMemberData(victimOwnerPlayer, victimGuid)
  if (victimData.spawnTime > 0) {
    victimData.time += get_sync_time() - victimData.spawnTime
    victimData.spawnTime = -1
  }
  victimData.previousLifeScore = calcSoldierScore(victimData, isNoBotsMode())
}

let function sendSquadStatsToPlayer(stats, playerEid, connid) {
  if (stats.len() == 0)
    return
  let connectionsToSend = has_network() ? connid
    : find_local_player() == playerEid ? playerEid
    : INVALID_CONNECTION_ID
  server_send_net_sqevent(playerEid, mkEventOnSquadStats({stats}), [connectionsToSend])
}

let scoringPlayerAwardsQuery = ecs.SqQuery("scoringPlayerAwardsQuery", {
  comps_ro=[
    ["possessed", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
    ["connid", ecs.TYPE_INT, INVALID_CONNECTION_ID],
    ["respawner__spawnScoreGainMultBySquad", ecs.TYPE_FLOAT_LIST],
  ],
  comps_rw=[
    ["respawner__spawnScore", ecs.TYPE_INT],
    ["scoring_player__kills", ecs.TYPE_INT],
    ["scoring_player__tankKills", ecs.TYPE_INT],
    ["scoring_player__planeKills", ecs.TYPE_INT],
    ["scoring_player__aiPlaneKills", ecs.TYPE_INT],
    ["scoring_player__captures", ecs.TYPE_FLOAT],
    ["scoring_player__assists", ecs.TYPE_INT],
    ["scoring_player__tankKillAssists", ecs.TYPE_INT],
    ["scoring_player__planeKillAssists", ecs.TYPE_INT],
    ["scoring_player__aiPlaneKillAssists", ecs.TYPE_INT],
    ["scoring_player__tankKillAssistsAsCrew", ecs.TYPE_FLOAT],
    ["scoring_player__planeKillAssistsAsCrew", ecs.TYPE_FLOAT],
    ["scoring_player__aiPlaneKillAssistsAsCrew", ecs.TYPE_FLOAT],
    ["scoring_player__attackKills", ecs.TYPE_INT],
    ["scoring_player__defenseKills", ecs.TYPE_INT],
    ["scoring_player__builtBarbwireActivations", ecs.TYPE_INT],
    ["scoring_player__builtStructures", ecs.TYPE_INT],
    ["scoring_player__builtGunKills", ecs.TYPE_INT],
    ["scoring_player__builtGunKillAssists", ecs.TYPE_INT],
    ["scoring_player__builtGunTankKills", ecs.TYPE_INT],
    ["scoring_player__builtGunTankKillAssists", ecs.TYPE_INT],
    ["scoring_player__builtGunPlaneKills", ecs.TYPE_INT],
    ["scoring_player__builtGunAiPlaneKills", ecs.TYPE_INT],
    ["scoring_player__builtGunPlaneKillAssists", ecs.TYPE_INT],
    ["scoring_player__builtGunAiPlaneKillAssists", ecs.TYPE_INT],
    ["scoring_player__builtCapzoneFortificationActivations", ecs.TYPE_INT],
    ["scoring_player__builtAmmoBoxRefills", ecs.TYPE_INT],
    ["scoring_player__builtMedBoxRefills", ecs.TYPE_INT],
    ["scoring_player__builtRallyPointUses", ecs.TYPE_INT],
    ["scoring_player__hostedOnSoldierSpawns", ecs.TYPE_INT],
    ["scoring_player__vehicleRepairs", ecs.TYPE_INT],
    ["scoring_player__vehicleExtinguishes", ecs.TYPE_INT],
    ["scoring_player__landings", ecs.TYPE_INT],
    ["scoring_player__reviveAssists", ecs.TYPE_INT],
    ["scoring_player__healAssists", ecs.TYPE_FLOAT],
    ["scoring_player__crewKillAssists", ecs.TYPE_FLOAT],
    ["scoring_player__crewTankKillAssists", ecs.TYPE_FLOAT],
    ["scoring_player__crewPlaneKillAssists", ecs.TYPE_FLOAT],
    ["scoring_player__crewAiPlaneKillAssists", ecs.TYPE_FLOAT],
    ["scoring_player__barrageBalloonDestructions", ecs.TYPE_INT],
    ["scoring_player__enemyBuiltFortificationDestructions", ecs.TYPE_INT],
    ["scoring_player__enemyBuiltGunDestructions", ecs.TYPE_INT],
    ["scoring_player__enemyBuiltUtilityDestructions", ecs.TYPE_INT],
    ["scoring_player__friendlyHits", ecs.TYPE_INT],
    ["scoring_player__friendlyKills", ecs.TYPE_INT],
    ["scoring_player__friendlyKillsSamePlayer2Add", ecs.TYPE_INT],
    ["scoring_player__friendlyKillsSamePlayer3Add", ecs.TYPE_INT],
    ["scoring_player__friendlyKillsSamePlayer4Add", ecs.TYPE_INT],
    ["scoring_player__friendlyKillsSamePlayer5AndMoreAdd", ecs.TYPE_INT],
    ["scoring_player__friendlyTankHits", ecs.TYPE_INT],
    ["scoring_player__friendlyTankKills", ecs.TYPE_INT],
    ["scoring_player__friendlyPlaneHits", ecs.TYPE_INT],
    ["scoring_player__friendlyPlaneKills", ecs.TYPE_INT],
    ["scoring_player__meleeKills", ecs.TYPE_INT],
    ["scoring_player__explosiveKills", ecs.TYPE_INT],
    ["scoring_player__longRangeKills", ecs.TYPE_INT],
    ["scoring_player__gunGameLevelup", ecs.TYPE_INT],
  ]
})

let getStatScore = @(stat, isNoBots) (isNoBots ? scoreAlone : scoreSquads)?[stat] ?? 0

let squadStatsFilter = {
  captures = true
  builtGunKills = true
  builtGunKillAssists = true
  builtGunTankKills = true
  builtGunTankKillAssists = true
  builtGunPlaneKills = true
  builtGunAiPlaneKills = true
  builtGunPlaneKillAssists = true
  builtGunAiPlaneKillAssists = true
  builtBarbwireActivations = true
  builtAmmoBoxRefills = true
  builtMedBoxRefills = true
  builtCapzoneFortificationActivations = true
  builtRallyPointUses = true
}

let function onSquadMembersStats(evt, _, __) {
  let awardsByPlayer = {}
  let awardsByGuid = {}
  let awardsByPlayerSquad = {}
  foreach (data in evt.data.list) {
    local {
      stat,
      playerEid = ecs.INVALID_ENTITY_ID,
      guid = "",
      eid = ecs.INVALID_ENTITY_ID,
      amount = 1,
      shouldOverride = false
    } = data

    if (eid != ecs.INVALID_ENTITY_ID) {
      let soldier = getSoldierInfoQuery(eid, @(_, comp) comp) ?? {}
      guid = soldier?.guid ?? ""
      playerEid = soldier?["squad_member__playerEid"] ?? ecs.INVALID_ENTITY_ID
    }

    if (!ecs.g_entity_mgr.doesEntityExist(playerEid) || guid == "")
      continue

    let mData = getMemberData(playerEid, guid)
    if (shouldOverride)
      mData[stat] = amount
    else
      mData[stat] += amount

    if (!(playerEid in awardsByPlayer))
      awardsByPlayer[playerEid] <- {}
    awardsByPlayer[playerEid][stat] <- (awardsByPlayer[playerEid]?[stat] ?? 0) + amount
    if (!(guid in awardsByGuid))
      awardsByGuid[guid] <- {}
    awardsByGuid[guid][stat] <- (awardsByGuid[guid]?[stat] ?? 0) + amount
    if (mData?.squadId != null) {
      if (!(playerEid in awardsByPlayerSquad))
        awardsByPlayerSquad[playerEid] <- {}
      if (!(mData.squadId in awardsByPlayerSquad[playerEid]))
        awardsByPlayerSquad[playerEid][mData.squadId] <- {}
      awardsByPlayerSquad[playerEid][mData.squadId][stat] <- (awardsByPlayerSquad[playerEid][mData.squadId]?[stat] ?? 0) + amount
    }
  }
  let isNoBots = isNoBotsMode()
  awardsByPlayer.each(@(playerStats, playerEid)
    scoringPlayerAwardsQuery.perform(playerEid, function(_,playerComps) {
      playerStats.each(function(increment, stat){
        let statCompName = $"scoring_player__{stat}"
        if (statCompName in playerComps)
          playerComps[statCompName] += increment
      })
      let playerSquadStats = (awardsByPlayerSquad?[playerEid] ?? {})
      playerSquadStats.each(function(stats, squadId) {
        stats.each(function(increment, stat){
          let squadSpawnScoreMult = playerComps.respawner__spawnScoreGainMultBySquad?[squadId] ?? 1.0
          let statScore = getStatScore(stat, isNoBots)
          if (statScore > 0 && increment > 0)
            playerComps.respawner__spawnScore += increment * statScore * squadSpawnScoreMult
        })
      })
      let personalStats = (getSoldierInfoQuery(playerComps.possessed, @(_, comp) awardsByGuid?[comp.guid]) ?? {})
      let squadStats = playerStats.filter(@(_, stat) stat in squadStatsFilter)
      let statsToSend = personalStats.__merge(squadStats) // override some personal with squad stats
        .map(@(val, stat) { amount = val, score = getStatScore(stat, isNoBots) })
      sendSquadStatsToPlayer(statsToSend, playerEid, playerComps.connid)
    }))
}

ecs.register_es("squad_stats_kills_es",
  {
    [EventAnyEntityDied] = onEntityDied,
    [EventSquadMembersStats] = onSquadMembersStats,
  },
  {},
  {tags="server"})
