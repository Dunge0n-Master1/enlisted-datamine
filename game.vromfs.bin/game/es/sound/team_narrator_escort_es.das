require ecs
require ecs.safe
require game.es.sound.narrator_common
require enlisted.events_enlisted
require game.utils.team
require game.es.capzones_common

def narrator_escort_on_zone_captured(zone : EntityId; team : int)
  query(zone) <| $ [es(REQUIRE=trainTriggerable)] (active : bool;
                                                   [[shared_comp]] narrator__phrase : Object;
                                                   capzone__alwaysHide : bool = false)
    if capzone__alwaysHide
      return

    let isAllies = is_teams_friendly(team, get_local_player_team())
    let phraseByTeam = narrator__phrase[isAllies ? "allies" : "enemy"] ?as Object
    if phraseByTeam == null
      return

    // we might not have the most recent zone data replicated yet (in this case capTeam is important)
    // but the event we got does. So use event's info for that one cap zone
    let capturedZoneInfo = [[ZoneInfo eid=zone, team=team, active=active]]
    let zonesInfo = get_all_captured_zones_info(team, capturedZoneInfo)
    // use capturedAlly because we pass zone team(not a hero team) to get_all_captured_zones_info
    if is_half_zone_captured(zonesInfo.capturedAlly, zonesInfo.total)
      let zoneCaptured = (*phraseByTeam)["zone_captured"] ?as Object
      play_narrator_major_event("zone_captured", zoneCaptured?.text ?? "", isAllies, zoneCaptured?.phrase ?? "")

[es(tag=sound)]
def narrator_escort_on_zone_captured_es(evt : EventZoneCaptured)
  narrator_escort_on_zone_captured(evt.zone, evt.team)

[es(tag=sound)]
def narrator_escort_on_zone_about_to_be_captured_es(evt : EventZoneIsAboutToBeCaptured)
  narrator_escort_on_zone_captured(evt.zone, evt.team)
