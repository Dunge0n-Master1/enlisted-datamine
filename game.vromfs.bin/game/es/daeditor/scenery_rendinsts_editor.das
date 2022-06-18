require ecs
require enlisted.events_enlisted
require DagorConsole
require DagorDebug3D
require DagorEditor
require RendInst


def is_nearly_same_float3(a, b)
  let eps = 0.001
  if abs(a.x - b.x) > eps
    return false
  if abs(a.y - b.y) > eps
    return false
  if abs(a.z - b.z) > eps
    return false
  return true

def is_nearly_same_ri_tm(a, b)
  if !is_nearly_same_float3(a[0], b[0])
    return false
  if !is_nearly_same_float3(a[1], b[1])
    return false
  if !is_nearly_same_float3(a[2], b[2])
    return false
  if !is_nearly_same_float3(a[3], b[3])
    return false
  return true


[es(tag=gameClient)]
def scenery_rendinsts_add_selected_es(evt : CmdRIToolAddSelected;
                                      var rendinsts_removes__selected : Array&)
  if evt.kind == "select"
    rendinsts_removes__selected |> clear()

  if evt.kind == "select" || evt.kind == "multiselect"
    using() <| $(var obj : Object#)
      obj |> set("tm", evt.tm)
      obj |> set("name", evt.name)
      obj |> set("bsph", evt.bsph)
      obj |> set("unbaked", evt.unbaked)
      rendinsts_removes__selected |> push(obj)

  if evt.kind == "deselect"
    for i in iter_range(rendinsts_removes__selected)
      let obj = get_ecs_object(rendinsts_removes__selected[i])
      if obj == null
        continue
      let tm = get_TMatrix(*obj, "tm") ?? float3x4()
      let name = get_string(*obj, "name", "")
      if name == evt.name && is_nearly_same_ri_tm(tm, evt.tm)
        rendinsts_removes__selected |> erase(i)
        break

[es(tag=gameClient)]
def scenery_rendinsts_clear_selected_es(evt : CmdRIToolClearSelected;
                                        var rendinsts_removes__selected : Array&)
  rendinsts_removes__selected |> clear()

[es(tag=gameClient, tag=render, no_order)]
def scenery_rendinsts_draw_selected_es(evt : UpdateStageInfoRenderDebug;
                                       rendinsts_removes__selected : Array)
  for item in rendinsts_removes__selected
    let obj = get_ecs_object(item)
    if obj == null
      continue
    let bsph = get_Point4(*obj, "bsph") ?? float4(0.0, 0.0, 0.0, 0.0)
    let pos = float3(bsph.x, bsph.y, bsph.z)
    let rad = bsph.w
    let unbaked = get_bool(*obj, "unbaked") ?? false
    if !unbaked
      draw_debug_sphere_buffered(pos, rad, E3DCOLOR(0xFFFFFFFF), 24, 1)
    else
      draw_debug_sphere_buffered(pos, rad - 0.005, E3DCOLOR(0xFFEE00EE), 24, 1)
      draw_debug_sphere_buffered(pos, rad,         E3DCOLOR(0xFFEE00EE), 24, 1)


[es(tag=gameClient)]
def scenery_rendinsts_create_rendinst_es(evt : CmdRIToolCreateRendInst)
  let createdEid = entity_object_editor_createEntityDirectRIExtra(evt.tpl, evt.tm, evt.name)
  if createdEid == INVALID_ENTITY_ID
    return

  if evt.tpl == "rebaked_rendinst"
    return

  entity_object_editor_addEntity(createdEid)

  entity_obj_editor_saveComponent(createdEid, "transform")
  entity_obj_editor_saveComponent(createdEid, "ri_extra__name")

  if evt.tpl == "unbaked_rendinst"
    set(createdEid, "rebake__tm", evt.tm)
    set(createdEid, "rebake__name", evt.name)
    entity_obj_editor_saveComponent(createdEid, "rebake__tm")
    entity_obj_editor_saveComponent(createdEid, "rebake__name")
