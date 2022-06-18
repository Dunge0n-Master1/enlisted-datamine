module send_squad_cmd_stat_bq_common shared
require ecs
require jsonwriter
require game.es.stat_bq_common

def send_squad_member_accept_order_bq(squad_leader : EntityId; order_name : string; order_position : float3 = float3(0); order_position_flag : bool = false)
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header("bot_order_execution") <| $(var jw : JsonWriter)
    jw_key_value(jw, "event_type", "bot_order_execution")
    jw_key_value(jw, "order_name", order_name)
    query(squad_leader) <| $ [es] (possessedByPlr : EntityId; transform : float3x4)
      if order_position_flag
        jw_key_value(jw, "distance", distance(order_position, transform[3]))
      query(possessedByPlr) <| $ [es] (userid : uint64; team : int)
        add_user_id(jw, userid)
        jw_key_value(jw, "team", team)

def send_order_cancel_bq(squad_leader : EntityId; status : string; order_name : string)
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header("user_order_cancel") <| $(var jw : JsonWriter)
    jw_key_value(jw, "order_name", order_name)
    jw_key_value(jw, "status", status)
    query(squad_leader) <| $ [es] (possessedByPlr : EntityId)
      query(possessedByPlr) <| $ [es] (userid : uint64; team : int)
        add_user_id(jw, userid)
        jw_key_value(jw, "team", team)

def new_player_order_bq(squad_leader : EntityId; order_name : string)
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header("user_order") <| $(var jw : JsonWriter)
    jw_key_value(jw, "event_type", "user_order")
    jw_key_value(jw, "order_name", order_name)
    query(squad_leader) <| $ [es] (possessedByPlr : EntityId)
      query(possessedByPlr) <| $ [es] (userid : uint64; team : int)
        add_user_id(jw, userid)
        jw_key_value(jw, "team", team)