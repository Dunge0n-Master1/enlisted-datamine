require ecs
require DagorMath
require math.base
require enlisted.events_enlisted
require game.es.terraform.scenery_terraforming_common
require terraform

def push_op_end(var arr : Array&)
  using() <| $(var obj : Object)
    obj |> set("end", true)
    arr |> push(obj)

def push_op_elevs_add(var arr : Array&; idx : int; x : float; z : float; radius : float; alt : float)
  using() <| $(var obj : Object)
    obj |> set("add", float4(x, z, radius, alt))
    obj |> set("at", idx)
    arr |> push(obj)

def push_op_elevs_del(var arr : Array&; idx : int)
  using() <| $(var obj : Object)
    obj |> set("del", idx)
    arr |> push(obj)

def push_op_egras_add(var arr : Array&; idx : int; x : float; z : float; radius : float)
  using() <| $(var obj : Object)
    obj |> set("add2", float3(x, z, radius))
    obj |> set("at", idx)
    arr |> push(obj)

def push_op_egras_del(var arr : Array&; idx : int)
  using() <| $(var obj : Object)
    obj |> set("del2", idx)
    arr |> push(obj)

def get_op(arr : Array; at : int)
  if at < 0 || at >= length(arr)
    return ""
  let obj = get_ecs_object(arr[at])
  if get_bool(obj, "end") != null
    return "end"
  if get_Point4(obj, "add") != null
    return "add"
  if get_int(obj, "del") != null
    return "del"
  if get_Point3(obj, "add2") != null
    return "add2"
  if get_int(obj, "del2") != null
    return "del2"
  return ""

def get_op_int(arr : Array; at : int; name : string)
  let obj = get_ecs_object(arr[at])
  return get_int(obj, name) ?? -1

def get_op_p3(arr : Array; at : int; name : string)
  let obj = get_ecs_object(arr[at])
  return get_Point4(obj, name) ?? float4(0.0, 0.0, 0.0, 0.0)

def get_op_p4(arr : Array; at : int; name : string)
  let obj = get_ecs_object(arr[at])
  return get_Point4(obj, name) ?? float4(0.0, 0.0, 0.0, 0.0)


def forget_oldest_brush_ops(var arr : Array&)
  let cnt = length(arr)
  if cnt <= 0
    return
  var num = 0
  if get_op(arr, num) == "end"
    num += 1
  while num < cnt
    if get_op(arr, num) == "end"
      break
    ++num
  if num > 0
    arr |> erase(0, num)


