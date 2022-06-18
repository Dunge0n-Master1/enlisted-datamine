require ecs

[es(tag=server, REQUIRE_NOT=controlledByAiGunner, track=turret__isControlledByAi, on_appear)]
def track_turret_controlled_by_ai_enable(evt : Event; eid : EntityId; turret__isControlledByAi : bool)
  if turret__isControlledByAi
    addSubTemplate(eid, "controlled_by_ai_gunner")

[es(tag=server, REQUIRE=controlledByAiGunner, track=turret__isControlledByAi, on_appear)]
def track_turret_controlled_by_ai_disable(evt : Event; eid : EntityId; turret__isControlledByAi : bool)
  if !turret__isControlledByAi
    removeSubTemplate(eid, "controlled_by_ai_gunner")
