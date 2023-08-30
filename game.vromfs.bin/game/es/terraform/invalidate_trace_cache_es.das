require ecs
require DngHuman
require vehicle
require Dacoll
require DagorMath
require Grid
require GridCollision
require enlisted.events_enlisted

def invalidate_trace_cache(var traceHandle)
  if traceHandle != null
    *traceHandle |> markDirty()

def private trace_cache_invalidation_impl(pos : float3; radius : float)
  for_each_entity_in_grid(ecs_hash("humans"), BSphere3(pos, radius), GridEntCheck POS) <| $(eid : EntityId)
    query(eid) <| $ [es] (var human_net_phys : HumanActor)
      human_net_phys.phys |> human_phys_getTraceHandle() |> invalidate_trace_cache()

    query(eid) <| $ [es] (var vehicle_net_phys : VehiclePhysActor)
      vehicle_net_phys.phys |> vehicle_phys_getTraceHandle() |> invalidate_trace_cache()

[es(REQUIRE=terraform)]
def trace_cache_invalidation_es(evt : CmdDig)
  trace_cache_invalidation_impl(evt.pos, 2. * evt.radius)

[es(REQUIRE=terraform)]
def trace_cache_invalidation_on_bomb_crater_es(evt : EventBombCraterPartTerraformed)
  if evt.shouldDig
    trace_cache_invalidation_impl(evt.partPos, 2. * evt.partRadius)
