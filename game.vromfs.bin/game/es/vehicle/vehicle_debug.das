options no_aot
require ecs
require DagorConsole
require DagorDebug3D

[console_cmd(name="vehicle.highlight_all")]
def highlight_all_vehicles_debug()
  query() <| $ [es(REQUIRE=vehicle)] (transform : float3x4)
    let color = E3DCOLOR(0xFFFF00FF)
    let frames = 30000
    draw_debug_sphere_buffered(transform[3], 1f, color, 12, frames)
    draw_debug_line_buffered(transform[3], transform[3] + float3(0, 1000, 0), color, frames)
