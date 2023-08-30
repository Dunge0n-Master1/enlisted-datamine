module component_filters shared

require ecs
require DngNet
require game.utils.team

enum PossessionResult
  NotControlled
  Controlled
  Unknown

def check_controlled(controlled_by, repl_to : int)
  if controlled_by == INVALID_CONNECTION_ID && repl_to == INVALID_CONNECTION_ID
    return PossessionResult Unknown
  return controlled_by == repl_to ? PossessionResult Controlled : PossessionResult NotControlled

def is_friendly_team_or(player_eid, entity_id : EntityId; default_value : bool)
  let playerTeam = get_int(player_eid, "team") ?? TEAM_UNASSIGNED
  let entityTeam = get_int(entity_id, "team")
  if entityTeam != null
    return is_teams_friendly(playerTeam, *entityTeam)

  //if there is no team in entity itself, check it's possessor (player) team
  let entityPlayerEid = get_Eid(entity_id, "possessedByPlr") ?? INVALID_ENTITY_ID
  if entityPlayerEid != INVALID_ENTITY_ID
    let entityPlayerTeam = get_int(entityPlayerEid, "team")
    if entityPlayerTeam != null
      return is_teams_friendly(playerTeam, *entityPlayerTeam)
  return default_value
