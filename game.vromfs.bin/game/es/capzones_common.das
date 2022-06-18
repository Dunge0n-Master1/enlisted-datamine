module capzones_common shared

require ecs
require game.events_game
require game.utils.team
require enlisted.events_enlisted
require net


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
