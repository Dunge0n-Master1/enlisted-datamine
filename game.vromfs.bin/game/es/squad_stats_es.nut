import "%dngscripts/ecs.nut" as ecs
let logBR = require("%enlSqGlob/library_logs.nut").with_prefix("[BattleReward] ")
let { mkEventOnSquadStats, EventSquadMembersStats } = require("%enlSqGlob/sqevents.nut")
let {EventAnyEntityDied} = require("dasevents")
let {EventLevelLoaded} = require("gameevents")
let { get_sync_time, INVALID_CONNECTION_ID, has_network } = require("net")
let {find_local_player} = require("%dngscripts/common_queries.nut")
let { isNoBotsMode } = require("%enlSqGlob/missionType.nut")
let { scoreSquads, scoreAlone} = require("%enlSqGlob/expScoringValues.nut")
let {server_send_net_sqevent} = require("ecs.netevent")

// TODO: this need to be removed when EventSquadMembersStats is remade to send playerEid instead of squadEid.
// But for now we keep it to find player by squadEid even if squad entity is no longer exists.
let playersSquads = persist("playersSquads", @() {})

let newStats = @() {
  spawns = 0
  killed = 0 //suicide does not count
  kills = 0
  attackKills = 0
  defenseKills = 0
  tankKills = 0
  planeKills = 0
  assists = 0
  tankKillAssists = 0
  planeKillAssists = 0
  captures = 0.0 // float
  crewKillAssists = 0.0 // float
  crewTankKillAssists = 0.0 // float
  crewPlaneKillAssists = 0.0 // float
  tankKillAssistsAsCrew = 0.0 // float
  planeKillAssistsAsCrew = 0.0 // float
  builtStructures = 0
  builtGunKills = 0
  builtGunKillAssists = 0
  builtGunTankKills = 0
  builtGunTankKillAssists = 0
  builtGunPlaneKills = 0
  builtGunPlaneKillAssists = 0
  builtBarbwireActivations = 0
  builtCapzoneFortificationActivations = 0
  builtAmmoBoxRefills = 0
  builtMedBoxRefills = 0
  builtRallyPointUses = 0
  hostedOnSoldierSpawns = 0
  vehicleRepairs = 0
  vehicleExtinguishes = 0
  landings = 0
  reviveAssists = 0
  healAssists = 0.0
  barrageBalloonDestructions = 0
  enemyBuiltFortificationDestructions = 0
  enemyBuiltGunDestructions = 0
  enemyBuiltUtilityDestructions = 0
  friendlyHits = 0
  friendlyKills = 0
  friendlyKillsSamePlayer2Add = 0
  friendlyKillsSamePlayer3Add = 0
  friendlyKillsSamePlayer4Add = 0
  friendlyKillsSamePlayer5AndMoreAdd = 0
  friendlyTankHits = 0
  friendlyTankKills = 0
  friendlyPlaneHits = 0
  friendlyPlaneKills = 0
  meleeKills = 0
  explosiveKills = 0
  longRangeKills = 0
  gunGameLevelup = 0
  time = 0.0 // float
  spawnTime = -1.0 // float
  score = 0
}

let soldierStatsQuery = ecs.SqQuery("soldierStatsQuery", { comps_rw = [["soldierStats", ecs.TYPE_OBJECT]] })

let function getMemberData(playerEid, guid) {
  let stats = soldierStatsQuery(playerEid, @(_, comp) comp.soldierStats)
  if (stats == null)
    return newStats()
  if (!(guid in stats))
    stats[guid] <- newStats()
  return stats[guid]
}

let function listSquadPlayer(squadEid) {
  if (squadEid in playersSquads)
    return
  playersSquads[squadEid] <- ecs.obsolete_dbg_get_comp_val(squadEid, "squad__ownerPlayer") ?? ecs.INVALID_ENTITY_ID
}

let function onMemberCreated(_evt, _eid, comp) {
  let guid = comp["guid"]
  if (!guid || !guid.len())
    return

  listSquadPlayer(comp["squad_member__squad"])
  let data = getMemberData(comp["squad_member__playerEid"], guid)
  data.spawns++
  data.spawnTime = get_sync_time()
  logBR("onMemberCreated ", comp["squad_member__playerEid"], guid)
}

let getSoldierInfoQuery = ecs.SqQuery("getSoldierInfoQuery", { comps_ro = [["guid", ecs.TYPE_STRING], ["squad_member__playerEid", ecs.TYPE_EID]] })
let getSquadOwnerPlayerQuery = ecs.SqQuery("getSquadOwnerPlayerQuery", { comps_ro = [["squad__ownerPlayer", ecs.TYPE_EID]] })

