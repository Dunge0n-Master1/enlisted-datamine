require ecs
require game.es.events
require game.events_game
require game.utils.team
require enlisted.events_enlisted

def has_respawn_by_type(resp_team : int; resp_type : string)
  let hasRespawn = find_query() <| $ [es(REQUIRE=respbase)] (team : int; respawnbaseType : string)
    return (team == TEAM_UNASSIGNED || team == resp_team) && respawnbaseType == resp_type
  return hasRespawn

def can_spawn_soldiers(squad_idx : int; soldier_revive_points__points : Array)
  if length(soldier_revive_points__points) == 0
    return true
  if squad_idx < 0 || squad_idx >= length(soldier_revive_points__points)
    return false
  assume revive = *(get_ecs_array(soldier_revive_points__points[squad_idx]))
  if length(revive) == 0
    return true
  for i in iter_range(revive)
    let pts = *(get_int(revive[i]))
    if pts >= 100
      return true
  return false

[es(tag=server, REQUIRE=player, on_event=RequestCheckTeamSpawnDefeat)]
def check_team_spawn_defeat_es(evt : Event;
                               eid : EntityId;
                               soldier_revive_points__points : Array;
                               var squads__revivePointsList : IntList&)
  var checkTeam : int = TEAM_UNASSIGNED
  query(eid) <| $ [es] (team : int)
    checkTeam = team
  if (checkTeam == TEAM_UNASSIGNED)
    return

  for i, pts in iter_range(squads__revivePointsList), squads__revivePointsList
    if pts >= 100 && !can_spawn_soldiers(i, soldier_revive_points__points)
      pts = 0 // make squad unavailable if all soldiers are dead

  let noMoreSpawns = find_query() <| $ [es(REQUIRE=teamTag)] (team__id : int; team__noMoreSpawns : bool)
    return team__id == checkTeam && team__noMoreSpawns
  if noMoreSpawns
    return

  let isAnyAlive = find_query() <| $ [es(REQUIRE=squad_member__squad)] (isAlive : bool; team : int)
    return team == checkTeam && isAlive
  if isAnyAlive
    return

  let anyCanSpawn = find_query() <| $ [es(REQUIRE=player)] (team : int;
                                                            squads__respawnTypeList : Array;
                                                            squads__revivePointsList : IntList;
                                                            soldier_revive_points__points : Array)
    if team != checkTeam
      return false
    for i, pts in iter_range(squads__revivePointsList), squads__revivePointsList
      if pts < 100
        continue
      if !can_spawn_soldiers(i, soldier_revive_points__points)
        continue
      if i < length(squads__respawnTypeList) && !has_respawn_by_type(checkTeam, string(*(get_ecs_string(squads__respawnTypeList[i]))))
        continue
      return true
    return false

  if !anyCanSpawn
    print("TEAM {checkTeam} SPAWN DEFEAT! Team cannot spawn any squads anymore!")
    query() <| $ [es(REQUIRE=teamTag)] (team__id : int; var team__noMoreSpawns : bool&)
      if team__id == checkTeam
        team__noMoreSpawns = true
    broadcastEvent([[EventTeamLost team=checkTeam]])
