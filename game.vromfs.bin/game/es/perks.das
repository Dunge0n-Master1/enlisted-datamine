require ecs
require ecs.common
require game.es.events
require DagorSystem

[es]
def on_perk_used_es(evt : EventOnLootItemUsed; eid : EntityId; var perk__useCount : int&; perk__maxUseCount : int)
  perk__useCount++
  if perk__useCount >= perk__maxUseCount
    ecs::query(evt.target) <| $ [es] (human_equipment__slots : ecs::Object)
      for equipItem in human_equipment__slots
        let item = get_ecs_object(equipItem.value)
        if item != null
          let itemEid = get_Eid(item, "item") ?? ecs::INVALID_ENTITY_ID
          if itemEid == eid
            sendEventImmediate(evt.target, [[CmdEquipItem itemEid=INVALID_ENTITY_ID, slotName=equipItem.key]])
            destroyEntity(eid)
