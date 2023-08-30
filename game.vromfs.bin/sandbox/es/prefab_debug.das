options no_aot
require ecs
require DagorConsole
require DagorDataBlock
require DagorSystem
require EcsUtils
require DagorEditor
require DagorDebug3D
require DagorMath
require game.es.prefab_common
require math.base
require enlisted.events_enlisted

[console_cmd(name="prefab.save", help="Save prefab to userPrefabs folder")]
def prefab_save()
  var found = false
  query() <| $ [es(REQUIRE=(prefab__id, daeditor__selected))] (eid : EntityId)
    sendEvent(eid, [[PrefabSaveEvent]])
    found = true

  if found == false
    logerr("Select any prefab for save")


[console_cmd(name="prefab.spawn", help="Spawn prefab by name")]
def prefab_load(prefab__name : string)
  broadcastEvent([[PrefabSpawnEvent name=prefab__name]])


[console_cmd(name="prefab.create", help="Create prefab from selected objects. Doesn't save prefab to drive")]
def prefab_create_from_selected(prefab__name : string)
  broadcastEvent([[PrefabCreateFromSelectedEvent name=prefab__name, save=false]])


[console_cmd(name="prefab.shatter", help="Delete prefab parent but keep objects")]
def prefab_shatter()
  broadcastEvent([[PrefabShatterSelectedEvent]])


[console_cmd(name="prefab.add_objects", help="Add selected objects to selected prefab")]
def prefab_add_object()
  find_query() <| $ [es(REQUIRE=daeditor__selected)] (eid : EntityId)
    sendEvent(eid, [[AddSelectedToPrefabEvent]])
    return true

[es(no_order, REQUIRE=daeditor__selected)]
def selected_prefab_draw_debug_es(info : UpdateStageInfoRenderDebug; prefab__id : int)
  begin_draw_cached_debug_lines(false, false, false)
  let gizmoBox = BBox3(-float3(0.12), float3(0.12))
  query() <| $ [es] (prefab__parentId : int; transform : float3x4)
    if prefab__parentId == prefab__id
      let p0 = transform * gizmoBox.boxMin
      let ax = transform[0] * gizmoBox.width[0]
      let ay = transform[1] * gizmoBox.width[1]
      let az = transform[2] * gizmoBox.width[2]
      draw_cached_debug_box(p0, ax, ay, az, E3DCOLOR(0xFFFFFF00))
      // add_debug_text_mark(transform[3], "child", -1, 0., E3DCOLOR(0x01FF0000))
  end_draw_cached_debug_lines()

[es(no_order, REQUIRE=daeditor__selected)]
def selected_object_draw_prefab_debug_es(info : UpdateStageInfoRenderDebug; prefab__parentId : int)
  find_query() <| $ [es] (prefab__id : int; transform : float3x4; prefab__name : string)
    if prefab__parentId == prefab__id
      add_debug_text_mark(transform[3], "prefab: {prefab__name}", -1, 0., E3DCOLOR(0x01FF0000))
      return true
    return false
