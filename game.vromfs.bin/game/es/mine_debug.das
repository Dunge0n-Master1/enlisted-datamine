options no_aot

require ecs
require game.es.net_console_macro

[net_console_cmd(name="mine.addToHero")]
def mine_add_to_hero_debug_cmd(mines_count : int = 3;
                               mine_template : string = "usa_antitank_mine";
                               [[net_hero]] hero_eid : EntityId)
  for i in range(0, mines_count)
    createEntity("{mine_template}+item") <| $(var init : ComponentsInitializer)
      set(init, "item__ownerEid", hero_eid)