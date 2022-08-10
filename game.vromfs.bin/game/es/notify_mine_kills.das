require ecs
require game.utils.team
require game.events_game
require enlisted.game.es.offender_cache_common
require enlisted.events_enlisted
require EnlistedDm
require strings

def check_mine_kill(victim_eid : EntityId; shell_id : int; offender_player_eid : EntityId)
  let shellTemplateName = get_shell_template_by_shell_id(shell_id)
  if empty(shellTemplateName)
    return
  let shellTemplate = getTemplateByName(shellTemplateName)
  if shellTemplate == null
    return
  let isMine = !(*shellTemplate |> getTemplateComponent("shell__mine")).isNull
  if !isMine
    return

  query(victim_eid) <| $ [es] (human_anim__vehicleSelected : EntityId = INVALID_ENTITY_ID;
                               human : Tag?;
                               vehicle : Tag?)
    let victimIsInVehicle = human_anim__vehicleSelected != INVALID_ENTITY_ID
    let victimIsVehicle = vehicle != null
    let victimIsHuman = human != null
    if victimIsVehicle
      sendEvent(offender_player_eid, [[EventOnPlayerMineVehicleKill]])
    elif victimIsHuman && !victimIsInVehicle
      sendEvent(offender_player_eid, [[EventOnPlayerMineInfantryKill]])

[es(tag=server)]
def notify_mine_kills(evt : EventAnyEntityDied) // broadcast
  let offenderPlayerEid = get_offender_from_cache(evt.offender).player
  if !offenderPlayerEid
    return

  let victimTeam = get_int(evt.victim, "team") ?? TEAM_UNASSIGNED
  let killerTeam = get_int(offenderPlayerEid, "team") ?? TEAM_UNASSIGNED

  if evt.victim != evt.offender && victimTeam != TEAM_UNASSIGNED && !is_teams_friendly(killerTeam, victimTeam)
    check_mine_kill(evt.victim, evt.shellId, offenderPlayerEid)
