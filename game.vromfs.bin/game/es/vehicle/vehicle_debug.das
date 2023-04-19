options no_aot
require ecs
require DagorConsole
require DagorDebug3D
require DngNet
require game.es.net_console_macro
require game.es.server_debug_common
require game.utils.team

[console_cmd(name="vehicle.highlight_all")]
def highlight_all_vehicles_debug()
  query() <| $ [es(REQUIRE=vehicle)] (transform : float3x4)
    let color = E3DCOLOR(0xFFFF00FF)
    let frames = 30000
    draw_debug_sphere_buffered(transform[3], 1f, color, 12, frames)
    draw_debug_line_buffered(transform[3], transform[3] + float3(0, 1000, 0), color, frames)

[net_console_cmd(name="vehicle.reviveTanks")]
def vehicle_reviveTanks()
  query() <| $ [es(REQUIRE=(isTank, deadEntity))] (eid : EntityId; transform : float3x4; team : int = TEAM_UNASSIGNED)
    let tankTemplate = remove_sub_template_name(getEntityTemplateName(eid), "dead_entity")
    destroyEntity(eid)
    createEntity(tankTemplate) <| $(var init)
      init |> set("transform", transform)
      init |> set("team", team)
