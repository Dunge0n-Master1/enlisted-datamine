options no_aot

require ecs
require ecs.safe
require game.es.net_console_macro
require daslib/strings_boost
require danetlibs.console_commands.main.console_common

[net_console_cmd(name="inventory.create_owned_item", hint="Create entity and set hero as owner")]
def inventory_create_owned_item_debug_cmd(item_template : string;
                                          items_count : int = 1;
                                          [[net_hero]] hero_eid : EntityId)
  for _i in range(0, items_count)
    createEntity(item_template) <| $(var init : ComponentsInitializer)
      set(init, "item__lastOwner", hero_eid)
      set(init, "item__ownerEid", hero_eid)


[net_console_cmd(name="inventory.create_weap_slot_item", hint="Create entity, set hero as owner and put to weapon slot")]
def inventory_create_weap_slot_item_debug_cmd(item_template : string;
                                              gun_slot_id : int;
                                              ammo_index : int = 0;
                                              ammo_count : int = 5;
                                              [[net_hero]] hero_eid : EntityId)
  query(hero_eid) <| $ [es] (var human_weap__gunEids : EidList)
    destroyEntity(human_weap__gunEids[gun_slot_id])
    human_weap__gunEids[gun_slot_id] = createEntity(item_template) <| $(var init : ComponentsInitializer)
      set(init, "item__lastOwner", hero_eid)
      set(init, "item__ownerEid", hero_eid)
      set(init, "gun__owner", hero_eid)

    var gunTemplate = getTemplateByName(item_template)
    if gunTemplate == null
      gunTemplate = buildTemplateByName(item_template)
      if gunTemplate == null
        return

    let gunAmmoHolders = get_ecs_array(getTemplateComponent(*gunTemplate, "gun__ammoHolders"))

    let ammoTemplate = gunAmmoHolders?[ammo_index] ?? ""
    if ammoTemplate == ""
      return

    for _i in range(0, ammo_count)
      createEntity(ammoTemplate) <| $(var init : ComponentsInitializer)
        set(init, "item__ownerEid", hero_eid)


[console_processor]
def inventory_create_owned_item_debug_cmd_processor(args : array<string>;
                                                    collect : bool;
                                                    var hints : ConsoleProcessorHints)
  let cmd = "inventory.create_owned_item"
  if collect
    let inputs <- args[0] |> split(" ")
    if length(inputs) >= 2
      add_hints([[auto[] [[CommandArgDesc name="template_name", hintType=CommandArgHintType TemplateName]];
                         [[CommandArgDesc name="items_count", hintType=CommandArgHintType Default]];
                         [[CommandArgDesc name="eid", hintType=CommandArgHintType EntityId, defaultValue="0"]] ]],
                cmd, inputs, /*hints_count*/ 20, /*threshold_cam_distance_sq*/ 2500.0, hints)
  return false

[console_processor]
def inventory_create_weap_slot_item_debug_processor(args : array<string>;
                                                    collect : bool;
                                                    var hints : ConsoleProcessorHints)
  let cmd = "inventory.create_weap_slot_item"
  if collect
    let inputs <- args[0] |> split(" ")
    if length(inputs) >= 2
      add_hints([[auto[] [[CommandArgDesc name="template_name", hintType=CommandArgHintType TemplateName]];
                         [[CommandArgDesc name="slot", hintType=CommandArgHintType Default]];
                         [[CommandArgDesc name="eid", hintType=CommandArgHintType EntityId, defaultValue="0"]] ]],
                cmd, inputs, /*hints_count*/ 20, /*threshold_cam_distance_sq*/ 2500.0, hints)
  return false
