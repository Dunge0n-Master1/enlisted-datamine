require ecs
require game.es.lut_switcher_common

[es(track=(isOutsideBattleArea, input__enabled), on_appear, REQUIRE=(hero, watchedByPlr))]
def tonemapper_switcher_outside_battle_area(evt : Event; isOutsideBattleArea : bool; input__enabled : bool)
  query() <| $ [es] (var color_grading_items : Array; color_grading__outOfbattleArea : Object)
    switch_color_grading(ecs_hash("battle_area"), color_grading_items, color_grading__outOfbattleArea, isOutsideBattleArea && input__enabled)

[es(on_event=EventEntityDestroyed, REQUIRE=watchedByPlr)]
def enl_disable_color_grading_on_destroy_es(evt : Event)
  query() <| $ [es(REQUIRE=color_grading__outOfbattleArea)] (var color_grading_items : Array)
    remove_grading(ecs_hash("battle_area"), color_grading_items)
