options no_aot
require ecs
require DagorDebug3D
require DagorConsole
require pathfinder
require strings
require danetlibs.pathfinder.main.pathfinder_common


[console_cmd(name="path.check_path")]
def path_check_path(sx, sy, sz, ex, ey, ez : float; dist_to_path : float = 10f; horz_threshold : float = -1f; max_vert_dist : float = 10f)
  let start = float3(sx, sy, sz)
  let end = float3(ex, ey, ez)
  let res = check_path(start, end, dist_to_path, horz_threshold, max_vert_dist)
  draw_debug_sphere_buffered(start, 1f, E3DCOLOR(0xFFFF0000), 12, 2000)
  draw_debug_sphere_buffered(end, 1f, E3DCOLOR(0xFF00FF00), 12, 2000)
  console_print("check_path({start}, {end}, {dist_to_path}, {horz_threshold}, {max_vert_dist}) == {res}")


[console_cmd(name="path.find_path")]
def path_find_path(sx, sy, sz, ex, ey, ez : float; dist_to_path : float = 10f; step_size : float = 10f; slop : float = 2.5)
  let start = float3(sx, sy, sz)
  let end = float3(ex, ey, ez)
  draw_debug_sphere_buffered(start, 1f, E3DCOLOR(0xFFFF0000), 12, 2000)
  draw_debug_sphere_buffered(end, 1f, E3DCOLOR(0xFF00FF00), 12, 2000)
  let res = find_path(start, end, dist_to_path, step_size, slop) <| $(path)
    console_print("path: len {length(path)}")
    if length(path) > 1
      var begin = path[0]
      print("{begin}")
      draw_debug_sphere_buffered(begin, 0.1f, E3DCOLOR(0xFF0000FF), 12, 2000)
      for i in range(1, length(path))
        let radius = saturate(0.1f + float(i) * 0.1f)
        draw_debug_sphere_buffered(path[i], radius, E3DCOLOR(0xFF0000FF), 12, 2000)
        draw_debug_line_buffered(begin, path[i], E3DCOLOR(0xFF0000FF), 2000)
        begin = path[i]
        print("{begin}")

  console_print("find_path({start}, {end}, {dist_to_path}, {step_size}, {slop}) == {res}")


[console_cmd(name="path.project_to_nearest_navmesh_point")]
def path_project_to_nearest_navmesh_point(sx, sy, sz : float; horz_extents : float = 0.5)
  let start = float3(sx, sy, sz)
  var pos = start
  let res = project_to_nearest_navmesh_point(pos, horz_extents)
  draw_debug_sphere_buffered(start, 0.25f, E3DCOLOR(0xFF0000FF), 12, 2000)
  console_print("project_to_nearest_navmesh_point({start}, {horz_extents}) == {res}, result position = {pos}")
  draw_debug_sphere_buffered(pos, 0.3f, E3DCOLOR(0xFF00FF00), 12, 2000)

[console_cmd(name="path.project_to_nearest_navmesh_point_3d")]
def path_project_to_nearest_navmesh_point_3d(sx, sy, sz : float; ext_x = 0.5; ext_y = 0.5; ext_z = 0.5)
  let start = float3(sx, sy, sz)
  var pos = start
  let ext = float3(ext_x, ext_y, ext_z)
  let res = project_to_nearest_navmesh_point(pos, ext)
  draw_debug_sphere_buffered(start, 0.25f, E3DCOLOR(0xFF0000FF), 12, 2000)
  console_print("project_to_nearest_navmesh_point({start}, {ext}) == {res}, result position = {pos}")
  draw_debug_sphere_buffered(pos, 0.3f, E3DCOLOR(0xFF00FF00), 12, 2000)


[console_cmd(name="path.query_navmesh_projections")]
def path_query_navmesh_projections(sx, sy, sz : float; horz_extents_x = 0.5; horz_extents_y = 0.5; horz_extents_z = 0.5; points_num = 8)
  let start = float3(sx, sy, sz)
  let extents = float3(horz_extents_x, horz_extents_y, horz_extents_z)
  draw_debug_sphere_buffered(start, 0.25f, E3DCOLOR(0xFF0000FF), 12, 2000)
  let res = query_navmesh_projections(start, extents, points_num) <| $(positions)
    for idx, pos in iter_range(positions), positions
      print("query_navmesh_projections({start}, {extents}) pos {idx}/{length(positions)} = {pos}")
      draw_debug_sphere_buffered(pos, 0.3f, E3DCOLOR(0xFF00FF00), 12, 2000)
  console_print("query_navmesh_projections({start}, {extents}) == {res}")


[console_cmd(name="path.get_lower_navmesh_pos")]
def path_get_lower_navmesh_pos(sx, sy, sz : float; ex, ey, ez : float; horz_extents : float = 0.5; dist_to_path : float = 10f; horz_threshold : float = -1f; max_vert_dist : float = 10f)
  let start = float3(sx, sy, sz)
  let end = float3(ex, ey, ez)
  let res = get_lower_navmesh_pos(end, horz_extents) <| $(p)
    return check_path(start, p, dist_to_path, horz_threshold, max_vert_dist)
  draw_debug_sphere_buffered(end, 0.25f, E3DCOLOR(0xFF0000FF), 12, 2000)
  console_print("get_lower_navmesh_pos({start}, {horz_extents}) == {res}, result position = {res}")
  if res is pos
    draw_debug_sphere_buffered(res as pos, 0.3f, E3DCOLOR(0xFF00FF00), 12, 2000)


