require ecs.ecs_quirrel
require daslib/quirrel_boost

[quirrel_bind(module_name="das.replay")]
def replay_rewind(time : float)
  find_query() <| $ [es(REQUIRE=replay__accelerationTime)] (eid : EntityId)
    destroyEntity(eid)
    return true

  createEntity("replay_acceleration_to") <| $(var init)
    init |> set("replay__accelerationTime", time)