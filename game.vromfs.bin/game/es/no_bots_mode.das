require ecs

[es(tag=server, REQUIRE=noBotsMode, on_appear)]
def no_bots_init_soldier_revive_points(evt : Event)
  query() <| $ [es(REQUIRE=player)] (eid : EntityId)
    addSubTemplate(eid, "soldier_revive_points")

[es(tag=server, REQUIRE=noBotsMode, on_event=(EventComponentsDisappear, EventEntityDestroyed))]
def no_bots_remove_soldier_revive_points(evt : Event)
  query() <| $ [es(REQUIRE=player)] (eid : EntityId)
    removeSubTemplate(eid, "soldier_revive_points")

[es(tag=server, REQUIRE=player, on_appear)]
def no_bots_init_soldier_revive_points_player_created(evt : Event; eid : EntityId)
  let isNoBotsMode = find_query() <| $ [es(REQUIRE=noBotsMode)] ()
    return true
  if isNoBotsMode
    addSubTemplate(eid, "soldier_revive_points")
