require ecs
require ecs.safe
require ecs.common
require strings
require game.es.sound.narrator_common
require enlisted.events_enlisted
require game.utils.team
require game.es.capzones_common

def private narrator_domination_on_zone_captured(zone : EntityId; team : int)
  query(zone) <| $ [es(REQUIRE=capzone__domination)] ([[shared_comp]] narrator__phrase : Object;
                                                      capzone__title : string;
                                                      capzone__alwaysHide : bool = false)
    if capzone__alwaysHide
      return

    let isAllies = is_teams_friendly(team, get_local_player_team())
    let phraseByTeam = narrator__phrase[isAllies ? "allies" : "enemy"] ?as Object
    if phraseByTeam == null
      return

    let zonesInfo = get_all_captured_zones_info(team)
    // use capturedAlly because we pass zone team(not a hero team) to get_all_captured_zones_info
    if zonesInfo.capturedAlly >= zonesInfo.total
      let allZonesCaptured = (*phraseByTeam)["all_zones_captured"] ?as Object
      play_narrator_major_event("all_zones_captured", allZonesCaptured?.text ?? "", isAllies, allZonesCaptured?.phrase ?? "")
      return

    let zoneCaptured = (*phraseByTeam)["zone_captured"] ?as Object
    let zoneCapturedText = replace(zoneCaptured?.text ?? "", "%title%", capzone__title)
    let zoneCapturedPhrase = replace(zoneCaptured?.phrase ?? "", "%title%", capzone__title)
    play_narrator_major_event("zone_captured", zoneCapturedText, isAllies, zoneCapturedPhrase)

[es(tag=sound)]
def narrator_domination_on_zone_captured_es(evt : EventZoneCaptured)
  narrator_domination_on_zone_captured(evt.zone, evt.team)

[es(tag=sound)]
def narrator_domination_on_zone_about_to_be_captured_es(evt : EventZoneIsAboutToBeCaptured)
  narrator_domination_on_zone_captured(evt.zone, evt.team)
