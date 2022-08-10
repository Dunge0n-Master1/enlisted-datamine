require ecs
require game.utils.team
require enlisted.events_enlisted

def on_zone_presence_change(visitor_eid : EntityId;
                            defaul_val : int;
                            count : int;
                            var capzone__presenceTeamCount : Object&)
  let team = get_int(visitor_eid, "team") ?? TEAM_UNASSIGNED
  if team == TEAM_UNASSIGNED
    return
  let teamId = "{team}"

  let presence = get_int(capzone__presenceTeamCount, teamId)

  if presence != null
    capzone__presenceTeamCount |> set(teamId, *presence + count)
  else
    capzone__presenceTeamCount |> set(teamId, defaul_val)

[es(tag=server)]
def capzone_presence_on_enter(evt : EventCapZoneEnter; var capzone__presenceTeamCount : Object&)
  on_zone_presence_change(evt.visitor, 1, 1, capzone__presenceTeamCount)

[es(tag=server)]
def capzone_presence_on_exit(evt : EventCapZoneLeave; var capzone__presenceTeamCount : Object&)
  on_zone_presence_change(evt.visitor, 0, -1, capzone__presenceTeamCount)