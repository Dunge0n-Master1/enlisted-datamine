options no_aot
require ecs
require DagorConsole


[console_cmd(name="armor_analyzer.mode", hint="[mode 0 - none, 1 - armor, 2 - xray]")]
def console_armor_analyzer_mode(mode : int = -1)
  query() <| $ [es] (var armor_analyzer__mode : int&)
    if mode == -1
      console_print("Armor analyzer mode is {armor_analyzer__mode}")
    else
      armor_analyzer__mode = mode

[console_cmd(name="armor_analyzer.set_screen_pos", hint="x y")]
def console_armor_analyzer_set_screen_pos(x : float; y : float)
  query() <| $ [es] (var armor_analyzer__screenPos : float2&)
    armor_analyzer__screenPos = float2(x, y)
