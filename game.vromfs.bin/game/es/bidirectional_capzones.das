require ecs
require enlisted.events_enlisted
require game.es.capzones_common
require game.events_game
require game.utils.team
require DagorSystem
require app


def activate_one_and_deactivate_other_group(activateGroupName : string;
                                            deactivateGroupName : string)
  var needReactivateOtherTeam = false
  query() <| $ [es] (eid : EntityId;
                     groupName : string;
                     active : bool)
    if groupName == activateGroupName
      sendEvent(eid, [[EventEntityActivate activate=true]])
    elif groupName == deactivateGroupName
      needReactivateOtherTeam ||= active
      sendEvent(eid, [[EventEntityActivate activate=false]])
  return needReactivateOtherTeam


def allow_next_and_disallow_prev_zone(team : int;
                                      activateAfterCap : string;
                                      deactivateAfterCap : string)
  var otherTeam = TEAM_UNASSIGNED
  query() <| $ [es] (team__id : int)
    if team__id != team
      otherTeam = team__id
  if otherTeam == TEAM_UNASSIGNED
    logerr("couldn't disallow to capture bidirectional capzone for team = {otherTeam}, expected 1 or 2")
  query() <| $ [es(REQUIRE=capzone)] (groupName : string;
                                      var capzone__onlyTeamCanCapture : int&)
    if groupName == activateAfterCap
      activate_group(activateAfterCap)
      capzone__onlyTeamCanCapture = (otherTeam != TEAM_UNASSIGNED &&
                                     capzone__onlyTeamCanCapture == otherTeam) ? TEAM_UNASSIGNED : team
    elif groupName == deactivateAfterCap
      capzone__onlyTeamCanCapture = team

def capture_bidirectional_capzone(zone_eid : EntityId; capture_team : int)
  query(zone_eid) <| $ [es(REQUIRE=capzoneTwoChains)] (capzone__lastZoneForTeam : int)
    if capzone__lastZoneForTeam == capture_team
      broadcastEvent([[EventTeamWon team=capture_team]])

[es(tag=server)]
def bidirectional_capzone_two_chains_captured_es(evt : EventZoneCaptured)
  capture_bidirectional_capzone(evt.zone, evt.team)

[es(tag=server)]
def bidirectional_capzone_two_chains_about_captured_es(evt : EventZoneIsAboutToBeCaptured)
  capture_bidirectional_capzone(evt.zone, evt.team)

[es(tag=server, REQUIRE=capzoneTwoChains)]
def bidirectional_capzone_decapture_on_activate(evt : EventEntityActivate; eid : EntityId; capzone__owningTeam : int)
  if evt.activate && capzone__owningTeam != TEAM_UNASSIGNED
    decapture_zone(eid)

[es(tag=server)]
def bidirectional_capzone_one_chain_captured_es(evt : EventZoneCaptured;
                                                eid : EntityId;
                                                capzone__activateAfterTeam1Cap : string;
                                                capzone__activateAfterTeam2Cap : string;
                                                capzone__activateGroupNameAfterTeam1Cap : string;
                                                capzone__activateGroupNameAfterTeam2Cap : string)
  if eid != evt.zone
    return
  let team = evt.team
  var activateAfterTeamCap : string
  var deactivateAfterTeamCap : string
  var activateGroupNameAfterTeamCap : string
  var deactivateGroupNameAfterTeamCap : string
  if team == 1
    activateAfterTeamCap = capzone__activateAfterTeam1Cap
    deactivateAfterTeamCap = capzone__activateAfterTeam2Cap
    activateGroupNameAfterTeamCap = capzone__activateGroupNameAfterTeam1Cap
    deactivateGroupNameAfterTeamCap = capzone__activateGroupNameAfterTeam2Cap
  elif team == 2
    activateAfterTeamCap = capzone__activateAfterTeam2Cap
    deactivateAfterTeamCap = capzone__activateAfterTeam1Cap
    activateGroupNameAfterTeamCap = capzone__activateGroupNameAfterTeam2Cap
    deactivateGroupNameAfterTeamCap = capzone__activateGroupNameAfterTeam1Cap
  else
    logerr("couldn't activate next bidirectional capzone for team = {team}, expected 1 or 2")

  allow_next_and_disallow_prev_zone(team, activateAfterTeamCap, deactivateAfterTeamCap)
  let needReactivateOtherTeam = activate_one_and_deactivate_other_group(activateGroupNameAfterTeamCap,
                                                                        deactivateGroupNameAfterTeamCap)
  var reactivatedGroupName = ""
  if needReactivateOtherTeam
    find_query() <| $ [es(REQUIRE=capzone)] (groupName : string;
                                             capzone__activateGroupNameAfterTeam1Cap : string;
                                             capzone__activateGroupNameAfterTeam2Cap : string)
      if groupName != activateAfterTeamCap
        return false
      if team == 1
        activate_group(capzone__activateGroupNameAfterTeam2Cap)
        reactivatedGroupName = capzone__activateGroupNameAfterTeam2Cap
      elif team == 2
        activate_group(capzone__activateGroupNameAfterTeam1Cap)
        reactivatedGroupName = capzone__activateGroupNameAfterTeam1Cap
      return true
  query() <| $ [es] (var activator__currentGroupNameForTeam1 : das_string&;
                     var activator__currentGroupNameForTeam2 : das_string&)
    if team == 1
      deactivate_group(string(activator__currentGroupNameForTeam1))
      activator__currentGroupNameForTeam1 := activateGroupNameAfterTeamCap
      if reactivatedGroupName != ""
        activator__currentGroupNameForTeam2 := reactivatedGroupName
    elif team == 2
      deactivate_group(string(activator__currentGroupNameForTeam2))
      activator__currentGroupNameForTeam2 := activateGroupNameAfterTeamCap
      if reactivatedGroupName != ""
        activator__currentGroupNameForTeam1 := reactivatedGroupName