[es(tag=gameClient)]
def terraforming_brush_es(evt : CmdTerraBrush; var terraform : TerraformComponent)
  find_query() <| $ [es] (var elevs : Array&;
                          var egras : Array&;
                          var terraforming__undo : Array&;
                          var terraforming__redo : Array&;
                          terraforming__maxUndo : int)
    let pos = float3(evt.pos.x, MAX_TERRAFORMING_INVALIDATE_HMAP_HEIGHT, evt.pos.z)
    let rad = evt.radius
    let alt = evt.alt

    if rad <= 0.0
      return true
    let altMode = alt != 0.0
    if !altMode && !evt.clearMode && !evt.eraseGrass
      return true

    let bmin = float3(pos.x - rad, MIN_TERRAFORMING_INVALIDATE_HMAP_HEIGHT, pos.z - rad)
    let bmax = float3(pos.x + rad, MAX_TERRAFORMING_INVALIDATE_HMAP_HEIGHT, pos.z + rad)
    var bbox = BBox3(bmin, bmax)

    var idxs : array<int>
    var rsum = 0.0
    if !evt.eraseGrass
      if !evt.clearMode
        for eidx in iter_range(elevs)
          let data = get_Point4(elevs[eidx]) ?? float4(0.0, 0.0, 0.0, 0.0)
          let dx = data.x - pos.x
          let dz = data.y - pos.z
          let dr = data.z
          if dx * dx + dz * dz < square(rad + dr) && abs(rad - dr) < rad * 0.9
            idxs |> push(eidx)
            rsum += square(dr)
      else
        var fidx = -1
        var frad = 0.0
        for eidx in iter_range(elevs)
          let data = get_Point4(elevs[eidx]) ?? float4(0.0, 0.0, 0.0, 0.0)
          let dx = data.x - pos.x
          let dz = data.y - pos.z
          let dr = data.z
          if dx * dx + dz * dz < square(rad + dr) && (fidx < 0 || dr < frad)
            fidx = eidx
            frad = dr
        if fidx >= 0
          idxs |> push(fidx)

    if length(idxs) == 0 && evt.clearMode && !evt.eraseGrass
      return true

    var gdxs : array<int>
    if evt.eraseGrass && evt.clearMode
      for gidx in iter_range(egras)
        let data = get_Point3(egras[gidx]) ?? float3(0.0, 0.0, 0.0)
        let dx = data.x - pos.x
        let dz = data.y - pos.z
        let dr = data.z
        if dx * dx + dz * dz < square(rad + dr)
          gdxs |> push(gidx)
      if length(gdxs) == 0
        return true

    if terraforming__maxUndo > 0
      while length(terraforming__undo) >= terraforming__maxUndo
        forget_oldest_brush_ops(terraforming__undo)

    push_op_end(terraforming__undo)

    var egrasBase = 0
    var egrasNum  = 0
    if evt.eraseGrass
      if !evt.clearMode
        apply_erase_grass(evt.pos, evt.radius);
        push_op_egras_del(terraforming__undo, length(egras))
        egras |> push(float3(pos.x, pos.z, rad))
        egrasBase = length(egras) - 1
        egrasNum  = 1
      else
        let base = length(gdxs) - 1
        for i in iter_range(gdxs)
          let gidx = gdxs[base - i] // last to first
          let data = get_Point3(egras[gidx]) ?? float3(0.0, 0.0, 0.0)
          let dpos = float3(data.x, 0.0, data.y)
          let drad = data.z
          push_op_egras_add(terraforming__undo, gidx, dpos.x, dpos.z, drad)
          egras |> erase(gidx) // FIXME: grass restoration visually not visible

    if evt.clearMode && !evt.eraseGrass
      let base = length(idxs) - 1
      for i in iter_range(idxs)
        let eidx = idxs[base - i] // last to first
        let data = get_Point4(elevs[eidx]) ?? float4(0.0, 0.0, 0.0, 0.0)
        let dpos = float3(data.x, MAX_TERRAFORMING_INVALIDATE_HMAP_HEIGHT, data.y)
        let drad = data.z
        let dalt = data.w
        apply_elevation(terraform, bbox, dpos, drad, -dalt)
        push_op_elevs_add(terraforming__undo, eidx, dpos.x, dpos.z, drad, dalt)
        elevs |> erase(eidx)
    elif altMode
      let maxRadSum = rad * rad * 10.0
      if rsum > maxRadSum
        let cnt = length(idxs)
        var best_i = -1
        var best_j = -1
        var best_d = 0.0
        for i in range(0, cnt)
          let eidx1 = idxs[i]
          let data1 = get_Point4(elevs[eidx1]) ?? float4(0.0, 0.0, 0.0, 0.0)
          for j in range(i + 1, cnt)
            let eidx2 = idxs[j]
            let data2 = get_Point4(elevs[eidx2]) ?? float4(0.0, 0.0, 0.0, 0.0)
            var dd = square(data1.x - data2.x) + square(data1.y - data2.y) + square(data1.z - data2.z) + square(data1.w - data2.w)
            dd += square(rad - data1.z) // to avoid touching too different radius elevations
            dd += square(rad - data2.z) // to avoid touching too different radius elevations
            if best_i < 0 || dd < best_d
              best_i = i
              best_j = j
              best_d = dd
        if best_i >= 0
          // delete second first to keep indexing (best_j > best_i)
          let eidx2 = idxs[best_j]
          let data2 = get_Point4(elevs[eidx2]) ?? float4(0.0, 0.0, 0.0, 0.0)
          let dpos2 = float3(data2.x, MAX_TERRAFORMING_INVALIDATE_HMAP_HEIGHT, data2.y)
          let drad2 = data2.z
          let dalt2 = data2.w
          apply_elevation(terraform, bbox, dpos2, drad2, -dalt2)
          push_op_elevs_add(terraforming__undo, eidx2, dpos2.x, dpos2.z, drad2, dalt2)
          elevs |> erase(eidx2)

           // then delete first
          let eidx1 = idxs[best_i]
          let data1 = get_Point4(elevs[eidx1]) ?? float4(0.0, 0.0, 0.0, 0.0)
          let dpos1 = float3(data1.x, MAX_TERRAFORMING_INVALIDATE_HMAP_HEIGHT, data1.y)
          let drad1 = data1.z
          let dalt1 = data1.w
          apply_elevation(terraform, bbox, dpos1, drad1, -dalt1)
          push_op_elevs_add(terraforming__undo, eidx1, dpos1.x, dpos1.z, drad1, dalt1)
          elevs |> erase(eidx1)

          // and then add mixed elevation
          let mpos = (dpos1 + dpos2) * 0.5
          let mrad = (drad1 + drad2) * 0.5
          let malt = dalt1 + dalt2
          apply_elevation(terraform, bbox, mpos, mrad, malt)
          push_op_elevs_del(terraforming__undo, length(elevs))
          elevs |> push(float4(mpos.x, mpos.z, mrad, malt))

    if altMode
      apply_elevation(terraform, bbox, pos, rad, alt)
      push_op_elevs_del(terraforming__undo, length(elevs))
      elevs |> push(float4(pos.x, pos.z, rad, alt))

    terraforming__redo |> clear()

    broadcastEvent([[CmdTerraUpdateRender hmapBoxMin=bbox.boxMin, hmapBoxMax=bbox.boxMax, egrasBase=egrasBase, egrasNum=egrasNum]])
    return true


