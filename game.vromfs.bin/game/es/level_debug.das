options no_aot
require ecs
require DagorConsole
require game.es.level_common

require gameObject

[console_cmd(name="level.indoor_pos")]
def check_is_pos_indoor()
  find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if camera__active
      let indoor = is_pos_indoor(transform[3])
      let msg = "position {transform[3]} is {indoor ? "indoor" : "outdoor"}"
      console_print(msg)
      print(msg)
    return camera__active
