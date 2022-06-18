require ecs
require game.es.app_common

[es(tag=server, on_appear, REQUIRE=player)]
def afk_enable_by_circuit(evt : Event; eid : EntityId)
  if is_production_circuit()
    addSubTemplate(eid, "player_afk")