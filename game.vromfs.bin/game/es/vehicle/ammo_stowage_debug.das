options no_aot
require ecs
require ecs.ecs_template
require dm
require CollRes
require DagorConsole

[ecs_template]
struct ammo_stowage_debug_draw
  ammoStowageDebugDraw : Tag

[console_cmd(name="ammo_stowage.draw")]
def ammo_stowage_toggle_debug_draw()
  var exists = false
  query() <| $ [es(REQUIRE=ammoStowageDebugDraw)] (eid : EntityId)
    destroyEntity(eid)
    exists = true
  if !exists
    createEntity("ammo_stowage_debug_draw")

[es(tag=(dev, render), no_order, REQUIRE=ammoStowageDebugDraw)]
def ammo_stowage_draw_parts(info : UpdateStageInfoAct)
  query() <| $ [es] (ammo_cluster__mapSlotToPartId : IntList; ammo_cluster__vehicleEid : EntityId)
    query(ammo_cluster__vehicleEid) <| $ [es] (damage_model : DamageModel; collres : CollisionResource; var dm_debug__draw_parts_mask : BoolList&)
      assume parts = damage_model.dmData.parts
      for partId in ammo_cluster__mapSlotToPartId
        if uint(partId) < uint(length(parts))
          let node = damage_model.dmData |> get_collision_node_id(partId)
          let nodeCount = collres |> collres_get_nodesCount()
          if length(dm_debug__draw_parts_mask) < nodeCount
            dm_debug__draw_parts_mask |> resize(nodeCount)
          dm_debug__draw_parts_mask[node] = parts[partId].enabled

[es(on_disappear, REQUIRE=ammoStowageDebugDraw)]
def disable_ammo_stowage_debug_draw(evt : Event)
  query() <| $ [es] (ammo_cluster__vehicleEid : EntityId)
    query(ammo_cluster__vehicleEid) <| $ [es] (var dm_debug__draw_parts_mask : BoolList&)
      dm_debug__draw_parts_mask |> clear()