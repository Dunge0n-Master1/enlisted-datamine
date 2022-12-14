module stat_bq_client_common shared
require statBQ
require jsonwriter public
require OnlineStorage

def send_event_bq_with_header_client(event_type; subexpr)
  jw_writer() <| $(var jw : JsonWriter)
    jw_start_array(jw)
    jw_start_obj(jw)
    add_event_bq_header(jw)
    jw_key_value(jw, "event_type", event_type)
    invoke(subexpr, jw)
    jw_end_obj(jw)
    jw_end_array(jw)
    add_bigquery_record("game_events_bq", jw.result)
    save_and_send_to_server()
