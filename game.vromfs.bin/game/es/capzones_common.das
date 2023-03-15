module capzones_common shared

require ecs
require game.events_game
require game.utils.team
require enlisted.events_enlisted
require net
require DagorRandom

struct CapturedZoneStat
  total : int
  capturedAlly : int
  capturedEnemy : int

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

def is_capzone_captured_by_team(capzone__owningTeam : int;
                                capzone__mustBeCapturedByTeam : int;
                                capzone__progress : float;
                                team_id : int)
  return (team_id == capzone__owningTeam &&
          team_id == capzone__mustBeCapturedByTeam &&
          capzone__progress >= 1.0)


def all_capzones_in_group_captured_by_team(skip_eid : EntityId; team_id : int; group : string)
  return !find_query() <| $ [es(REQUIRE=capzone)] (eid : EntityId;
                                                   groupName : string;
                                                   active : bool;
                                                   capzone__progress : float;
                                                   capzone__owningTeam : int;
                                                   capzone__mustBeCapturedByTeam : int = TEAM_UNASSIGNED)
    return (active &&
            skip_eid != eid &&
            group == groupName &&
            !is_capzone_captured_by_team(capzone__owningTeam, capzone__mustBeCapturedByTeam, capzone__progress, team_id))


def get_all_captured_zones_info(hero_team : int)
  var info = [[CapturedZoneStat]]
  query() <| $ [es] (capzone__capTeam : int;
                     capzone__alwaysShow : bool = false;
                     capzone__alwaysHide : bool = false;
                     active : bool = false)
    if (active || capzone__alwaysShow) && !capzone__alwaysHide
      if capzone__capTeam != TEAM_UNASSIGNED
        if is_teams_friendly(capzone__capTeam, hero_team)
          info.capturedAlly += 1
        else
          info.capturedEnemy += 1
      info.total += 1
  return info


def is_zone_captured_by_team(team : int; capzone__capTeam : int; capzone__mustBeCapturedByTeam : int; capzone__progress : float)
  return capzone__capTeam == team && capzone__mustBeCapturedByTeam == team && capzone__progress >= 0.9


def is_all_zones_in_group_captured_by_team(skip_eid : EntityId; team : int; group_name : string)
  var allZonesCaptured = true
  query() <| $ [es(REQUIRE=capzone)] (eid : EntityId; active : bool; groupName : string;
                                      capzone__capTeam : int; capzone__mustBeCapturedByTeam : int; capzone__progress : float)
    if (active && eid != skip_eid && groupName == group_name &&
        !is_zone_captured_by_team(team, capzone__capTeam, capzone__mustBeCapturedByTeam, capzone__progress))
      allZonesCaptured = false
  return allZonesCaptured


struct SectorInfo
  zonesCapturedByTeam : int
  zonesTotal : int
  groupName : string
  nextGroup : string

def is_last_sector_for_team(team : int; captured_zone_eid : EntityId = INVALID_ENTITY_ID)
  var sectorsInfo : array<SectorInfo>
  query() <| $ [es(REQUIRE=capzone)] (eid : EntityId;
                                      capzone__activateAfterCap : string;
                                      groupName : string;
                                      capzone__capTeam : int;
                                      capzone__mustBeCapturedByTeam : int;
                                      capzone__progress : float)
    let myGroupIndex = find_index_if(sectorsInfo) <| $(elem) : bool
      return groupName == elem.groupName

    let isCaptured = (captured_zone_eid == eid ||
      is_zone_captured_by_team(team, capzone__capTeam, capzone__mustBeCapturedByTeam, capzone__progress))
    if myGroupIndex < 0
      sectorsInfo |> push([[SectorInfo groupName=groupName, nextGroup=capzone__activateAfterCap,
        zonesCapturedByTeam=isCaptured ? 1 : 0, zonesTotal=1]])
      return
    sectorsInfo[myGroupIndex].zonesCapturedByTeam += isCaptured ? 1 : 0
    sectorsInfo[myGroupIndex].zonesTotal += 1

  let lastGroupIndex = find_index_if(sectorsInfo) <| $(elem) : bool
    return elem.nextGroup == ""

  if lastGroupIndex < 0 || sectorsInfo[lastGroupIndex].zonesCapturedByTeam == sectorsInfo[lastGroupIndex].zonesTotal
    return false // last sector is captured already or not exist?

  let penultGroupIndex = find_index_if(sectorsInfo) <| $(elem) : bool
    return elem.nextGroup == sectorsInfo[lastGroupIndex].groupName

  return penultGroupIndex > 0 && sectorsInfo[penultGroupIndex].zonesCapturedByTeam == sectorsInfo[penultGroupIndex].zonesTotal

def is_half_zone_captured(captured : int; total : int)
  return total >= 2 && captured * 2 >= total && (captured - 1) * 2 < total
