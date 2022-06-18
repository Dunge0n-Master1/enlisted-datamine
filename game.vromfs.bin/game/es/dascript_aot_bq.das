require ecs
require app
require game.es.stat_bq_common


[es(tag=server, on_event=EventLevelLoaded, REQUIRE=level__blk)]
def send_aot_stat_on_session_start(evt : Event)
  if globally_enabled_aot()
    // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
    send_event_bq_with_header("dascript_stats") <| $(var jw : JsonWriter)
      jw_key_value(jw, "das_systems_count", das_ecs_systems_count())
      jw_key_value(jw, "das_aot_systems_count", das_ecs_aot_systems_count())
      jw_key_value(jw, "link_aot_errors_count", link_aot_errors_count())
