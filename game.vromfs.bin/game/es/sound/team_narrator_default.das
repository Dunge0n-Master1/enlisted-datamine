require ecs
require ecs.safe
require ecs.common
require game.es.sound.narrator_common
require enlisted.events_enlisted
require game.utils.team
require game.es.capzones_common

[es(tag=sound, track=capzone__capTeam, REQUIRE_NOT=(capzone__bombTemplate, trainTriggerable))]
def narrator_default_on_cap_zone_change_es(evt : Event;
                                           eid : EntityId;
                                           capzone__capTeam : int;
                                           active : bool;
                                           var ui_capzone__capTeamPrev : int&;
                                           capzone__title : string = "")

  if active && capzone__capTeam != TEAM_UNASSIGNED && ui_capzone__capTeamPrev == TEAM_UNASSIGNED
    query() <| $ [es(REQUIRE=watchedByPlr)] (team : int; capturer__capZonesIn : EidList)
      let isAlliesCapture = is_teams_friendly(team, capzone__capTeam)
      let isHeroCapture = isAlliesCapture && has_value(capturer__capZonesIn, eid)
      assume title = capzone__title
      if isHeroCapture && try_play_narrator_major_event("zone_capture_start", "Zone is being captured", isAlliesCapture, "pointCapturingPlayer")
        return
      elif !try_play_narrator_major_event("zone_capture_start", "Zone is being captured", isAlliesCapture, isAlliesCapture ? "point{title}CapturingAlly" : "point{title}CapturingEnemy")
        play_narrator_major_event("zone_capture_start", "Zone is being captured", isAlliesCapture, isAlliesCapture ? "pointCapturingAlly" : "pointCapturingEnemy")

  ui_capzone__capTeamPrev = capzone__capTeam


def narrator_default_on_zone_captured(zone : EntityId; team : int)
  query(zone) <| $ [es(REQUIRE_NOT=(trainTriggerable, capzone__bombTemplate, capzone__domination),
                       REQUIRE=capzone)] ([[shared_comp]] narrator__phrase : Object;
                                          capzone__checkAllZonesInGroup : bool = false;
                                          groupName : string = "";
                                          capzone__alwaysHide : bool = false)
    if capzone__alwaysHide
      return

    let isAllies = is_teams_friendly(team, get_local_player_team())
    let phraseByTeam = narrator__phrase[isAllies ? "allies" : "enemy"] ?as Object
    if phraseByTeam == null
      return

    if capzone__checkAllZonesInGroup && is_all_zones_in_group_captured_by_team(zone, team, groupName)
      let lastSectorLeft = (*phraseByTeam)["last_sector_left"] ?as Object
      if lastSectorLeft != null && is_last_sector_for_team(team)
        play_narrator_major_event("last_sector_left", lastSectorLeft?.text ?? "", isAllies, lastSectorLeft?.phrase ?? "")
        return
      let sectorCaptured = (*phraseByTeam)["sector_captured"] ?as Object
      play_narrator_major_event("sector_captured", sectorCaptured?.text ?? "", isAllies, sectorCaptured?.phrase ?? "")
      return

    let zonesInfo = get_all_captured_zones_info(team)
    if zonesInfo.capturedAlly >= zonesInfo.total
      let allZonesCaptured = (*phraseByTeam)["all_zones_captured"] ?as Object
      play_narrator_major_event("all_zones_captured", allZonesCaptured?.text ?? "", isAllies, allZonesCaptured?.phrase ?? "")
      return

    if zonesInfo.capturedAlly + 1 == zonesInfo.total
      let oneZoneToCapture = (*phraseByTeam)["one_zone_to_capture"] ?as Object
      if oneZoneToCapture != null && try_play_narrator_major_event("one_zone_to_capture", oneZoneToCapture?.text ?? "", isAllies, oneZoneToCapture?.phrase ?? "")
        return
    elif is_half_zone_captured(zonesInfo.capturedAlly, zonesInfo.total)
      let halfZonesCaptured = (*phraseByTeam)["half_zones_captured"] ?as Object
      if halfZonesCaptured != null && try_play_narrator_major_event("half_zones_captured", halfZonesCaptured?.text ?? "", isAllies, halfZonesCaptured?.phrase ?? "")
        return

    let zoneCaptured = (*phraseByTeam)["zone_captured"] ?as Object
    play_narrator_major_event("zone_captured", zoneCaptured?.text ?? "", isAllies, zoneCaptured?.phrase ?? "")


[es(tag=sound)]
def narrator_default_on_zone_captured_es(evt : EventZoneCaptured)
  narrator_default_on_zone_captured(evt.zone, evt.team)


[es(tag=sound)]
def narrator_default_on_zone_about_to_be_captured_es(evt : EventZoneIsAboutToBeCaptured)
  narrator_default_on_zone_captured(evt.zone, evt.team)

