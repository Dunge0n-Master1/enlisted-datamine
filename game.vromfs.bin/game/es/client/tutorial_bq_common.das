module tutorial_bq_common shared
require ecs
require game.es.stat_bq_common
require enlisted.game.es.client.stat_bq_client_common

def send_tutorial_stage_bq(stage_name : string)
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header_client(stage_name) <| $(var jw : JsonWriter)
    // only one player possible, because tutorial is offline match
    query() <| $ [es] (userid : uint64) { add_user_id(jw, userid); }
