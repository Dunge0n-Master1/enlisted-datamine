require ecs
require game.events_game
require matching
require EnlistedMatching

[es(tag=server, on_event=EventLevelLoaded)]
def level_loaded_events_es(evt : Event)
  on_level_loaded()

[es(tag=server)]
def matching_events_es(evt : EventTeamMemberJoined)
  let eid = evt.eid
  let team = evt.team
  query(eid) <| $ [es] (userid : uint64)
    if userid != INVALID_USER_ID
      on_player_team_changed(userid, team)

[es(tag=server, track=vote_to_kick__kicked)]
def vote_to_kick_mroom_kick_es(evt : Event; vote_to_kick__kicked : bool; userid : uint64)
  if vote_to_kick__kicked && userid != INVALID_USER_ID
    player_kick_from_room(userid)
    ban_player_in_room(userid)
