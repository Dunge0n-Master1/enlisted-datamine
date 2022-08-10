module capzones_common shared

require ecs
require game.events_game
require game.utils.team
require enlisted.events_enlisted
require net
require DagorRandom


def activate_group(activateGroupName : string)
  query() <| $ [es] (eid : EntityId;
                     groupName : string)
    if groupName == activateGroupName
      sendEvent(eid, [[EventEntityActivate activate=true]])


def deactivate_group(deactivateGroupName : string)
  query() <| $ [es] (eid : EntityId;
                     groupName : string)
    if groupName == deactivateGroupName
      sendEvent(eid, [[EventEntityActivate activate=false]])


def decapture_zone(eid : EntityId)
  query(eid) <| $ [es] (var capzone__progress : float&;
                        var capzone__owningTeam : int&;
                        var capzone__curTeamCapturingZone : int&;
                        var capzone__curTeamDominating : int&)
    capzone__progress = 0.f
    broadcast_net_event([[EventZoneDecaptured zone=eid, team=capzone__owningTeam]])
    capzone__owningTeam = TEAM_UNASSIGNED
    capzone__curTeamCapturingZone = TEAM_UNASSIGNED
    capzone__curTeamDominating = TEAM_UNASSIGNED

def select_random_choice(object : Object)
  var totalWeight = 0.
  for it in object
    totalWeight += get_float(it.value) ?? 0.
  if totalWeight == 0.
    return ""
  let rnd = rnd_float(0., totalWeight)
  var curWeight = 0.
  for it in object
    curWeight += get_float(it.value) ?? 0.
    if rnd < curWeight
      return it.key
  return ""

def is_capzone_captured_by_team(capzone__capTeam : int;
                                capzone__mustBeCapturedByTeam : int;
                                capzone__progress : float;
                                team_id : int)
  return (team_id == capzone__capTeam &&
          team_id == capzone__mustBeCapturedByTeam &&
          capzone__progress >= 0.99)


def all_capzones_in_group_captured_by_team(skip_eid : EntityId; team_id : int; group : string)
  return !find_query() <| $ [es(REQUIRE=capzone)] (eid : EntityId;
                                                   groupName : string;
                                                   active : bool;
                                                   capzone__progress : float;
                                                   capzone__capTeam : int;
                                                   capzone__mustBeCapturedByTeam : int = TEAM_UNASSIGNED)
    return (active &&
            skip_eid != eid &&
            group == groupName &&
            !is_capzone_captured_by_team(capzone__capTeam, capzone__mustBeCapturedByTeam, capzone__progress, team_id))
