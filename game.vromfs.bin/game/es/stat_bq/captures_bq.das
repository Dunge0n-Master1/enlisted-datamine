require ecs
require statBQ
require jsonwriter
require game.es.events
require game.es.stat_bq_common
require enlisted.events_enlisted
require player


def on_zone_captured(evt, eid, capzone__title)
  if eid == evt.zone
    // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
    send_event_bq_with_header("zone_capture") <| $(var jw : JsonWriter)
      jw_key_value(jw, "capzone_id", capzone__title)
      jw_key_value(jw, "team", evt.team)

[es(tag=server)]
def zone_is_about_to_be_captured_es(evt : EventZoneIsAboutToBeCaptured; eid : EntityId; capzone__title : string)
  on_zone_captured(evt, eid, capzone__title)

[es(tag=server)]
def zone_captured_es(evt : EventZoneCaptured; eid : EntityId; capzone__title : string)
  on_zone_captured(evt, eid, capzone__title)

[es(tag=server)]
def zone_decaptured_es(evt : EventZoneDecaptured; eid : EntityId; capzone__title : string)
  if eid == evt.zone
    // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
    send_event_bq_with_header("zone_decapture") <| $(var jw : JsonWriter)
      jw_key_value(jw, "capzone_id", capzone__title)
      jw_key_value(jw, "team", evt.team)
