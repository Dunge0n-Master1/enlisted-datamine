require ecs
require DagorMath
require enlisted.events_enlisted
require WorldRenderer

[es(tag=render)]
def terraforming_update_render_es(evt : CmdTerraUpdateRender)
  var bbox = BBox3(evt.hmapBoxMin, evt.hmapBoxMax)
  find_query() <| $ [es] (egras : Array)
    var base = evt.egrasBase
    var num  = evt.egrasNum
    if base < 0
      num += base
      base = 0
    if base + num > length(egras)
      num = length(egras) - base
    for i in range(0, num)
      let data = get_Point3(egras[base + i]) ?? float3(0.0, 0.0, 0.0)
      let pos = float3(data.x, 0.0, data.y)
      let rad = data.z
      if rad > 0.0
        erase_grass(pos, rad)
        bbox3_add(bbox, BBox3(pos, 2.0 * rad))
    return true
  invalidate_after_heightmap_change(bbox)
