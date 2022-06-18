options no_aot
require ecs
require DagorConsole


[console_cmd(name="app.debug_projectiles")]
def force_crosshair_debug_cmd(state : int = -1)
  query() <| $ [es] (var gun__projectileDebug : bool&)
    if state < 0
      gun__projectileDebug = !gun__projectileDebug
    elif state == 0
      gun__projectileDebug = false
    else
      gun__projectileDebug = true