[console_cmd(name="corridor.find_path")]
def corridor_find_path(sx, sy, sz, ex, ey, ez : float; jump_links = true)
  let start = float3(sx, sy, sz)
  let end = float3(ex, ey, ez)
  using() <| $(var path_corridor : dtPathCorridor#)
    path_corridor |> init_path_corridor()

    let inp = [[CorridorInput() start=start, target=end, distToPath=0.5, includeJumpLinks=jump_links]]
    let res = path_corridor |> set_path_corridor(inp, null)

    draw_debug_sphere_buffered(start, 1f, E3DCOLOR(0xFFFF0000), 12, 2000)
    draw_debug_sphere_buffered(end, 1f, E3DCOLOR(0xFF00FF00), 12, 2000)

    path_corridor |> corridor_getPath() <| $(list)
      let line = build_string() <| $(str)
        for l in list
          str |> format("%lld", l)
          str |> write("  ")
      console_print(line)

    path_corridor |> find_corridor_corners(1000) <| $(corners)
      console_print("corridor: corners len {length(corners)}")
      if length(corners) > 0
        var begin = corners[0]
        draw_debug_sphere_buffered(begin, 0.1f, E3DCOLOR(0xFF0000FF), 12, 2000)
        draw_debug_line_buffered(begin, start, E3DCOLOR(0xFF0000FF), 2000)
        for i in range(1, length(corners))
          let radius = saturate(0.1f + float(i) * 0.1f)
          draw_debug_sphere_buffered(corners[i], radius, E3DCOLOR(0xFF0000FF), 12, 2000)
          draw_debug_line_buffered(begin, corners[i], E3DCOLOR(0xFF0000FF), 2000)
          begin = corners[i]

    console_print("corridor({start}, {end}) == {res}")


[console_cmd(name="path.find_random_point_around_circle")]
def path_find_random_point(sx, sy, sz, radius : float)
  let start = float3(sx, sy, sz)
  var resPos : float3
  let res = find_random_point_around_circle(start, radius, resPos)

  draw_debug_sphere_buffered(start, 0.25f, E3DCOLOR(0xFF0000FF), 12, 2000)
  if res
    draw_debug_sphere_buffered(resPos, 0.3f, E3DCOLOR(0xFF00FF00), 12, 2000)
  else
    draw_debug_sphere_buffered(resPos, 0.3f, E3DCOLOR(0xFFFF0000), 12, 2000)
  console_print("find_random_point_around_circle({start}, {radius}) == {res}, result position = {resPos} distance = {distance(start, resPos)}")


[console_cmd(name="path.find_random_point_in_radius")]
def path_find_random_point_in_radius(sx, sy, sz, radius, extends : float)
  let start = float3(sx, sy, sz)
  var resPos : float3
  let res = find_random_point_in_radius(start, radius, extends, resPos)

  draw_debug_sphere_buffered(start, 0.25f, E3DCOLOR(0xFF0000FF), 12, 2000)
  if res
    draw_debug_sphere_buffered(resPos, 0.3f, E3DCOLOR(0xFF00FF00), 12, 2000)
  else
    draw_debug_sphere_buffered(resPos, 0.3f, E3DCOLOR(0xFFFF0000), 12, 2000)
  console_print("find_random_point_in_radius({start}, {radius}) == {res}, result position = {resPos} distance = {distance(start, resPos)}")


[console_cmd(name="path.draw_poly")]
def navmesh_draw_poly(sx, sy, sz : float; poly_id : uint64; dist_threshold = 0.5)
  var res : NavMeshTriangle
  let start = float3(sx, sy, sz)
  let success = find_nearest_triangle_by_pos(start, poly_id, dist_threshold, res)
  draw_debug_line_buffered(res.p0, res.p1, E3DCOLOR(0xFF0000FF), 30)
  draw_debug_line_buffered(res.p1, res.p2, E3DCOLOR(0xFF0000FF), 30)
  draw_debug_line_buffered(res.p2, res.p0, E3DCOLOR(0xFF0000FF), 30)
  console_print("find_nearest_triangle_by_pos({start}, {poly_id}) == {success}, result tri = {res}")


[console_cmd(name="path.find_poly")]
def navmesh_find_poly(sx, sy, sz : float; horz_dist : float = 1f)
  var res : NavMeshTriangle
  let start = float3(sx, sy, sz)
  let success = get_triangle_by_pos(start, horz_dist, res)
  draw_debug_line_buffered(res.p0, res.p1, E3DCOLOR(0xFF0000FF), 30)
  draw_debug_line_buffered(res.p1, res.p2, E3DCOLOR(0xFF0000FF), 30)
  draw_debug_line_buffered(res.p2, res.p0, E3DCOLOR(0xFF0000FF), 30)
  console_print("get_triangle_by_pos({start}, {horz_dist}) == {success}, result tri = {res}")
