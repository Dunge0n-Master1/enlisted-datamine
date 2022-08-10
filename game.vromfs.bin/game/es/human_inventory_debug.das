options no_aot

require ecs
require game.es.net_console_macro

[net_console_cmd(name="inventory.create_owned_item", hint="Create entity and set hero as owner")]
def inventory_create_owned_item_debug_cmd(item_template : string;
                                          items_count : int = 1;
                                          [[net_hero]] hero_eid : EntityId)
  for _i in range(0, items_count)
    createEntity(item_template) <| $(var init : ComponentsInitializer)
      set(init, "item__ownerEid", hero_eid)


[net_console_cmd(name="inventory.create_weap_slot_item", hint="Create entity, set hero as owner and put to weapon slot")]
def inventory_create_weap_slot_item_debug_cmd(item_template : string;
                                              gun_slot_id : int;
                                              [[net_hero]] hero_eid : EntityId)
  query(hero_eid) <| $ [es] (var human_weap__gunEids : EidList)
    destroyEntity(human_weap__gunEids[gun_slot_id])
    human_weap__gunEids[gun_slot_id] = createEntity(item_template) <| $(var init : ComponentsInitializer)
      set(init, "item__ownerEid", hero_eid)
      set(init, "gun__owner", hero_eid)