let function onEntityDied(evt, _eid, _comp) {
  let victimEid = evt.victim

  let victim = getSoldierInfoQuery(victimEid, @(_, comp) comp) ?? {}
  let victimGuid = victim?.guid ?? ""
  let victimOwnerPlayer = victim?["squad_member__playerEid"]
  if (victimOwnerPlayer == null || victimGuid == "")
    return

  logBR("onMemberDied ", victimOwnerPlayer, victimGuid)
  let victimData = getMemberData(victimOwnerPlayer, victimGuid)
  if (victimData.spawnTime > 0) {
    victimData.time += get_sync_time() - victimData.spawnTime
    victimData.spawnTime = -1
  }
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
  ],
  comps_rw=[
    ["scoring_player__kills", ecs.TYPE_INT],
    ["scoring_player__tankKills", ecs.TYPE_INT],
    ["scoring_player__planeKills", ecs.TYPE_INT],
    ["scoring_player__captures", ecs.TYPE_FLOAT],
    ["scoring_player__assists", ecs.TYPE_INT],
    ["scoring_player__tankKillAssists", ecs.TYPE_INT],
    ["scoring_player__planeKillAssists", ecs.TYPE_INT],
    ["scoring_player__tankKillAssistsAsCrew", ecs.TYPE_FLOAT],
    ["scoring_player__planeKillAssistsAsCrew", ecs.TYPE_FLOAT],
    ["scoring_player__attackKills", ecs.TYPE_INT],
    ["scoring_player__defenseKills", ecs.TYPE_INT],
    ["scoring_player__builtBarbwireActivations", ecs.TYPE_INT],
    ["scoring_player__builtStructures", ecs.TYPE_INT],
    ["scoring_player__builtGunKills", ecs.TYPE_INT],
    ["scoring_player__builtGunKillAssists", ecs.TYPE_INT],
    ["scoring_player__builtGunTankKills", ecs.TYPE_INT],
    ["scoring_player__builtGunTankKillAssists", ecs.TYPE_INT],
    ["scoring_player__builtGunPlaneKills", ecs.TYPE_INT],
    ["scoring_player__builtGunPlaneKillAssists", ecs.TYPE_INT],
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

let getScore = @(stat, isNoBots) (isNoBots ? scoreAlone : scoreSquads)?[stat] ?? 0

let squadStatsFilter = {
  captures = true
  builtGunKills = true
  builtGunKillAssists = true
  builtGunTankKills = true
  builtGunTankKillAssists = true
  builtGunPlaneKills = true
  builtGunPlaneKillAssists = true
  builtBarbwireActivations = true
  builtAmmoBoxRefills = true
  builtMedBoxRefills = true
  builtCapzoneFortificationActivations = true
  builtRallyPointUses = true
}

let function onSquadMembersStats(evt, _, __) {
  let awardsByPlayer = {}
  let awardsByGuid = {}
  foreach (data in evt.data.list) {
    local { stat, playerEid = ecs.INVALID_ENTITY_ID, squadEid = ecs.INVALID_ENTITY_ID, guid = "", eid = ecs.INVALID_ENTITY_ID, amount = 1
    } = data

    if (eid != ecs.INVALID_ENTITY_ID) {
      let soldier = getSoldierInfoQuery(eid, @(_, comp) comp) ?? {}
      guid = soldier?.guid ?? ""
      playerEid = soldier?["squad_member__playerEid"] ?? ecs.INVALID_ENTITY_ID
    }
    playerEid = (playerEid != ecs.INVALID_ENTITY_ID)
      ? playerEid
      : playersSquads?[squadEid] ?? getSquadOwnerPlayerQuery(squadEid, @(_,comp) comp["squad__ownerPlayer"]) ?? ecs.INVALID_ENTITY_ID
    if (playerEid == ecs.INVALID_ENTITY_ID || guid == "")
      continue

    let mData = getMemberData(playerEid, guid)
    mData[stat] += amount

    if (!(playerEid in awardsByPlayer))
      awardsByPlayer[playerEid] <- {}
    awardsByPlayer[playerEid][stat] <- (awardsByPlayer[playerEid]?[stat] ?? 0) + amount
    if (!(guid in awardsByGuid))
      awardsByGuid[guid] <- {}
    awardsByGuid[guid][stat] <- (awardsByGuid[guid]?[stat] ?? 0) + amount
  }
  let isNoBots = isNoBotsMode()
  awardsByPlayer.each(@(playerStats, playerEid)
    scoringPlayerAwardsQuery.perform(playerEid, function(_,playerComps) {
      playerStats.each(function(increment, stat){
        let statCompName = $"scoring_player__{stat}"
        if (statCompName in playerComps)
          playerComps[statCompName] += increment
      })
      let personalStats = (getSoldierInfoQuery(playerComps.possessed, @(_, comp) awardsByGuid?[comp.guid]) ?? {})
      let squadStats = playerStats.filter(@(_, stat) stat in squadStatsFilter)
      let statsToSend = personalStats.__merge(squadStats) // override some personal with squad stats
        .map(@(val, stat) { amount = val, score = getScore(stat, isNoBots) })
      sendSquadStatsToPlayer(statsToSend, playerEid, playerComps.connid)
    }))
}

ecs.register_es("squad_stats_es",
  { [ecs.EventEntityCreated] = onMemberCreated },
  { comps_ro = [
      ["squad_member__squad", ecs.TYPE_EID],
      ["squad_member__playerEid", ecs.TYPE_EID],
      ["guid", ecs.TYPE_STRING],
    ]
  }, {tags="server"})

ecs.register_es("squad_stats_kills_es",
  {
    [EventAnyEntityDied] = onEntityDied,
    [EventSquadMembersStats] = onSquadMembersStats,
  },
  {},
  {tags="server"})

let function onLevelLoaded(_evt, _eid, _comp) {
  playersSquads.clear()
}

ecs.register_es("squad_stats_on_level_load_es", {
  [EventLevelLoaded] = onLevelLoaded
}, {})
