options no_aot

require ecs
require game.es.net_console_macro


[net_console_cmd(name="battle_area.disable_hero_damage", hint="Disable damaging the hero when he is outside a battle area")]
def battle_area_disable_hero_damage_debug_cmd([[net_hero]] hero_eid : EntityId)
  addSubTemplate(hero_eid, "disable_battle_area_damage")
