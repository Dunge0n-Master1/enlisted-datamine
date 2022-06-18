require ecs
require EnlistedNet
require inventory
require game.es.events
require math
require math.base
require strings
require DagorSystem
require DagorMath


[es(tag=server)]
def use_item_human_effect_es(evt : EventOnItemStartUse; item__ownerOnUseEffectTemplate : string; item__useTime : float; var item__ownerOnUseEffectEid : EntityId&)
  item__ownerOnUseEffectEid = createEntity(item__ownerOnUseEffectTemplate) <| $(var init : ComponentsInitializer)
    set(init, "game_effect__attachedTo", evt.target)
    set(init, "game_effect__timeToDestroy", item__useTime)


[es(tag=server)]
def drop_loot_es(evt : CmdDropLoot; eid : EntityId)
  drop_loot(eid, evt.detachWeapMods, false)


[es(tag=server, REQUIRE=dropItemsOnUse)]
def drop_items_on_use_es(evt : EventOnLootItemUsed)
  sendEvent(evt.target, [[CmdDropLoot detachWeapMods=true]])
