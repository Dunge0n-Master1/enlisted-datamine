options no_aot
require ecs
require strings
require CollRes
require DagorConsole
require Dacoll
require DagorDebug3D
require GridCollision
require CollisionTraces
require Grid
require PhysMat
require DagorShaders
require WorldRenderer

let
  aim_ruler_physmatVarId = get_shader_variable_id("aim_ruler_physmat", true)

enum RulerMode : int
  DISABLE = 0
  RULER = 1
  BOXES = 2
  PHYSMAP = 3

[console_cmd(name="aim.ruler", hint="<mode 0 - disable, 1 - ruler, 2 - ruler+boxes, 3 - ruler+boxes+physmap>")]
def draw_ruler(mode : int)
  let found = find_query() <| $ [es(REQUIRE=aimRulerDebug)] (eid : EntityId; var drawPhysMap, drawBoxes : bool&)
    if mode == int(RulerMode DISABLE)
      destroyEntity(eid)
    else
      drawBoxes = (mode >= int(RulerMode BOXES))
      drawPhysMap = (mode >= int(RulerMode PHYSMAP))
    return true

  if !found && mode >= int(RulerMode RULER)
    createEntity("aim_ruler_debug") <| $(init)
      init |> set("drawBoxes", mode >= int(RulerMode BOXES))
      init |> set("drawPhysMap", mode >= int(RulerMode PHYSMAP))

def private trace_grid(grid_type : uint; pos, dir : float3; var len : float&)
  var retEid = INVALID_ENTITY_ID
  trace_entities_in_grid(grid_type, pos, dir, len, INVALID_ENTITY_ID, SortIntersections YES) <| $(intersections : array<IntersectedEntity>#)
    if length(intersections) != 0
      retEid = intersections[0].eid
  return retEid

def draw_same_material(pos : float3; test_mat_id)
  let halfSize = 32
  let boxRenderHalfSize = float3(0.2, 0.3, 0.2)
  let colorSame = E3DCOLOR(0xFFFFFFFF)
  let colorOther = E3DCOLOR(0xFFFF0000)
  var worldBBox = BBox3()
  if !worldRenderer_getWorldBBox3(worldBBox)
    return

  let tracePos = float3(floor(pos.x) + 0.5, worldBBox.boxMax.y, floor(pos.z) + 0.5)
  let dir = float3(0, -1, 0)
  for ix in range(-halfSize, halfSize)
    for iz in range(-halfSize, halfSize)
      var matId = PHYSMAT_INVALID
      var riDesc = RendInstDesc()
      var t = worldBBox.width.y
      var norm : float3
      let p = tracePos + float3(ix, 0, iz)

      if traceray_normalized(p, dir, t, matId, norm, ETF_ALL, riDesc, -1)
        let center = p + dir * t
        draw_cached_debug_box(BBox3(center - boxRenderHalfSize, center + boxRenderHalfSize),
          matId == test_mat_id ? colorSame : colorOther
          )

[es(tag=render, no_order, REQUIRE=aimRulerDebug)]
def draw_ruler_es(evt : UpdateStageInfoRenderDebug; shouldDraw : bool; tracePos : float3; traceDir : float3;
                  drawBoxes, drawPhysMap : bool)
  if !shouldDraw
    return
  var len = 4000f
  var norm : float3
  var color = E3DCOLOR(0xFFFFFFFF)
  var matId = PHYSMAT_INVALID
  var riDesc = RendInstDesc()
  if traceray_normalized(tracePos, traceDir, len, matId, norm, ETF_ALL, riDesc, -1)
    color = E3DCOLOR(0xFF00FF00)
  var desc = format("%.2fm", len)
  let humanTarget = trace_grid(ecs_hash("humans"), tracePos, traceDir, len)
  let vehicleTarget = trace_grid(ecs_hash("vehicles"), tracePos, traceDir, len)
  let lootTarget = trace_grid(ecs_hash("loot"), tracePos, traceDir, len)
  let gunTarget = trace_grid(ecs_hash("interactable"), tracePos, traceDir, len)
  let targetEid = !!gunTarget ? gunTarget : !!lootTarget ? lootTarget : !!humanTarget ? humanTarget : vehicleTarget
  if !targetEid
    if matId >= 0
      desc += " mat {matId} <{get_material_name(get_material(matId))}>"
  else
    color = E3DCOLOR(0xFF00FF00)
    query(targetEid) <| $ [es] (possessedByPlr : EntityId const?; transform : float3x4; collres : CollisionResource; material : string = "default")
      var t = 4000f
      if collres_traceray(collres, transform, tracePos, traceDir, t, norm, matId)
        desc += " pmat {matId} <{get_material_name(get_material(matId))}>"
      desc += " mat {get_material_id(material)} <{material}>"
      if possessedByPlr != null
        desc += " plr <{get_string(*possessedByPlr, "name", "")}>"
    desc += " {targetEid} <{getEntityTemplateName(targetEid)}>"
  let pos = tracePos + traceDir * len
  if drawPhysMap
    DagorShaders::set_int(aim_ruler_physmatVarId, matId)
  begin_draw_cached_debug_lines(false, false, false)

  if drawBoxes && matId >= 0
    draw_same_material(pos, matId)
  draw_debug_line_buffered(tracePos, pos, color, 5)
  add_debug_text_mark(pos, desc, -1, 0., color)

  end_draw_cached_debug_lines()