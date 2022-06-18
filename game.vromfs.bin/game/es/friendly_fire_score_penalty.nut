import "%dngscripts/ecs.nut" as ecs
let {OnFriendlyFire, OnTeamKill} = require("dasevents")
let getSoldierInfoFromCache = require("%scripts/game/es/soldier_info_cache.nut")
let { isFriendlyFireMode } = require("%enlSqGlob/missionType.nut")
let logFF = require("%sqstd/log.nut")().with_prefix("[FriendlyFire] ")
let get_gun_template_by_props_id = require_optional("dm")?.get_gun_template_by_props_id ?? @(...) null
let { split_by_chars } = require("string")

let getPlayerNameQuery = ecs.SqQuery("getPlayerNameQuery", { comps_ro = [["name", ecs.TYPE_STRING]] })
let getSquadOwnerPlayerQuery = ecs.SqQuery("getSquadOwnerPlayerQuery", { comps_ro = [["squad__ownerPlayer", ecs.TYPE_EID]] })
let getPlayerKillCountQuery = ecs.SqQuery("getPlayerTeamkillRelapseQuery", { comps_rw = [["friendly_fire__playerKillCount", ecs.TYPE_OBJECT]] })
let getPlayerForgivableStatsQuery = ecs.SqQuery("getPlayerForgivableStatsQuery", { comps_rw = [["friendly_fire__forgivableStats", ecs.TYPE_OBJECT]] })

let getPlayerName = @(playerEid)
  getPlayerNameQuery(playerEid, @(_, comp) comp.name)

let getSquadOwnerPlayer = @(squadEid)
  getSquadOwnerPlayerQuery(squadEid, @(_, comp) comp["squad__ownerPlayer"]) ?? INVALID_ENTITY_ID

let function setForgivableStats(offenderPlayerEid, victimPlayerEid, statData) {
  getPlayerForgivableStatsQuery(victimPlayerEid, function(_, comp) {
    let offenderKey = offenderPlayerEid.tostring()
    if (offenderKey not in comp["friendly_fire__forgivableStats"])
      comp["friendly_fire__forgivableStats"][offenderKey] <- []
    let oldStats = comp["friendly_fire__forgivableStats"][offenderKey].getAll()
    comp["friendly_fire__forgivableStats"][offenderKey] <- oldStats.append(statData.__merge({ amount = -(statData?.amount ?? 1) }))
  })
}

let function addSoldierStat(offender, stat, victimPlayerEid, victimName, gunPropsId) {
  if (isFriendlyFireMode()) {
    let statData = { stat, playerEid=offender.player, guid=offender.guid }
    ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats({ list = [statData] }))
    setForgivableStats(offender.player, victimPlayerEid, statData)
    let offenderPlayerName = getPlayerName(offender.player)
    let victimPlayerName = getPlayerName(victimPlayerEid)
    let gunTplName = get_gun_template_by_props_id(gunPropsId)
    let gunName = split_by_chars(gunTplName ?? "", "+")?[0] ?? gunTplName
    logFF($"{offenderPlayerName}[{offender.player}] got penalty {stat} with weapon: {gunName}. Victim: {victimName} of player {victimPlayerName}[{victimPlayerEid}]")
  }
}

let samePlayerKillStats = [
  null
  "friendlyKillsSamePlayer2Add"
  "friendlyKillsSamePlayer3Add"
  "friendlyKillsSamePlayer4Add"
  "friendlyKillsSamePlayer5AndMoreAdd"
]

let function increaseSamePlayerKillCount(offender, victimPlayer) {
  let victimKey = victimPlayer.tostring()
  return getPlayerKillCountQuery(offender.player, function(_, comp) {
    comp["friendly_fire__playerKillCount"][victimKey] <- ((comp["friendly_fire__playerKillCount"]?[victimKey] ?? 0) + 1)
    return comp["friendly_fire__playerKillCount"][victimKey]
  }) ?? 1
}

