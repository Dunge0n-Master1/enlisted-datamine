require ecs
require ecs.common
require soundEvent
require enlisted.events_enlisted
require game.events_game
require game.utils.team


[es(tag=sound)]
def capzone_capturing_sounds_on_captured(evt : EventZoneCaptured;
                                         eid aka capzone_eid : EntityId;
                                         capzone__alwaysHide : bool)
  if evt.zone == capzone_eid && !capzone__alwaysHide
    find_query() <| $ [es(REQUIRE=hero)] (team aka hero_team : int;
                                          capturer__capZonesIn : EidList;
                                          human__capzoneCapturedSoundPath : string)
      if is_teams_friendly(hero_team, evt.team) && find_index(capturer__capZonesIn, capzone_eid) >= 0
        oneshot(human__capzoneCapturedSoundPath)
      return true


def zone_is_capturing(capzone__captureStatus : int) : bool
  return capzone__captureStatus != 0


def zone_is_capturing_by_hero(zone_eid : EntityId; hero_team : int; is_downed, is_in_vehicle : bool) : bool
  var ret = false
  query(zone_eid) <| $ [es] (capzone__captureStatus : int; capzone__capTeam : int; zone__excludeDowned : ecs::Tag const?; capzone__canCaptureOnVehicle : bool)
    if is_downed && zone__excludeDowned != null
      return
    if is_in_vehicle && !capzone__canCaptureOnVehicle
      return
    if !zone_is_capturing(capzone__captureStatus)
      return
    if !is_teams_friendly(hero_team, capzone__capTeam)
      return
    ret = true
  return ret


def is_hero_capturing(capturer__capZonesIn : EidList; hero_team : int; is_downed, is_in_vehicle : bool) : bool
  for zoneEid in capturer__capZonesIn
    if zone_is_capturing_by_hero(zoneEid, hero_team, is_downed, is_in_vehicle)
      return true
  return false


def track_capturing(capturer__capZonesIn : EidList;
                    team : int;
                    isAlive, isDowned, isInVehicle : bool;
                    human__capzoneCapturingSoundPath : string;
                    var human__capzoneCapturingSoundEvent : SoundEvent&)
  let isCapturing = isAlive && is_hero_capturing(capturer__capZonesIn, team, isDowned, isInVehicle)
  if human__capzoneCapturingSoundEvent.enabled != isCapturing
    human__capzoneCapturingSoundEvent.enabled = isCapturing
    release(human__capzoneCapturingSoundEvent.handle)
    if isCapturing
      human__capzoneCapturingSoundEvent |> play(human__capzoneCapturingSoundPath)


[es(tag=sound, track=(capzone__captureStatus, capzone__capTeam), REQUIRE=(capzone__captureStatus, capzone__capTeam))]
def capzone_capturing_sounds_track_capture_status(evt : Event)
  query() <| $ [es(REQUIRE=hero)] (capturer__capZonesIn : EidList;
                                   team aka hero_team : int;
                                   isAlive, isDowned : bool;
                                   isInVehicle : bool = false;
                                   human__capzoneCapturingSoundPath : string;
                                   var human__capzoneCapturingSoundEvent : SoundEvent&)
    track_capturing(capturer__capZonesIn, hero_team, isAlive, isDowned, isInVehicle, human__capzoneCapturingSoundPath, human__capzoneCapturingSoundEvent)


[es(tag=sound, REQUIRE=hero, track=(capturer__capZonesIn, isAlive, isDowned, isInVehicle), on_appear)]
def capzone_capturing_sounds_track_hero_zones_in(evt : Event;
                                                 capturer__capZonesIn : EidList;
                                                 team aka hero_team : int;
                                                 isAlive, isDowned : bool;
                                                 isInVehicle : bool = false;
                                                 human__capzoneCapturingSoundPath : string;
                                                 var human__capzoneCapturingSoundEvent : SoundEvent&)
  track_capturing(capturer__capZonesIn, hero_team, isAlive, isDowned, isInVehicle, human__capzoneCapturingSoundPath, human__capzoneCapturingSoundEvent)


[es(tag=sound, REQUIRE=hero, track=isAlive)]
def capzone_capturing_sounds_track_is_alive(evt : Event;
                                            isAlive : bool;
                                            var human__capzoneCapturingSoundEvent : SoundEvent&)
  if !isAlive
    release(human__capzoneCapturingSoundEvent.handle)


[es(tag=sound, REQUIRE=hero, on_disappear)]
def capzone_capturing_sounds_disappear(evt : Event;
                                       var human__capzoneCapturingSoundEvent : SoundEvent&)
  release(human__capzoneCapturingSoundEvent.handle)
