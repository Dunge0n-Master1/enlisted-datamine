module dm_events shared
require ecs

[cpp_event(unicast)]
struct EventOnHitByProjectile
  localHitPos : float3
  localNormal : float3
  caliber : float
  bulletTypeId : int
  nodeId : int
  pierced : bool

[cpp_event(unicast)]
struct EventOnRicochet
  localHitPos : float3
  localNormal : float3
  caliber : float
  projectileEid : EntityId