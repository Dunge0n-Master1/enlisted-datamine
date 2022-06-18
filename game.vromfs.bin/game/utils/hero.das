module hero shared
require ecs
require player


def get_controlled_hero() : EntityId
  return get_Eid(get_local_player_eid(), "possessed") ?? INVALID_ENTITY_ID


def get_watched_entity() : EntityId
  var watchedByPlr = INVALID_ENTITY_ID
  find_query() <| $ [es(REQUIRE=watchedByPlr)] (eid : EntityId)
    watchedByPlr = eid
    return true
  return watchedByPlr