def apply_undoredo(var terraform : TerraformComponent;
                   var elevs : Array&;
                   var egras : Array&;
                   var src : Array&;
                   var dst : Array&)
  if length(src) <= 0
    return

  push_op_end(dst)

  var bbox = BBox3(float3(0.0, MIN_TERRAFORMING_INVALIDATE_HMAP_HEIGHT, 0.0), 0.0)
  var has_bbox = false

  while length(src) > 0
    let idx = length(src) - 1
    let op = get_op(src, idx)

    if op == "end"
      src |> pop()
      break

    if op == "add"
      let elev = get_op_p4(src, idx, "add")
      let eidx = get_op_int(src, idx, "at")
      let pos = float3(elev.x, MAX_TERRAFORMING_INVALIDATE_HMAP_HEIGHT, elev.y)
      let rad = elev.z
      let alt = elev.w
      if !has_bbox
        has_bbox = true
        bbox = BBox3(pos, 2.0 * rad)
      apply_elevation(terraform, bbox, pos, rad, alt)
      push_op_elevs_del(dst, length(elevs))
      elevs |> push(eidx, elev)
      src |> pop()
      continue

    if op == "del"
      let del_idx = get_op_int(src, idx, "del")
      if del_idx < 0 || del_idx >= length(elevs)
        src |> clear()
        dst |> clear()
        return
      let elev = get_Point4(elevs[del_idx]) ?? float4(0.0, 0.0, 0.0, 0.0)
      let pos = float3(elev.x, MAX_TERRAFORMING_INVALIDATE_HMAP_HEIGHT, elev.y)
      let rad = elev.z
      let alt = elev.w
      apply_elevation(terraform, bbox, pos, rad, -alt)
      push_op_elevs_add(dst, del_idx, elev.x, elev.y, elev.z, elev.w)
      elevs |> erase(del_idx)
      src |> pop()
      continue

    if op == "add2"
      let egra = get_op_p3(src, idx, "add2")
      let eidx = get_op_int(src, idx, "at")
      push_op_egras_del(dst, length(egras))
      egras |> push(eidx, egra) // FIXME: grass re-deletion not required for now
      src |> pop()
      continue

    if op == "del2"
      let del_idx = get_op_int(src, idx, "del2")
      if del_idx < 0 || del_idx >= length(elevs)
        src |> clear()
        dst |> clear()
        return
      let egra = get_Point3(egras[del_idx]) ?? float3(0.0, 0.0, 0.0)
      push_op_egras_add(dst, del_idx, egra.x, egra.y, egra.z)
      egras |> erase(del_idx); // FIXME: grass restoration visually not visible
      src |> pop()
      continue

    src |> pop()

  broadcastEvent([[CmdTerraUpdateRender hmapBoxMin=bbox.boxMin, hmapBoxMax=bbox.boxMax, egrasBase=0, egrasNum=0]])

[es(tag=gameClient)]
def terraforming_undo_es(evt : CmdTerraBrushUndo; var terraform : TerraformComponent)
  find_query() <| $ [es] (var elevs : Array&;
                          var egras : Array&;
                          var terraforming__undo : Array&;
                          var terraforming__redo : Array&)
    apply_undoredo(terraform, elevs, egras, terraforming__undo, terraforming__redo)
    return true

[es(tag=gameClient)]
def terraforming_redo_es(evt : CmdTerraBrushRedo; var terraform : TerraformComponent)
  find_query() <| $ [es] (var elevs : Array&;
                          var egras : Array&;
                          var terraforming__undo : Array&;
                          var terraforming__redo : Array&)
    apply_undoredo(terraform, elevs, egras, terraforming__redo, terraforming__undo)
    return true