let function onSoldierKill(offender, gunPropsId, comp) {
  let victimPlayer = comp["squad_member__playerEid"]
  addSoldierStat(offender, "friendlyKills", victimPlayer, comp.guid, gunPropsId)
  if (!comp.possessedByPlr)
    return
  let samePlayerKills = increaseSamePlayerKillCount(offender, victimPlayer)
  let samePlayerKillStat = samePlayerKillStats[clamp(samePlayerKills - 1, 0, samePlayerKillStats.len() - 1)]
  if (samePlayerKillStat != null)
    addSoldierStat(offender, samePlayerKillStat, victimPlayer, comp.guid, gunPropsId)
}

ecs.register_es("apply_team_kill_penalty_human",
  {[OnTeamKill] = @(evt, _, comp) onSoldierKill(getSoldierInfoFromCache(evt.offender), evt.gunPropsId, comp)},
  {comps_rq=["human"], comps_ro=[["guid", ecs.TYPE_STRING, ""], ["squad_member__playerEid", ecs.TYPE_EID, INVALID_ENTITY_ID], ["possessedByPlr", ecs.TYPE_EID, INVALID_ENTITY_ID]]},
  {tags="server"})

ecs.register_es("apply_team_kill_penalty_plane",
  {[OnTeamKill] = @(evt, _, comp) addSoldierStat(getSoldierInfoFromCache(evt.offender), "friendlyPlaneKills", getSquadOwnerPlayer(comp.ownedBySquad), comp.killLogName, evt.gunPropsId)},
  {comps_rq=["airplane"], comps_ro=[["killLogName", ecs.TYPE_STRING, ""], ["ownedBySquad", ecs.TYPE_EID, INVALID_ENTITY_ID]]},
  {tags="server"})

ecs.register_es("apply_team_kill_penalty_tank",
  {[OnTeamKill] = @(evt, _, comp) addSoldierStat(getSoldierInfoFromCache(evt.offender), "friendlyTankKills", getSquadOwnerPlayer(comp.ownedBySquad), comp.killLogName, evt.gunPropsId)},
  {comps_rq=["isTank"], comps_ro=[["killLogName", ecs.TYPE_STRING, ""], ["ownedBySquad", ecs.TYPE_EID, INVALID_ENTITY_ID]]},
  {tags="server"})

ecs.register_es("apply_friendly_fire_penalty_on_human_hit",
  {[OnFriendlyFire] = @(evt, _, comp) addSoldierStat(getSoldierInfoFromCache(evt.offender), "friendlyHits", comp["squad_member__playerEid"], comp.guid, evt.gunPropsId)},
  {comps_rq=["human"], comps_ro=[["guid", ecs.TYPE_STRING, ""], ["squad_member__playerEid", ecs.TYPE_EID, INVALID_ENTITY_ID]]},
  {tags="server"})

ecs.register_es("apply_friendly_fire_penalty_on_plane_damage",
  {[OnFriendlyFire] = @(evt, _, comp) addSoldierStat(getSoldierInfoFromCache(evt.offender), "friendlyPlaneHits", getSquadOwnerPlayer(comp.ownedBySquad), comp.killLogName, evt.gunPropsId)},
  {comps_rq=["airplane"], comps_ro=[["killLogName", ecs.TYPE_STRING, ""], ["ownedBySquad", ecs.TYPE_EID, INVALID_ENTITY_ID]]},
  {tags="server"})

ecs.register_es("apply_friendly_fire_penalty_on_tank_damage",
  {[OnFriendlyFire] = @(evt, _, comp) addSoldierStat(getSoldierInfoFromCache(evt.offender), "friendlyTankHits", getSquadOwnerPlayer(comp.ownedBySquad), comp.killLogName, evt.gunPropsId)},
  {comps_rq=["isTank"], comps_ro=[["killLogName", ecs.TYPE_STRING, ""], ["ownedBySquad", ecs.TYPE_EID, INVALID_ENTITY_ID]]},
  {tags="server"})


ecs.register_es("log_current_friendly_fire_penalty",
  { onChange = function(eid, comp) {
      let penalty = comp["scoring_player__friendlyFirePenalty"]
      let spawnCount = comp["squads__spawnCount"]
      logFF($"{comp.name}[{eid}] current penalty {penalty}. Spawn count: {spawnCount}")
    }
  },
  {comps_track = [["scoring_player__friendlyFirePenalty", ecs.TYPE_INT]],
   comps_ro = [["squads__spawnCount", ecs.TYPE_INT], ["name", ecs.TYPE_STRING]]
  },
  {tags="server"})