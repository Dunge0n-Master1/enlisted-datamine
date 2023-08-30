require ecs

[es(tag=render, on_appear, track=human_anim__vehicleSelected)]
def vehicle_seats_disable_ragdoll(evt : Event; human_anim__vehicleSelected : EntityId; var ragdoll__isAllowed : bool&)
  ragdoll__isAllowed = !has(human_anim__vehicleSelected, "vehicle_seats__disableRagdoll")

[es(tag=render, on_appear, REQUIRE=vehicle_seats__disableRagdoll)]
def vehicle_seats_disable_ragdoll_on_vehicle_appear(evt : Event; eid : EntityId)
  query() <| $ [es] (human_anim__vehicleSelected : EntityId;
                     var ragdoll__isAllowed : bool&)
    if human_anim__vehicleSelected == eid
      ragdoll__isAllowed = false
