require ecs

[es(tag=sound, no_order, REQUIRE=watchedByPlayerSound, REQUIRE=watchedByPlr)]
def watched_by_player_sound_update_watched(info : UpdateStageInfoAct;
                                           var is_watched_sound : bool&)
  is_watched_sound = true


[es(tag=sound, no_order, REQUIRE=watchedByPlayerSound, REQUIRE_NOT=watchedByPlr)]
def watched_by_player_sound_update_not_watched(info : UpdateStageInfoAct;
                                               var is_watched_sound : bool&)
  is_watched_sound = false
