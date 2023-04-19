require ecs
require game.es.player_events
require matching
require DngMatching

[es(tag=server, on_event=EventOnPlayerConnected)]
def player_set_wish_any_team_flag(evt : Event; userid : uint64; var player__wishAnyTeam : bool&)
  if userid != INVALID_USER_ID
    player__wishAnyTeam = get_player_req_teams_num(userid) > 1
