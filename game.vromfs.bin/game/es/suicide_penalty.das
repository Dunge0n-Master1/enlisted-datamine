require ecs
require game.es.app_common

[es(tag=server, on_appear, REQUIRE=player)]
def suicide_penalty_enable(evt : Event; eid : EntityId)
  addSubTemplate(eid, "suicide_penalty")
