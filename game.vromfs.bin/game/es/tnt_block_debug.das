options no_aot

require ecs
require game.es.net_console_macro

[net_console_cmd(name="tnt_block.addTestSet")]
def tnt_block_add_test_set_debug_cmd(tnt_block_template : string = "ussr_tnt_block"; tnt_blocks_count : int = 5; [[net_hero]] hero_eid : EntityId)
  for _i in range(0, tnt_blocks_count)
    createEntity(tnt_block_template) <| $(var init : ComponentsInitializer)
      set(init, "item__ownerEid", hero_eid)

  query(hero_eid) <| $ [es] (itemContainer : EidList)
    var hasExploder = false
    for itemEid in itemContainer
      hasExploder ||= has(itemEid, "tntBlockExploder")

    if !hasExploder
      createEntity("tnt_block_exploder") <| $(var init : ComponentsInitializer)
        set(init, "item__ownerEid", hero_eid)

[net_console_cmd(name="tnt_block.removeAllInstalled")]
def tnt_block_add_test_set_debug_cmd([[net_hero]] hero_eid : EntityId)
  query() <| $ [es] (eid : EntityId; tnt_block__humanOwnerEid : EntityId)
    if tnt_block__humanOwnerEid == hero_eid
      destroyEntity(eid)
