require ecs
require RendInst
require DagorMath
require DagorConsole
require DagorDebug3D
require DagorEditor
require enlisted.events_enlisted
require game.es.terraform.scenery_rendinsts_common


def unbake_door(eid, tm, name; var riunb : Array&)
  if has(eid, "clonedRIDoorTag")
    entity_object_editor_selectEntity(eid, true)
    return

  let templ = getEntityTemplateName(eid)
  let tpl = add_sub_template_name(templ, "unbaked_door_ri")
  let createdEid = entity_object_editor_createEntityDirectRIExtra(tpl, tm, name)
  if createdEid == INVALID_ENTITY_ID
    return

  entity_object_editor_addEntity(createdEid)

  entity_obj_editor_saveComponent(createdEid, "transform")
  entity_obj_editor_saveComponent(createdEid, "ri_extra__name")

  set(createdEid, "rebake__tm", tm)
  set(createdEid, "rebake__name", name)
  entity_obj_editor_saveComponent(createdEid, "rebake__tm")
  entity_obj_editor_saveComponent(createdEid, "rebake__name")

  entity_object_editor_selectEntity(createdEid, true)

  using() <| $(var obj : Object)
    obj |> set("tm", tm)
    obj |> set("name", name)
    riunb |> push(obj)

  destroyEntity(eid)

def remove_door(eid, tm, name; var rirmv : Array&)
  if has(eid, "clonedRIDoorTag")
    destroyEntity(eid)
    return

  using() <| $(var obj : Object)
    obj |> set("tm", tm)
    obj |> set("name", name)
    rirmv |> push(obj)

  destroyEntity(eid)

def clone_door(eid, tm, name)
  let templ = getEntityTemplateName(eid)
  let tpl = has(eid, "clonedRIDoorTag") ? templ : add_sub_template_name(templ, "unbaked_door_ri")
  let createdEid = entity_object_editor_createEntityDirectRIExtra(tpl, tm, name)
  if createdEid == INVALID_ENTITY_ID
    return

  entity_object_editor_addEntity(createdEid)

  entity_obj_editor_saveComponent(createdEid, "transform")
  entity_obj_editor_saveComponent(createdEid, "ri_extra__name")

  entity_object_editor_selectEntity(createdEid, true)

[es(tag=gameClient, on_event=EventEditorEntityMoved, REQUIRE=isDoor)]
def update_door_initial_transform_when_moved_in_editor_es(evt : Event;
                                                          transform : float3x4;
                                                          var initialTransform : float3x4&)
  initialTransform = transform


[es(tag=gameClient)]
def scenery_rendinsts_unbake_rendinst_es(evt : CmdRIToolUnbakeRendInst;
                                         var riunb : Array&)
  var rebaked = false
  if evt.eid != INVALID_ENTITY_ID
    if has(evt.eid, "enbakedRITag")
      reCreateEntityFrom(evt.eid, remove_sub_template_name(evt.eid, "enbaked_ri"))
      entity_obj_editor_saveDelTemplate(evt.eid, "enbaked_ri", false/*use_undo*/)
      entity_object_editor_selectEntity(evt.eid, true)
      return
    if has(evt.eid, "unbakedRendInstTag") || has(evt.eid, "gameRendInstTag")
      entity_object_editor_selectEntity(evt.eid, true)
      return
    if has(evt.eid, "isDoor")
      unbake_door(evt.eid, evt.tm, evt.name, riunb)
      return
    rebaked = has(evt.eid, "rebakedRendInstTag")
    if !rebaked
      return

  if rebaked
    destroyEntity(evt.eid)
  elif !remove_rendinst(evt.tm, evt.name)
    return

  using() <| $(var obj : Object)
    obj |> set("tm", evt.tm)
    obj |> set("name", evt.name)
    riunb |> push(obj)

  broadcastEventImmediate([[CmdRIToolCreateRendInst tpl="unbaked_rendinst", tm=evt.tm, name=evt.name, eid=INVALID_ENTITY_ID, undo=false]])

[es(tag=gameClient)]
def scenery_rendinsts_enbake_rendinst_es(evt : CmdRIToolEnbakeRendInst)
  if evt.eid == INVALID_ENTITY_ID
    return
  if has(evt.eid, "gameRendInstTag") || has(evt.eid, "unbakedRendInstTag") || has(evt.eid, "clonedRIDoorTag")
    reCreateEntityFrom(evt.eid, add_sub_template_name(evt.eid, "enbaked_ri"))
    entity_obj_editor_saveAddTemplate(evt.eid, "enbaked_ri")
    return

[es(tag=gameClient)]
def scenery_rendinsts_rebake_rendinst_es(evt : CmdRIToolRebakeRendInst;
                                         var riunb : Array&)
  if evt.eid == INVALID_ENTITY_ID
    return
  if !has(evt.eid, "unbakedRendInstTag") && !has(evt.eid, "clonedRIDoorTag")
    return

  let rebakeTm = get_TMatrix(evt.eid, "rebake__tm")
  if rebakeTm == null
    return
  let rebakeName = get_string(evt.eid, "rebake__name", "")
  if rebakeName == ""
    return

  for idx in iter_range(riunb)
    let obj = get_ecs_object(riunb[idx])
    if obj == null
      continue
    let name = get_string(*obj, "name", "")
    if name != rebakeName
      continue
    let tm = get_TMatrix(*obj, "tm")
    if tm == null
      continue
    if !is_nearly_same_ri_tm(*tm, *rebakeTm)
      continue
    broadcastEventImmediate([[CmdRIToolCreateRendInst tpl="rebaked_rendinst", tm=*rebakeTm, name=rebakeName, eid=INVALID_ENTITY_ID, undo=false]])
    destroyEntity(evt.eid)
    riunb |> erase(idx)
    break

