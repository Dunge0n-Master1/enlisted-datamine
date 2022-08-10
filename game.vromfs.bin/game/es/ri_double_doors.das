require ecs
require game.es.ri_double_doors_common

[es(tag=server, REQUIRE=connectDoubleDoors, on_appear)]
def double_doors_es(evt : Event; eid : EntityId)
  destroyEntity(eid)
  query() <| $ [es(REQUIRE=isDoor)] (eid : EntityId)
    pair_riextra_door(eid)
