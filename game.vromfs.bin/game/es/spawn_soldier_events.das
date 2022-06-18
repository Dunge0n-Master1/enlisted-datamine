module spawn_soldier_events shared
require ecs

[event(unicast)]
struct SoldierSpawnEquipmentCreated {}

[event(unicast)]
struct FinalizeSoldierCreation
  spawnerEid : EntityId
