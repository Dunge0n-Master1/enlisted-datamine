require ecs


[es(tag=server, on_appear, REQUIRE=deadEntity)]
def add_score_on_destroyable_death(evt : Event;
                                   destroyable_score__addScoreAmount : int;
                                   destroyable_score__addScoreForTeam : int)
  find_query() <| $ [es] (team__id : int;
                          var team__score : float&)
    if team__id == destroyable_score__addScoreForTeam
      team__score += float(destroyable_score__addScoreAmount)
      return true
    return false
