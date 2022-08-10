require ecs
require game.events_game

[es(tag=server)]
def count_scoring_player_soldier_deaths(evt : EventEntityDied; squad_member__playerEid : EntityId)
  query(squad_member__playerEid) <| $ [es] (var scoring_player__soldierDeaths : int&)
    scoring_player__soldierDeaths += 1

[es(tag=server, track=squad__numAliveMembers)]
def count_scoring_player_squad_deaths(evt : Event;
                                      squad__numAliveMembers : int;
                                      squad__ownerPlayer : EntityId)
  if squad__numAliveMembers <= 0
    query(squad__ownerPlayer) <| $ [es] (var scoring_player__squadDeaths : int&)
      scoring_player__squadDeaths += 1
