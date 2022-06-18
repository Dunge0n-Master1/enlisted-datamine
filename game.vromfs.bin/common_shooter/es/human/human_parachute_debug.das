options no_aot
require ecs
require game.utils.hero
require game.es.net_console_macro
require common_shooter.es.human.human_parachute_common


[net_console_cmd(name="soldier.add_parachute", hint="Adds a parachute to the entity")]
def add_parachute_console_cmd([[net_hero]] hero_eid : EntityId; parachute_template : string = "parachute_canopy_item")
  parachute_create_for_eid(hero_eid, parachute_template)