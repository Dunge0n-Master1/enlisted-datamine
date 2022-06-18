require ecs
require vehicle

[es(on_appear)]
def set_groun_collision_softness(evt : Event; groundCollisionSoftness : float; var vehicle_net_phys : VehiclePhysActor)
  vehicle_net_phys.phys.groundCollisionSoftness = groundCollisionSoftness