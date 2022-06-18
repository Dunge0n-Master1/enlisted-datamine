require ecs
require ecs.common
require statBQ
require jsonwriter
require game.es.player_events
require game.es.stat_bq_common
require enlisted.game.utils.armies_common
require EnlistedNet

def add_user_id_and_team(var jw; userid; team)
  add_user_id(jw, userid)
  jw_key_value(jw, "team", team)

def add_soldiers(var jw; soldiers)
  jw_start_array(jw)
  for it in soldiers
    jw_start_obj(jw)

    let soldier = get_ecs_object(it)
    jw_key_value(jw, "class", get_string(soldier, "sClass", ""))
    jw_key_value(jw, "level", get_int(soldier, "level") ?? -1)
    jw_key_value(jw, "level_max", get_int(soldier, "maxLevel") ?? -1)

    let weapons = get_ecs_object(soldier, "human_weap__weapTemplates")
    jw_key_value(jw, "primary", get_string(weapons, "primary", ""))
    jw_key_value(jw, "secondary", get_string(weapons, "secondary", ""))
    jw_key_value(jw, "tertiary", get_string(weapons, "tertiary", ""))

    jw_end_obj(jw)
  jw_end_array(jw)

def add_squads(var root_jw; squads)
  if squads == null
    return
  jw_writer() <| $(var jw : JsonWriter)
    jw_start_array(jw)
    for it in *squads
      let squad = get_ecs_object(it)
      let soldiers = get_ecs_array(squad, "squad")
      if soldiers != null
        jw_start_obj(jw)
        jw_key_value(jw, "squad_id", get_string(squad, "squadId", ""))
        jw_key_value(jw, "vehicle", get_squad_vehicle(squad))
        jw_key(jw, "soliders")
        add_soldiers(jw, *soldiers)
        jw_end_obj(jw)
    jw_end_array(jw)
    jw_key_value(root_jw, "all_squads", jw.result)

[es(tag=server)]
def player_connected_es(evt : EventOnPlayerConnected; userid : uint64)
  let team = evt.wishTeam
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header("player_connect") <| $(var jw : JsonWriter)
    add_user_id_and_team(jw, userid, team)

[es(tag=server, before=player_events_es)]
def client_disconnected_es(evt : EventOnClientDisconnected; userid : uint64; connid : int; team : int)
  if evt.connid != connid
    return
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header("player_client_disconnect") <| $(var jw : JsonWriter)
    add_user_id_and_team(jw, userid, team)
    jw_key_value(jw, "connerr", "{evt.cause}")

[es(tag=server, track=disconnected)]
def player_on_change_disconnected_es(evt : Event; userid : uint64; disconnected : bool; team : int)
  if disconnected
    return
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header("player_reconnect") <| $(var jw : JsonWriter)
    add_user_id_and_team(jw, userid, team)

[es(tag=server, track=team)]
def player_on_change_team_es(evt : Event; userid : uint64; team : int)
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header("player_change_team") <| $(var jw : JsonWriter)
    add_user_id_and_team(jw, userid, team)

[es(tag=server, track=armiesReceivedTime, REQUIRE=armiesReceivedTime)]
def player_on_receive_armies_es(evt : Event; userid : uint64; team : int; army : string; armies : Object)
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header("player_receive_army") <| $(var jw : JsonWriter)
    add_user_id_and_team(jw, userid, team)
    jw_key_value(jw, "army", army)
    add_squads(jw, get_army_squads(armies, army))
