require ecs
require app
require game.events_game
require enlisted.events_enlisted
require game.utils.team

def get_entity_squad_owner_player(eid)
  let squadEid = get_Eid(eid, "squad_member__squad") ?? INVALID_ENTITY_ID
  return get_Eid(squadEid, "squad__ownerPlayer") ?? INVALID_ENTITY_ID


[es(tag=server)]
def infantry_squad_wipeout_on_kill(evt : EventEntityDied; squad_member__squad : EntityId; team : int; isInVehicle : bool = false)
  let offenderPlayer = get_entity_squad_owner_player(evt.offender)
  if !offenderPlayer || isInVehicle
    return

  var offenderTeam = TEAM_UNASSIGNED
  query(offenderPlayer) <| $ [es] (team : int)
    offenderTeam = team

  if offenderTeam == TEAM_UNASSIGNED || is_teams_friendly(offenderTeam, team)
    return

  query(squad_member__squad) <| $ [es] (squad_wipeout__timeLimit : float;
                                        squad__numMembers : int;
                                        squad_wipeout__minSquadSize : int = 2;
                                        var squad_wipeout__offender : EntityId&;
                                        var squad_wipeout__firstKillTime : float&;
                                        var squad_wipeout__kills : int&)
    let time = get_sync_time()
    if ((squad__numMembers < squad_wipeout__minSquadSize)
      || (!!squad_wipeout__offender && squad_wipeout__offender != offenderPlayer)
      || (squad_wipeout__firstKillTime >= 0.0 && (time - squad_wipeout__firstKillTime) > squad_wipeout__timeLimit))
      return
    squad_wipeout__offender = offenderPlayer
    squad_wipeout__firstKillTime = squad_wipeout__firstKillTime >= 0.0 ? squad_wipeout__firstKillTime : time
    if ++squad_wipeout__kills == squad__numMembers
      sendEvent(offenderPlayer, [[EventOnPlayerWipedOutInfantrySquad]])
