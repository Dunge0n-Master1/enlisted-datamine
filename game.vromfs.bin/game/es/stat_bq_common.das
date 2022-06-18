module stat_bq_common shared
require ecs
require ecs.common
require statBQ
require jsonwriter public

def send_event_bq_with_header(event_type : string; subexpr : block<(var jw : JsonWriter) : void>)
  send_event_bq("game_events_bq") <| $(var jw : JsonWriter)
    jw_start_array(jw)
    jw_start_obj(jw)
    add_event_bq_header(jw)
    jw_key_value(jw, "event_type", event_type)
    invoke(subexpr, jw)
    jw_end_obj(jw)
    jw_end_array(jw)

    print("[BQ][{event_type}]: {jw.result}\n")

def add_entity_type(var jw : JsonWriter; eid : EntityId; prefix : string)
  if has(eid, "human")
    ecs::query(eid) <| $ [es] (beh_tree__enabled : bool; isInVehicle : bool)
      let suffix = isInVehicle ? "_in_vehicle" : ""
      jw_key_value(jw, "{prefix}_type", beh_tree__enabled ? "human_bot{suffix}" : "human{suffix}")
  elif has(eid, "airplane")
    jw_key_value(jw, "{prefix}_type", "airplane")
  elif has(eid, "vehicle")
    jw_key_value(jw, "{prefix}_type", "vehicle")

def get_team_eid(team : int)
  var teamEid = INVALID_ENTITY_ID
  ecs::find_query() <| $ [es] (eid : EntityId; team__id : int)
    if team__id == team
      teamEid = eid
    return teamEid != INVALID_ENTITY_ID
  return teamEid

def add_user_id(var jw : JsonWriter; userid : uint64; key : string = "user_id")
  if int64(userid) > int64(0)
    jw_key_value(jw, key, int64(userid))
