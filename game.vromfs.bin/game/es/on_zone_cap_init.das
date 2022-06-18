require ecs
require game.utils.team

def find_another_team_or(team, default_value)
  var res = default_value
  find_query() <| $ [es] (team__id : int)
    if team__id != TEAM_UNASSIGNED && team__id != team
      res = team__id
      return true
    return false
  return res

[es(tag=server, on_appear)]
def capzone_init_owning_team(evt : Event; capzone__mustBeCapturedByTeam : int; var capzone__owningTeam : int&)
  if capzone__mustBeCapturedByTeam != TEAM_UNASSIGNED
    capzone__owningTeam = find_another_team_or(capzone__mustBeCapturedByTeam, capzone__owningTeam)
