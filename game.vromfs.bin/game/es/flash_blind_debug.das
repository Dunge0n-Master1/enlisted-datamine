options no_aot
require ecs
require ecs.common
require game.utils.hero
require DagorConsole
require game.es.flash_blind_common

[console_cmd(name="affect.flash_blind")]
def console_flash_blind(intensity : float)
  let hero = get_controlled_hero()
  fire_flash_blind_affect(hero, intensity)
