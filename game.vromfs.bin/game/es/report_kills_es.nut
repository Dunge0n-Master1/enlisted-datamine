import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *

let {TEAM_UNASSIGNED} = require("team")
let dm = require_optional("dm")
if (dm == null)
  return
let {get_gun_template_by_props_id, get_shell_template_by_shell_id} = dm
let {TMatrix} = require("dagor.math")
let getSoldierInfoFromCache = require("%scripts/game/es/soldier_info_cache.nut")

let {EventAnyEntityDied} = require("dasevents")
/*
todo:
  - remove killerPlayerEid, victimPlayerEid, killerSquad, victimSquad from native message as they are not needed anywhere except here and we can take them here manually
*/

let namePlayerQuery = ecs.SqQuery("namePlayerQuery", { comps_ro = [["name", ecs.TYPE_STRING]] })
let nameVehicleQuery = ecs.SqQuery("nameVehicleQuery", { comps_ro = [["item__name", ecs.TYPE_STRING]] })
let nameKillLogQuery = ecs.SqQuery("nameVehicleQuery", { comps_ro = [["killLogName", ecs.TYPE_STRING]] })

let function getName(playerEid, eid, isVehicle) {
  return playerEid ? namePlayerQuery(playerEid, @(_, c) c.name)
    : isVehicle ? nameVehicleQuery(eid, @(_, c) c["item__name"])
    : eid ? nameKillLogQuery(eid, @(_, c) c.killLogName)
    : null
}

let playerTable = @(eid, team, player_eid, vehicle, rank) {
  eid
  team
  player_eid
  name = getName(player_eid, eid, vehicle)
  vehicle
  rank
}

let squadQuery = ecs.SqQuery("squadQuery", {
  comps_ro = ["squad__isAlive", "squad__numAliveMembers", "squad__numMembers"]
})

let getTeamQuery = ecs.SqQuery("getTeamQuery", { comps_ro = [["team", ecs.TYPE_INT]] })

let victimQuery = ecs.SqQuery("victimReportQuery", {
  comps_ro = [
    ["reportKill", ecs.TYPE_BOOL, true],
    ["squad_member__squad", ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["vehicle", ecs.TYPE_TAG, null],
    ["airplane", ecs.TYPE_TAG, null],
    ["isTank", ecs.TYPE_TAG, null],
    ["isDowned", ecs.TYPE_BOOL, null],
    ["dm_parts__type", ecs.TYPE_STRING_LIST, null],
    ["transform", ecs.TYPE_MATRIX, null],
  ]
})

let killerQuery = ecs.SqQuery("killerReportQuery", {
  comps_ro = [
    ["vehicle", ecs.TYPE_TAG, null],
    ["transform", ecs.TYPE_MATRIX, null],
  ]
})

let rankQuery = ecs.SqQuery("playerRankQuery", {
  comps_ro = [["player_info__military_rank", ecs.TYPE_INT]]
})

let getSoldierPlayerRank = @(eid) rankQuery(eid, @(_, c) c?.player_info__military_rank)

let getItemNameFromTemplate = @(db, templateName)
  db.getTemplateByName(templateName ?? "")?.getCompValNullable("item__name")

let function getWeaponNameForReport(gunPropsId, shellId) {
  let gunTemplateName = get_gun_template_by_props_id(gunPropsId) ?? ""
  let shellTemplateName = get_shell_template_by_shell_id(shellId) ?? ""
  let db = ecs.g_entity_mgr.getTemplateDB()
  return getItemNameFromTemplate(db, gunTemplateName) ?? getItemNameFromTemplate(db, shellTemplateName)
}

let getScoreId = @(victim)
  victim?.airplane ? "planeKills"
    : victim?.isTank ? "tankKills"
    : "kills"

let function onEntityDied(evt, _eid, _comp) {
  let { damageType, gunPropsId, shellId, collNodeId } = evt
  let victimEid = evt.victim
  let killerEid = evt.offender

  let victim = victimQuery(victimEid, @(_, c) c) ?? {}
  if (!(victim?.reportKill ?? true))
    return

  let killer = killerQuery(killerEid, @(_, c) c) ?? {}
  let killerPlayerEid = getSoldierInfoFromCache(killerEid)?.player ?? INVALID_ENTITY_ID
  let victimPlayerEid = getSoldierInfoFromCache(victimEid)?.player ?? INVALID_ENTITY_ID
  let victimTeam = getTeamQuery(victimEid, @(_, c) c.team)
    ?? getTeamQuery(victimPlayerEid, @(_, c) c.team)
    ?? TEAM_UNASSIGNED
  let killerTeam = getTeamQuery(killerPlayerEid, @(_, comp) comp.team)
    ?? TEAM_UNASSIGNED

  if (victimTeam == TEAM_UNASSIGNED)
    return

  let isVictimVehicle = victim?.vehicle != null
  let isKillerVehicle = killer?.vehicle != null
  let victimRank = getSoldierPlayerRank(victimPlayerEid)
  let killerRank = getSoldierPlayerRank(killerPlayerEid)
  let nodeType = victim?["dm_parts__type"][collNodeId]
  let gunName = getWeaponNameForReport(gunPropsId, shellId)
  let victimSquadEid = victim?["squad_member__squad"] ?? INVALID_ENTITY_ID
  let lastInSquad = squadQuery(victimSquadEid, @(_, comp) comp["squad__numAliveMembers"]) < 2
  //FIXME! just died sodliers are still Alive. We need to store data in squad of list of alive soldiers or avoid semantic coupling other way

  ecs.server_msg_sink(ecs.event.EventKillReport({
    victim = playerTable(victimEid, victimTeam, victimPlayerEid, isVictimVehicle, victimRank).__update({
      isDowned = victim?.isDowned
      lastInSquad
      scoreId = getScoreId(victim)
    })
    killer = playerTable(killerEid, killerTeam, killerPlayerEid, isKillerVehicle, killerRank)
    nodeType
    damageType
    gunName
  }))


  let killerPos = (killer?.transform ?? TMatrix()).getcol(3)
  let victimPos = (victim?.transform ?? TMatrix()).getcol(3)
  log("player {0} ({1},{2},{3}) kills {4} ({5},{6},{7}) by {8} with {9} hit to {10}".subst(
    getName(killerPlayerEid, killerEid, isKillerVehicle),
    killerPos.x, killerPos.y, killerPos.z,
    getName(victimPlayerEid, victimEid, isVictimVehicle),
    victimPos.x, victimPos.y, victimPos.z,
    damageType, gunName, nodeType))
}

ecs.register_es("report_kill_es", {
  [EventAnyEntityDied] = onEntityDied,
}, {comps_rq = [ "msg_sink" ]}, {tags="server"})
