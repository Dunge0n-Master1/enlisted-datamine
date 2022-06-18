require ecs

[es(tag=server, on_appear, track=scoring_player__score, REQUIRE=player, REQUIRE_NOT=playerIsBot)]
def battle_result_mark_player_enough_score_for_exp_mult(evt : Event;
                                                        scoring_player__score : int;
                                                        scoring_player__minScoreForXpMultipliers : int;
                                                        var scoring_player__isEnoughScoreForXpMultipliers : bool&)
  if scoring_player__score >= scoring_player__minScoreForXpMultipliers
    scoring_player__isEnoughScoreForXpMultipliers = true
