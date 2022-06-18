options no_aot
require ecs
require DagorConsole
require Dacoll
require DagorDebug3D
require game.utils.hero

[console_cmd(name="hmap.draw", hint="<mode 0 - draw by sphere_cast, 1 - draw by traceray> [width=16] [size=0.1] [frames=1000]")]
def draw_hmap(mode : int; width = 16; size = 0.1; frames = 1000)
  find_query() <| $ [es(REQUIRE=hero)] (transform : float3x4)

    let center = transform[3]
    let from = center + float3(0., 2., 0.)

    let dir = float3(0., -1., 0.)
    for x in range(-width, width)
      for z in range(-width, width)
        let offset = float3(float(x), 0., float(z)) * size
        var t = 4.f
        if mode == 0
          let prevStep = dacoll_set_hmap_step(1)
          let to = from + offset + dir * t
          var out = ShapeQueryOutput()
          if sphere_cast(from + offset, to, 0.05, out)
            draw_debug_sphere_buffered(out.res, 0.01f, E3DCOLOR(0xFF0000FF), 12, frames)
          dacoll_set_hmap_step(prevStep)
        elif mode == 1
          var norm = float3()
          if traceray_normalized(from + offset, dir, t, norm)
            let hit = from + offset + dir * t
            draw_debug_sphere_buffered(hit, 0.01f, E3DCOLOR(0xFF0000FF), 12, frames)
    return true
