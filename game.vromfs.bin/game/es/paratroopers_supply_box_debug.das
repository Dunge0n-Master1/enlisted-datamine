options no_aot
require ecs
require game.es.net_console_macro
require game.es.paratroopers_supply_box_common
require DagorConsole
require Dacoll

[net_console_cmd(name="paratroopers.spawn_box_at_pos")]
def debug_spawn_supply_box_at_pos(pos_x : float;
                                  pos_z : float;
                                  height : float = 450.;
                                  velocity_x : float = 0.;
                                  velocity_y : float = 0.;
                                  velocity_z : float = 0.;
                                  box_template : string = "paratroopers_supply_box_in_air";
                                  [[net_hero]] hero_eid : EntityId)
  let squad = get_Eid(hero_eid, "squad_member__squad") ?? INVALID_ENTITY_ID
  let pos = float3(pos_x, height, pos_z)
  let velocity = float3(velocity_x, velocity_y, velocity_z)
  spawn_supply_box(box_template, pos, squad, velocity, pos.xz)

[console_cmd(name="paratroopers.spawn_box_at_cam_trace")]
def debug_spawn_supply_box(height : float = 450.;
                           velocity_x : float = 0.;
                           velocity_y : float = 0.;
                           velocity_z : float = 0.;
                           box_template : string = "paratroopers_supply_box_in_air")
  find_query() <| $ [es] (transform : float3x4; camera__active : bool)
    if !camera__active
      return false
    var len = 1000.f
    var norm = float3()
    traceray_normalized(transform[3], transform[2], len, norm)
    var pos = transform[3] + transform[2] * len
    pos.y += height
    let velocity = float3(velocity_x, velocity_y, velocity_z)
    var hero_eid = INVALID_ENTITY_ID
    query() <| $ [es(REQUIRE=hero)] (eid : EntityId)
      hero_eid = eid
    if is_server()
      let squad = get_Eid(hero_eid, "squad_member__squad") ?? INVALID_ENTITY_ID
      spawn_supply_box(box_template, pos, squad, velocity, pos.xz)
    else

      exec_server_cmd("paratroopers.spawn_box_at_pos {pos.x} {pos.z} {pos.y} {velocity.x} {velocity.y} {velocity.z} {box_template} {hero_eid}")

    return true
