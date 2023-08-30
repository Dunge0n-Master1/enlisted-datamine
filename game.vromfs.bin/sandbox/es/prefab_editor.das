options no_aot
require ecs
require EcsUtils
require math.base
require DagorEditor
require DagorSystem
require DagorConsole
require DagorDataBlock
require game.es.prefab_common
require enlisted.events_enlisted
require Dacoll

let PREFAB_SPAWN_TRACE_LEN_METER = 1000.
let PREFAB_OBJECT_TEMPLATE = "prefab_object"
let PREFAB_TEMPLATE = "prefab"
let PREFAB_SAVE_ON_LOADED_TEMPLATE = "prefab_save_on_finish_create"

def gen_new_prefab_id()
  var id = 0
  query() <| $ [es] (prefab__id : int)
    id = max(id, prefab__id)
  return id + 1

def is_valid_prefab_name_with_logerr(prefab__name : string)
  if !is_prefab_name_valid(prefab__name)
    logerr("Prefab name is not valid! It should contains only numbers or latin letters")
    return false
  return true

def private move_prefab(prefab__id : int; parent_transform : float3x4)
  query() <| $ [es] (eid : EntityId; prefab__parentId : int; prefab__localTm : float3x4; var transform : float3x4&)
    if prefab__parentId != prefab__id
      return
    transform = parent_transform * prefab__localTm
    entity_obj_editor_saveComponent(eid, "transform")

[es(REQUIRE=daeditor__selected, on_event=CmdTeleportEntity)]
def move_prefab_es(evt : Event; prefab__id : int; transform aka parent_transform : float3x4; var prev_transform : float3x4&)
  if prev_transform == parent_transform
    return

  prev_transform = parent_transform
  move_prefab(prefab__id, parent_transform)


[es(REQUIRE=daeditor__selected, on_event=CmdTeleportEntity)]
def move_prefab_object_es(evt : Event; prefab__parentId : int; transform aka child_transform : float3x4; var prefab__localTm : float3x4&)
  find_query() <| $ [es] (prefab__id : int; transform : float3x4)
    if prefab__parentId != prefab__id
      return false
    prefab__localTm = inverse(transform) * child_transform
    return true

[es]
def editor_delete_prefab_es(evt : EditorToDeleteEntitiesEvent; prefab__id : int)
  query() <| $ [es] (eid : EntityId; prefab__parentId : int)
    if prefab__parentId == prefab__id
      push(evt.linkedEntitiesToDelete, eid)

[es(on_disappear)]
def destroy_prefab_objects_es(evt : Event; prefab__id : int)
  query() <| $ [es] (eid : EntityId; prefab__parentId : int)
    if prefab__parentId == prefab__id
      destroyEntity(eid)

[es(on_event=PrefabShatterSelectedEvent)]
def prefab_shatter_es(evt : Event)
  var undoSystem = get_undo_system()
  if undoSystem != null
    *undoSystem |> begin()

  query() <| $ [es(REQUIRE=daeditor__selected)] (eid : EntityId; prefab__id : int)
    query() <| $ [es] (eid : EntityId; prefab__parentId : int)
      if prefab__parentId == prefab__id
        removeSubTemplate(eid, PREFAB_OBJECT_TEMPLATE)
        entity_obj_editor_saveDelTemplate(eid, PREFAB_OBJECT_TEMPLATE, true/*use_undo*/)
    entity_object_editor_selectEntity(eid, false/*selected*/)
    entity_object_editor_removeEntity(eid, true/*use_undo*/)
    destroyEntity(eid)

  query() <| $ [es(REQUIRE=(prefab__parentId, daeditor__selected))] (eid : EntityId)
    removeSubTemplate(eid, PREFAB_OBJECT_TEMPLATE)
    entity_obj_editor_saveDelTemplate(eid, PREFAB_OBJECT_TEMPLATE, true/*use_undo*/)

  if undoSystem != null
    *undoSystem |> accept("Prefab shatter")

[es(on_event=PrefabSaveEvent)]
def prefab_object_save_prefab_es(evt : Event; prefab__parentId : int)
  find_query() <| $ [es] (eid : EntityId; prefab__id : int)
    if prefab__id == prefab__parentId
      sendEvent(eid, [[PrefabSaveEvent]])
      return true
    return false

