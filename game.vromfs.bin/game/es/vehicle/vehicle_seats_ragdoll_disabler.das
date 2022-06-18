require ecs

[es(tag=render, on_appear, track=human_anim__vehicleSelected)]
def vehicle_seats_disable_ragdoll(evt : Event; human_anim__vehicleSelected : EntityId; var ragdoll__isAllowed : bool&)
  ragdoll__isAllowed = !has(human_anim__vehicleSelected, "vehicle_seats__disableRagdoll")