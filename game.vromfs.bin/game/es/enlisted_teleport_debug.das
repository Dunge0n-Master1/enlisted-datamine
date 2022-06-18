options no_aot
require ecs
require DagorConsole
require game.utils.hero
require enlisted.game.es.enl_teleport_common

[console_cmd(name="squad.teleport_to_camera")]
def console_squad_teleport_to_camera()
  let targetEid = get_controlled_hero()
  query(targetEid) <| $ [es] (squad_member__squad : EntityId)
    find_query() <| $ [es] (camera__active : bool; transform : float3x4)
      if camera__active
        teleport_squad_to_pos(squad_member__squad, transform[3])
      return camera__active