[es(on_event=PrefabSaveEvent)]
def prefab_save_es(evt : Event; eid : EntityId; prefab__id : int; prefab__name : string)
  if !is_valid_prefab_name_with_logerr(prefab__name)
    return

  using() <| $(var blk : DataBlock)
    var entityBlk = datablock_add_new_block(blk, "entity")
    save_entity_from_editor_to_blk(eid, *entityBlk)
    *entityBlk |> datablock_remove_param("prefab__id")

    query() <| $ [es] (eid : EntityId; prefab__parentId : int)
      if prefab__parentId != prefab__id
        return

      entityBlk = datablock_add_new_block(blk, "entity")
      save_entity_from_editor_to_blk(eid, *entityBlk)
      *entityBlk |> datablock_remove_param("prefab__parentId")

    blk |> datablock_save_to_text_file(make_prefab_path(prefab__name))
    visual_log("Prefab <{prefab__name}> saved")


[es(on_event=AddSelectedToPrefabEvent)]
def add_selected_objects_to_prefab_es(evt : Event; prefab__id : int)
  query() <| $ [es(REQUIRE=daeditor__selected, REQUIRE_NOT=(prefab__parentId, prefab__id))] (eid : EntityId)
    let finalizeCreation <- @ <| (eid : EntityId)
      entity_obj_editor_saveComponent(eid, "prefab__parentId")
    addSubTemplate(eid, PREFAB_OBJECT_TEMPLATE, finalizeCreation) <| $(var init : ecs::ComponentsInitializer)
      init |> set("prefab__parentId", prefab__id)
    entity_obj_editor_saveAddTemplate(eid, PREFAB_OBJECT_TEMPLATE)