[es(tag=gameClient)]
def scenery_rendinsts_remove_rendinst_es(evt : CmdRIToolRemoveRendInst;
                                         var rirmv : Array&)
  if evt.eid != INVALID_ENTITY_ID
    if has(evt.eid, "gameRendInstTag")
      destroyEntity(evt.eid)
      return
    if has(evt.eid, "unbakedRendInstTag")
      destroyEntity(evt.eid)
      return
    if has(evt.eid, "isDoor")
      remove_door(evt.eid, evt.tm, evt.name, rirmv)
      return
    if has(evt.eid, "rebakedRendInstTag")
      destroyEntity(evt.eid)
      using() <| $(var obj : Object)
        obj |> set("tm", evt.tm)
        obj |> set("name", evt.name)
        rirmv |> push(obj)
    return

  if !remove_rendinst(evt.tm, evt.name)
    return

  using() <| $(var obj : Object)
    obj |> set("tm", evt.tm)
    obj |> set("name", evt.name)
    rirmv |> push(obj)

[es(tag=gameClient)]
def scenery_rendinsts_restore_rendinst_es(evt : CmdRIToolRestoreRendInst;
                                          var rirmv : Array&)
  let cnt = length(rirmv)
  if cnt <= 0
    return

  for i in range(0, cnt)
    let idx = cnt - 1 - i
    let obj = get_ecs_object(rirmv[idx])
    if obj == null
      continue
    let rebakeName = get_string(*obj, "name", "")
    if rebakeName == ""
      continue
    let rebakeTm = get_TMatrix(*obj, "tm")
    if rebakeTm == null
      continue
    let pos = (*rebakeTm)[3]
    let poolsCount = rendinst_getRiGenExtraResCount()
    var radius = 10.0 // safe default
    for pool_id in range(poolsCount)
      let riName = riex_getRIGenExtraName(uint(pool_id))
      if riName == rebakeName
        radius = riex_getBsphRad(uint(pool_id))
        break
    console_command("daEd4.zoom {pos.x} {pos.y+radius*0.618} {pos.z} {radius}")
    broadcastEventImmediate([[CmdRIToolCreateRendInst tpl="rebaked_rendinst", tm=*rebakeTm, name=rebakeName, eid=INVALID_ENTITY_ID, undo=false]])
    rirmv |> erase(idx)
    break


[es(tag=gameClient)]
def scenery_rendinsts_create_rendinst_es(evt : CmdRIToolCreateRendInst)
  var tpl = evt.tpl
  if evt.eid != INVALID_ENTITY_ID
    if has(evt.eid, "isDoor")
      clone_door(evt.eid, evt.tm, evt.name)
    if tpl == "game_rendinst" && getEntityTemplateName(evt.eid) == "game_rendinst_decor"
      tpl = "game_rendinst_decor"
  let createdEid = entity_object_editor_createEntityDirectRIExtra(tpl, evt.tm, evt.name)
  if createdEid == INVALID_ENTITY_ID
    return
  if tpl == "rebaked_rendinst"
    return

  if !evt.undo
    entity_object_editor_addEntity(createdEid)
  else
    entity_object_editor_addEntityWithUndo(createdEid)

  entity_obj_editor_saveComponent(createdEid, "transform")
  entity_obj_editor_saveComponent(createdEid, "ri_extra__name")

  if tpl == "unbaked_rendinst"
    set(createdEid, "rebake__tm", evt.tm)
    set(createdEid, "rebake__name", evt.name)
    entity_obj_editor_saveComponent(createdEid, "rebake__tm")
    entity_obj_editor_saveComponent(createdEid, "rebake__name")

  entity_object_editor_selectEntity(createdEid, true)


[es(tag=gameClient)]
def scenery_rendinsts_add_selected_es(evt : CmdRIToolAddSelected;
                                      var rendinsts_removes__selected : Array&)
  if evt.action == "select"
    rendinsts_removes__selected |> clear()

  if evt.action == "select" || evt.action == "multiselect"
    using() <| $(var obj : Object)
      obj |> set("tm", evt.tm)
      obj |> set("name", evt.name)
      obj |> set("bsph", evt.bsph)
      obj |> set("kind", evt.kind)
      rendinsts_removes__selected |> push(obj)

  if evt.action == "deselect"
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
    let kind = get_int(*obj, "kind") ?? 0
    if kind <= 0
      draw_debug_sphere_buffered(pos, rad, E3DCOLOR(0xFFFFFFFF), 24, 1)
    elif kind == 1
      draw_debug_sphere_buffered(pos, rad - 0.005, E3DCOLOR(0xFFEE00EE), 24, 1)
      draw_debug_sphere_buffered(pos, rad,         E3DCOLOR(0xFFEE00EE), 24, 1)
    elif kind == 2
      draw_debug_sphere_buffered(pos, rad, E3DCOLOR(0xFFF0F000), 24, 1)
    else
      draw_debug_sphere_buffered(pos, rad, E3DCOLOR(0xFF00F0F0), 24, 1)
