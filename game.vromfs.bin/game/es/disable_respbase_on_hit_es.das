require ecs
require common_shooter.events_common_shooter
require math
require math.base

[es(tag=server)]
def disable_respbase_on_hit_es(evt : EventOnEntityHit)
  query(evt.victim) <| $ [es] (transform : float3x4;
                               spawn_immunity__initialPos : float3 const&;
                               spawn_immunity__immuneDistance : float;
                               lastRespawnBaseEid : ecs::EntityId)
    if distance_sq(spawn_immunity__initialPos, transform[3]) <= square(spawn_immunity__immuneDistance)
      ecs::query(lastRespawnBaseEid) <| $ [es(REQUIRE=temporaryRespawnbase)] (var active : bool&)
        active = false