import "%dngscripts/ecs.nut" as ecs
let {TEAM_UNASSIGNED} = require("team")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let getSoldierInfoFromCache = require("%scripts/game/es/soldier_info_cache.nut")
let {EventAnyEntityDied, EventOnPlayerMineVehicleKill, EventOnPlayerMineInfantryKill} = require("dasevents")
let {get_shell_template_by_shell_id} = require("dm")

let getTeamQuery = ecs.SqQuery("getTeamQuery", { comps_ro=[["team", ecs.TYPE_INT]] })

let mineVictimQuery = ecs.SqQuery("mineVictimQuery", { comps_ro = [
  ["human_anim__vehicleSelected", ecs.TYPE_EID, INVALID_ENTITY_ID],
  ["human" , ecs.TYPE_TAG, null],
  ["vehicle" , ecs.TYPE_TAG, null]
]})

let function checkMineKill(victimEid, shellId, offenderPlayerEid) {
  let shellTemplateName = get_shell_template_by_shell_id(shellId) ?? ""
  if (shellTemplateName == "")
    return
  let shellTemplate = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(shellTemplateName)
  let isMine = shellTemplate?.getCompValNullable("shell__mine") != null
  if (!isMine)
    return

  mineVictimQuery(victimEid, function(_, comp) {
    let victimIsInVehicle = comp["human_anim__vehicleSelected"] != INVALID_ENTITY_ID
    let victimIsVehicle = comp["vehicle"] != null
    let victimIsHuman = comp["human"] != null
    if (victimIsVehicle)
      ecs.g_entity_mgr.sendEvent(offenderPlayerEid, EventOnPlayerMineVehicleKill())
    else if (victimIsHuman && !victimIsInVehicle)
      ecs.g_entity_mgr.sendEvent(offenderPlayerEid, EventOnPlayerMineInfantryKill())
  })
}

ecs.register_es("notify_mine_kills",
  {[EventAnyEntityDied] = function(evt, _eid, _comp) {
    let { victim, offender, shellId } = evt
    let offenderPlayerEid = getSoldierInfoFromCache(offender)?.player ?? INVALID_ENTITY_ID
    if (offenderPlayerEid == INVALID_ENTITY_ID)
      return

    let victimTeam = getTeamQuery(victim, @(_, c) c.team) ?? TEAM_UNASSIGNED
    let killerTeam = getTeamQuery(offenderPlayerEid, @(_, c) c.team) ?? TEAM_UNASSIGNED

    if (victim == offender || victimTeam == TEAM_UNASSIGNED || is_teams_friendly(killerTeam, victimTeam))
      return
    checkMineKill(victim, shellId, offenderPlayerEid)
  }}, {}, {tags="server"})