[es]
def prefab_load_es(evt : PrefabSpawnEvent)
  if !is_valid_prefab_name_with_logerr(evt.name)
    return
  var undoSystem = get_undo_system()
  if undoSystem != null
    *undoSystem |> begin()

  var prefabEid = INVALID_ENTITY_ID
  let prefabId = gen_new_prefab_id()
  using() <| $(var blk : DataBlock)
    let prefabPath = make_prefab_path(evt.name)
    if !datablock_load(blk, prefabPath)
      logerr("Failed to load prefab <{prefabPath}>")
      return
    for i in range(blk.blockCount)
      let entityBlk = datablock_get_block(blk, uint(i))
      if entityBlk.getBlockName != "entity"
        logerr("Invalid block name <{entityBlk.getBlockName}> except <entity> while loading prefab <{evt.name}>")
        continue
      let tmplName = datablock_getStr(entityBlk, "_template", "")
      if tmplName == ""
        logerr("Not found _template in block with index {i} while loading prefab <{evt.name}>")
        continue
      using() <| $(var comps : ComponentsList)
        load_comp_list_from_blk(*entityBlk, comps)
        // sync create for select by editor
        let eid = createEntitySync(tmplName) <| $(var init : ComponentsInitializer&)
          find_component(comps) <| $(comp_name : string; comp : ChildComponent const#)
            init |> set(comp_name, comp)
            return false
          init |> set("prefab__parentId", prefabId)
          init |> set("prefab__id", prefabId)
        scene_insert_entity_record(get_active_scene(), eid, tmplName, comps)
        entity_object_editor_addEntityWithUndo(eid)
        entity_obj_editor_saveComponent(eid, "prefab__id")
        entity_obj_editor_saveComponent(eid, "prefab__parentId")
        if has(eid, "prefab__id")
          prefabEid = eid
  if !!prefabEid
    entity_object_unselectAll()
    entity_object_editor_selectEntity(prefabEid, true/*selected*/)
    find_query() <| $ [es] (camera__active : bool; transform aka camera_transform : float3x4)
      if !camera__active
        return false
      query(prefabEid) <| $ [es] (var transform : float3x4&)
        var t = PREFAB_SPAWN_TRACE_LEN_METER
        var norm = float3()
        if !traceray_normalized(camera_transform[3], camera_transform[2], t, norm)
          t = 20.
        transform[3] = camera_transform[3] + camera_transform[2] * t
        move_prefab(prefabId, transform)
        entity_obj_editor_saveComponent(prefabEid, "transform")
      return true

  if undoSystem != null
    *undoSystem |> accept("Prefab create")

[es(on_appear)]
def prefab_save_on_loaded_es(evt : Event; prefab__parentId : int)
  find_query() <| $ [es] (eid : EntityId; prefab__id : int; var prefab__createdCount : int&)
    if prefab__id != prefab__parentId
      return false
    --prefab__createdCount
    if prefab__createdCount <= 0
      removeSubTemplate(eid, PREFAB_SAVE_ON_LOADED_TEMPLATE)
      sendEvent(eid, [[PrefabSaveEvent]])
    return true

[es]
def prefab_create_from_selected_es(evt : PrefabCreateFromSelectedEvent)
  if !is_valid_prefab_name_with_logerr(evt.name)
    return
  var undoSystem = get_undo_system()
  if undoSystem != null
    *undoSystem |> begin()
  let prefabId = gen_new_prefab_id()
  var entityInPrefabCount = 0
  var positionSum = float3()
  query() <| $ [es(REQUIRE=daeditor__selected, REQUIRE_NOT=(prefab__id, prefab__parentId))] (eid : EntityId; transform : float3x4 const? = null)
    let finalizeCreation <- @ <| (eid : EntityId)
      entity_obj_editor_saveComponent(eid, "prefab__parentId")
    addSubTemplate(eid, PREFAB_OBJECT_TEMPLATE, finalizeCreation) <| $(var init : ecs::ComponentsInitializer)
      init |> set("prefab__parentId", prefabId)
    entityInPrefabCount++
    if transform != null
      positionSum += (*transform)[3]
    entity_obj_editor_saveAddTemplate(eid, PREFAB_OBJECT_TEMPLATE)

  if entityInPrefabCount == 0
    *undoSystem |> cancel()
    return
  // sync create for select by editor
  var prefabTemplate = PREFAB_TEMPLATE
  if evt.save
    prefabTemplate += "+" + PREFAB_SAVE_ON_LOADED_TEMPLATE
  let eid = createEntitySync(prefabTemplate) <| $(var init : ecs::ComponentsInitializer)
    init |> set("prefab__id", prefabId)
    init |> set("prefab__name", evt.name)
    var tm = IDENT_TM
    tm[3] = (positionSum / float(entityInPrefabCount))
    init |> set("transform", tm)
    if evt.save
      init |> set("prefab__createdCount", entityInPrefabCount)
  scene_insert_empty_entity_record(get_active_scene(), eid, PREFAB_TEMPLATE)
  entity_object_editor_addEntity(eid)
  entity_obj_editor_saveComponent(eid, "prefab__id")
  entity_obj_editor_saveComponent(eid, "prefab__name")
  entity_obj_editor_saveComponent(eid, "transform")
  entity_object_unselectAll()
  entity_object_editor_selectEntity(eid, true/*selected*/)
  *undoSystem |> accept("Prefab create")

[es(on_event=PrefabSelectParentEvent)]
def prefab_select_parent_es(evt : Event; prefab__parentId : int)
  find_query() <| $ [es] (eid : EntityId; prefab__id : int)
    if prefab__id != prefab__parentId
      return false
    entity_object_editor_selectEntity(eid, true/*selected*/)
    return true

[es(on_event=EditorOnInitClonedEntity)]
def on_prefab_clone_es(evt : Event; eid : EntityId; var prefab__id : int&)
  let oldPrefabId = prefab__id
  prefab__id = gen_new_prefab_id()
  entity_obj_editor_saveComponent(eid, "prefab__id")
  query() <| $ [es] (eid : EntityId; prefab__parentId : int)
    if prefab__parentId != oldPrefabId
      return
    let newEid = entity_object_editor_cloneEntity(eid, true/*use_undo*/)
    set(newEid, "prefab__parentId", prefab__id)
    entity_obj_editor_saveComponent(newEid, "prefab__parentId")

