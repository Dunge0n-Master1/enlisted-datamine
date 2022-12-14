require ecs
require app
require DagorSystem
require CurrentCircuit
require jsonwriter
require ECSGlobalTags
require OnlineStorage
require game.es.app_common

[es(tag=gameClient, on_event=(EventUserLoggedIn, EventDaScriptReloaded))]
def send_aot_stat_on_login(evt : Event)
  if globally_enabled_aot()
    jw_writer() <| $(var jw : JsonWriter)
      jw_start_obj(jw)
      jw_key_value(jw, "platform", get_platform_string_id())
      jw_key_value(jw, "build_number", get_exe_version_str())
      jw_key_value(jw, "das_systems_count", das_ecs_systems_count())
      jw_key_value(jw, "das_aot_systems_count", das_ecs_aot_systems_count())
      jw_key_value(jw, "link_aot_errors_count", link_aot_errors_count())
      jw_key_value(jw, "circuit", get_circuit_name())
      jw_key_value(jw, "environment", get_environment())
      jw_key_value(jw, "load_time", das_load_time_ms())
      jw_key_value(jw, "memory_usage", das_memory_usage() / 1024l)
      jw_end_obj(jw)

      add_bigquery_record("dascript_client", jw.result)
      save_and_send_to_server()
