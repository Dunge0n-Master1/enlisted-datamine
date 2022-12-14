require ecs
require enlisted.events_enlisted
require game.es.capzones_common
require game.utils.team
require game.events_game

def on_zone_activate_multiple(zone_eid : EntityId; team_id : int)
  query(zone_eid) <| $ [es] (capzone__activateChoiceAfterCap : Object;
                             capzone__checkAllZonesInGroup : bool = false;
                             groupName : string;
                             capzone__mustBeCapturedByTeam : int = TEAM_UNASSIGNED)
    if (capzone__checkAllZonesInGroup
        && (team_id != capzone__mustBeCapturedByTeam || !all_capzones_in_group_captured_by_team(zone_eid, team_id, groupName)))
      return
    let teams = get_ecs_object(capzone__activateChoiceAfterCap["team"])
    if teams != null
      let choice = get_ecs_object((*teams)["{team_id}"])
      if choice != null
        let nextGroup = select_random_choice(*choice)
        if nextGroup != ""
          activate_group(nextGroup)

def on_zone_captured(zone_eid : EntityId; team_id : int)
  query(zone_eid) <| $ [es] (groupName : string;
                             capzone__activateAfterCap : das_string;
                             capzone__activateAfterTeam1Cap : das_string const?;
                             capzone__activateAfterTeam2Cap : das_string const?;
                             capzone__checkAllZonesInGroup : bool = false;
                             capzone__mustBeCapturedByTeam : int = TEAM_UNASSIGNED)
    if (capzone__checkAllZonesInGroup
        && (team_id != capzone__mustBeCapturedByTeam || !all_capzones_in_group_captured_by_team(zone_eid, team_id, groupName)))
      return
    var nextGroupName = string(capzone__activateAfterCap)
    if team_id == 1
      nextGroupName = string(capzone__activateAfterTeam1Cap ?? capzone__activateAfterCap)
    elif team_id == 2
      nextGroupName = string(capzone__activateAfterTeam2Cap ?? capzone__activateAfterCap)
    let paramName = "capzone__activateAfterTeam{team_id}Cap"
    print("searching for {nextGroupName} to activate from param {paramName}")
    activate_group(nextGroupName) // TODO: need improvement. Only activate respawns?

def on_zone_captured_delayed(zone_eid : EntityId; team_id : int)
  query(zone_eid) <| $ [es] (groupName aka current_groupName : string;
                             capzone__activateChoice : Object const?;
                             capzone__activateAfterCap : das_string;
                             capzone__activateAfterTeam1Cap : das_string const?;
                             capzone__activateAfterTeam2Cap : das_string const?;
                             capzone__checkAllZonesInGroup : bool = false;
                             capzone__mustBeCapturedByTeam : int = TEAM_UNASSIGNED)
    if (capzone__checkAllZonesInGroup
        && (team_id != capzone__mustBeCapturedByTeam || !all_capzones_in_group_captured_by_team(zone_eid, team_id, current_groupName)))
      return
    var nextGroupName = string(capzone__activateAfterCap)
    if team_id == 1
      nextGroupName = string(capzone__activateAfterTeam1Cap ?? capzone__activateAfterCap)
    elif team_id == 2
      nextGroupName = string(capzone__activateAfterTeam2Cap ?? capzone__activateAfterCap)
    let paramName = "capzone__activateAfterTeam{team_id}Cap"

    print("searching capzone for {nextGroupName} to activate from param {paramName}")

    query() <| $ [es(REQUIRE=capzone)] (eid : EntityId; groupName : string)
      if groupName == nextGroupName
        sendEvent(eid, [[EventEntityActivate activate = true]])
    query() <| $ [es(REQUIRE=battle_area)] (eid : EntityId; groupName : string)
      if groupName == nextGroupName
        sendEvent(eid, [[EventEntityActivate activate = true]])

    let hasChoice = capzone__activateChoice != null && !capzone__activateChoice.empty
    if nextGroupName != "" || hasChoice
      query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=(autoSetRespawnGroup, temporaryRespawnbase))] (eid : EntityId;
                                                                                                    groupName aka respawn_groupName : string;
                                                                                                    team aka respawn_team : int)
        if respawn_team != team_id
          if respawn_groupName == nextGroupName
            sendEvent(eid, [[EventEntityActivate activate = true]])
          elif respawn_groupName == current_groupName
            sendEvent(eid, [[EventEntityActivate activate = false]])

[es(tag=server)]
def capzone_on_activate_multiple_captured(evt : EventZoneCaptured)
  on_zone_activate_multiple(evt.zone, evt.team)

[es(tag=server)]
def capzone_on_activate_multiple_delayed(evt : EventZoneDeactivated)
  on_zone_activate_multiple(evt.zone, evt.team)

[es(tag=server)]
def capzone_on_activate_captured(evt : EventZoneCaptured)
  on_zone_captured(evt.zone, evt.team)

[es(tag=server)]
def capzone_on_activate_delayed(evt : EventZoneDeactivated)
  on_zone_captured(evt.zone, evt.team)

[es(tag=server)]
def capzone_on_activate_delayed_captured(evt : EventZoneIsAboutToBeCaptured)
  on_zone_captured_delayed(evt.zone, evt.team)
