require ecs
require ecs.safe
require ecs.common
require game.utils.team
require game.events_game
require game.es.awards_common
require enlisted.game.es.offender_cache_common
require enlisted.events_enlisted
require DngDm
require strings

def send_shell_kill_stat_award(player : EntityId; stat : string; award : string)
  if !empty(stat)
    sendEvent(player, [[EventAddPlayerStat stat=stat]])
  if !empty(award)
    add_award(player, award)

def check_shell_kill(victim_eid : EntityId; shell_id : int; offender_player_eid : EntityId; offender_guid : string)
  let shellTemplateName = get_shell_template_by_shell_id(shell_id)
  if empty(shellTemplateName)
    return
  let shellTemplate = getTemplateByName(shellTemplateName)
  if shellTemplate == null
    return
  let vehicleStat = *shellTemplate |> getTemplateComponent("shell__vehicleKillStat") ?? ""
  let vehicleAward = *shellTemplate |> getTemplateComponent("shell__vehicleKillAward") ?? vehicleStat
  let infantryStat = *shellTemplate |> getTemplateComponent("shell__infantryKillStat") ?? ""
  let infantryAward = *shellTemplate |> getTemplateComponent("shell__infantryKillAward") ?? infantryStat
  let crewStat = *shellTemplate |> getTemplateComponent("shell__crewKillStat") ?? ""
  let crewAward = *shellTemplate |> getTemplateComponent("shell__crewKillAward") ?? crewStat
  let soldierStat = *shellTemplate |> getTemplateComponent("shell__killSoldierStat") ?? ""

  if (empty(vehicleStat) && empty(vehicleAward) &&
      empty(infantryStat) && empty(infantryAward) &&
      empty(crewStat) && empty(crewAward) && empty(soldierStat))
    return

  query(victim_eid) <| $ [es] (human_anim__vehicleSelected : EntityId = INVALID_ENTITY_ID;
                               human : Tag const?;
                               vehicle : Tag const?)
    let victimIsInVehicle = human_anim__vehicleSelected != INVALID_ENTITY_ID
    let victimIsVehicle = vehicle != null
    let victimIsHuman = human != null
    if victimIsVehicle
      send_shell_kill_stat_award(offender_player_eid, vehicleStat, vehicleAward)
    elif victimIsHuman && !victimIsInVehicle
      send_shell_kill_stat_award(offender_player_eid, infantryStat, infantryAward)
    elif victimIsHuman && victimIsInVehicle
      send_shell_kill_stat_award(offender_player_eid, crewStat, crewAward)

    if victimIsHuman && !empty(soldierStat)
      send_award_stat(offender_player_eid, offender_guid, soldierStat)

[es(tag=server)]
def notify_shell_kills(evt : EventAnyEntityDied) // broadcast
  let offender = get_offender_from_cache(evt.offender)
  let offenderPlayerEid = offender.player
  if !offenderPlayerEid
    return

  let victimTeam = get_int(evt.victim, "team") ?? TEAM_UNASSIGNED
  let killerTeam = get_int(offenderPlayerEid, "team") ?? TEAM_UNASSIGNED

  if evt.victim != evt.offender && victimTeam != TEAM_UNASSIGNED && !is_teams_friendly(killerTeam, victimTeam)
    check_shell_kill(evt.victim, evt.shellId, offenderPlayerEid, offender.guid)
