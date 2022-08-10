require ecs
require app
require statBQ
require jsonwriter
require game.events_game
require game.es.stat_bq_common
require strings

def isTeamsSwithed() : bool
  var result = false
  query() <| $ [es] (isTeamsSwitched : bool) { result = isTeamsSwitched; }
  return result

def private get_sectors()
  var zones : array<string>
  query() <| $ [es(REQUIRE=capzone)] (ui_order : int; groupName : string)
    if ui_order >= 0
      zones |> push(groupName)
  return <- zones

[es(tag=server, on_event=EventLevelLoaded, REQUIRE=level__blk)]
def session_stated_es(evt : Event)
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header("session_start") <| $(var jw : JsonWriter)
    jw_key_value(jw, "level", get_current_scene())
    jw_key_value(jw, "sectors", get_sectors())

[es(tag=server, on_event=EventEntityDestroyed, REQUIRE=level__blk)]
def session_end_es(evt : Event)
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header("session_stop") <| $(var jw : JsonWriter)
    jw_key_value(jw, "level", get_current_scene())
    jw_key_value(jw, "teams_switched", isTeamsSwithed())
    jw_key_value(jw, "sectors", get_sectors())

[es(tag=server, REQUIRE=level__blk)]
def session_on_round_end_es(evt : EventTeamRoundResult)
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header("session_stop_with_result") <| $(var jw : JsonWriter)
    jw_key_value(jw, "level", get_current_scene())
    jw_key_value(jw, "team", evt.team)
    jw_key_value(jw, "is_won", evt.isWon)
    jw_key_value(jw, "teams_switched", isTeamsSwithed())
    jw_key_value(jw, "sectors", get_sectors())

    let team = evt.team
    ecs::find_query() <| $ [es] (team__id : int; team__score : float; team__scoreCap : float; team__armies : StringList)
      let isMyTeam = team__id == team
      if isMyTeam
        jw_key_value(jw, "army", length(team__armies) > 0 ? string(team__armies[0]) : "")
        jw_key_value(jw, "team_score", team__score)
        jw_key_value(jw, "team_score_cap", team__scoreCap)
      return isMyTeam
