require ecs
require app

[es(tag=sound, no_order)]
def gun_sound_is_watched_update(info : UpdateStageInfoAct;
                                var gun_sound__isWatched : bool&;
                                gun__owner : EntityId)
  gun_sound__isWatched = false
  query(gun__owner) <| $ [es] (is_watched_sound : bool; human_anim__vehicleSelected = INVALID_ENTITY_ID)
    gun_sound__isWatched = is_watched_sound
    query(human_anim__vehicleSelected) <| $ [es] (is_watched_sound : bool)
      gun_sound__isWatched ||= is_watched_sound
