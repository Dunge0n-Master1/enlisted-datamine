options no_aot
require ecs
require DagorConsole
require DagorSystem
require game.es.teleport_common
require game.utils.hero
require game.es.net_console_macro


[net_console_cmd(name="phys.teleport", hint="[x,y,z] [hero eid] Uses camera if no coords are provided")]
def console_phys_teleport(x, y, z, w : float = 0.0; [[net_hero]] hero_eid : EntityId)
  if y == 0.0 && z == 0.0 && w == 0.0
    let eid = x == 0.0 ? hero_eid : EntityId(uint(x))
    teleport_eid_to(eid, float3(0, 0, 0), true)
  else
    let eid = w == 0.0 ? hero_eid : EntityId(uint(w))
    teleport_eid_to(eid, float3(x, y, z), false)


[console_cmd(name="phys.teleport_to_camera")]
def console_phys_teleport_to_camera()
  let targetEid = get_controlled_hero()
  if targetEid == INVALID_ENTITY_ID
    return
  find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if camera__active
      teleport_or_request(targetEid, transform[3])
    return camera__active


[console_cmd(name="phys.position")]
def console_phys_position()
  let targetEid = get_controlled_hero()
  query(targetEid) <| $ [es] (transform : float3x4)
    let s = "{transform[3]}"
    set_clipboard_ansi_text(s)
    console_print("Phys pos: {s}")
