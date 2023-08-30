options no_aot
require ecs
require app
require ecs.common
require ecs.ecs_template
require Dacoll
require PhysMat
require DagorMath
require DagorInput
require DagorEditor
require DagorConsole
require DagorDebug3D
require debug.logerr_once
require game.es.events
require game.es.input.input_events
require enlisted.events_enlisted
require math.color
require math.base
require math.linear
require daslib/strings_boost



[ecs_template]
struct poly_area_editor
  poly_area_editor__areasEids : EidList
  poly_area_editor__traceFrom : float3
  poly_area_editor__cursorPosition : float3
  poly_area_editor__highlightedAreaEid : EntityId
  poly_area_editor__highlightedAreaPointIndex : int
  poly_area_editor__highlightedAreaPointIndex2 : int
  poly_area_editor : Tag


def enable_poly_area_editor_with_areas(areasEids : EidList)
  createEntity("poly_area_editor") <| $(init)
    init |> set("poly_area_editor__areasEids", areasEids)
  console_print(" Shoot button to add a point or move an existing one")
  console_print(" Zoom button to remove a point")


[console_cmd(name="poly_editor.enable", hint="enable poly area editor for all active areas")]
def poly_area_edit_command(enable_active_only : bool = true)
  let hasEditor = find_query() <| $ [es(REQUIRE=poly_area_editor)] (eid : EntityId)
    destroyEntity(eid)
    return true

  if !hasEditor
    using() <| $(var polyAreasEids : EidList)
      query() <| $ [es(REQUIRE=poly_area__points)] (eid : EntityId; active : bool = true)
        if !enable_active_only || active
          polyAreasEids |> push(eid)
      enable_poly_area_editor_with_areas(polyAreasEids)

  console_print("{hasEditor ? "deactivated" : "activated"} poly area editor")


[console_cmd(name="poly_editor.add_area", hint="add area to editor or enable editor with this area")]
def poly_area_add_command(area_eid : uint)
  let eid = EntityId(area_eid)
  let hasEditor = find_query() <| $ [es] (var poly_area_editor__areasEids : EidList&)
    if !poly_area_editor__areasEids |> has_value(eid)
      poly_area_editor__areasEids |> push(eid)
      console_print("added {eid} area to active poly editor")
    else
      console_print("{eid} area is already active in poly editor")
    return true

  if !hasEditor
    using() <| $(var polyAreasEids : EidList)
      polyAreasEids |> push(eid)
      enable_poly_area_editor_with_areas(polyAreasEids)
      console_print("added {eid} area and activated poly editor")


[console_cmd(name="poly_editor.remove_area")]
def poly_area_remove_command(eid : uint)
  let hasEditor = find_query() <| $ [es] (var poly_area_editor__areasEids : EidList)
    let idx = poly_area_editor__areasEids |> find_index(EntityId(eid))
    if idx >= 0
      poly_area_editor__areasEids |> erase(idx)
      console_print("removed {eid} area from active in poly editor")
    else
      console_print("{eid} area was not active before in poly editor")
    return true

  if !hasEditor
    console_print("poly area editor is not enabled")


[console_cmd(name="poly_editor.remove_all_areas")]
def poly_area_remove_all_command()
  let hasEditor = find_query() <| $ [es] (var poly_area_editor__areasEids : EidList)
    poly_area_editor__areasEids |> clear()
    console_print("removed all areas from active poly editor")
    return true

  if !hasEditor
    console_print("poly area editor is not enabled")


[console_processor]
def poly_area_editor_remove_cmd_processor(args : array<string>;
                                          collect : bool;
                                          var hints : ConsoleProcessorHints)
  if !collect
    return false

  let cmd = "poly_editor.remove_area"
  let inputs <- args[0] |> split(" ")

  if length(inputs) >= 2 && inputs[0] == cmd
    query() <| $ [es] (poly_area_editor__areasEids : EidList)
      for eid in poly_area_editor__areasEids
        query(eid) <| $ [es] (battleAreaId : string = "";
                              capzone__areaId : string = "")
          hints |> add_hint("{cmd} {eid}", 0, 1, "({battleAreaId}{capzone__areaId})")
  return false


[console_processor]
def poly_area_editor_add_cmd_processor(args : array<string>;
                                       collect : bool;
                                       var hints : ConsoleProcessorHints)
  if !collect
    return false

  let cmd = "poly_editor.add_area"
  let inputs <- args[0] |> split(" ")

  if length(inputs) >= 2 && inputs[0] == cmd
    query() <| $ [es(REQUIRE=poly_area__points)] (eid : EntityId;
                                                  battleAreaId : string = "";
                                                  capzone__areaId : string = "")
      hints |> add_hint("{cmd} {eid}", 0, 1, "({battleAreaId}{capzone__areaId})")
  return false


def get_closest_point_index_in_fov_from_areas(areas : EidList;
                                              look_from : float3;
                                              look_dir : float3;
                                              cosine : float) : tuple<areaEid : EntityId; index : int>
  var closestArea = INVALID_ENTITY_ID
  var closestPointIdx = -1
  var biggestPointCosine = 0.0

  for areaEid in areas
    query(areaEid) <| $ [es] (poly_area__points : Point3List)
      let pointsCount = length(poly_area__points)
      for i, point in range(pointsCount), poly_area__points

        let toPointCosine = dot(normalize(point - look_from), look_dir)
        if toPointCosine > cosine && (closestArea == INVALID_ENTITY_ID || toPointCosine > biggestPointCosine)
          closestArea = areaEid
          closestPointIdx = i
          biggestPointCosine = toPointCosine

  return [[auto closestArea, closestPointIdx]]


def get_closest_segment_indexes_in_fov_from_areas(areas : EidList;
                                                  look_from : float3;
                                                  look_dir : float3) : tuple<areaEid : EntityId; index1 : int; index2 : int>
  var closestArea = INVALID_ENTITY_ID
  var closestPointIdx1 = -1
  var closestPointIdx2 = -1
  var closestDistance = 0.0

  for areaEid in areas
    query(areaEid) <| $ [es] (poly_area__points : Point3List)
      let pointsCount = length(poly_area__points)
      for i1, p1 in range(pointsCount), poly_area__points
        let i2 = (i1 + 1) % pointsCount
        let p2 = poly_area__points[i2]

        let projectedP1 = project_onto_plane(p1, look_dir)
        let projectedP2 = project_onto_plane(p2, look_dir)

        let dist = distance_sq_to_seg(look_from, projectedP1, projectedP2)

        if closestArea == INVALID_ENTITY_ID || dist < closestDistance
          closestArea = areaEid
          closestPointIdx1 = i1
          closestPointIdx2 = i2
          closestDistance = dist

  return [[auto closestArea, closestPointIdx1, closestPointIdx2]]


[es(tag=input)]
def poly_area_editor_input(evt : EventDaInputActionTriggered;
                           poly_area_editor__cursorPosition : float3;
                           var poly_area_editor__highlightedAreaEid : EntityId&;
                           var poly_area_editor__highlightedAreaPointIndex : int&;
                           var poly_area_editor__highlightedAreaPointIndex2 : int&)
  query(poly_area_editor__highlightedAreaEid) <| $ [es] (var poly_area__points : Point3List&)
    query() <| $ [es] (human_input__shoot : int; human_input__zoom : int)
      let hasPointHighlighted = poly_area_editor__highlightedAreaPointIndex >= 0 && poly_area_editor__highlightedAreaPointIndex < length(poly_area__points)
      let hasPoint2Highlighted = poly_area_editor__highlightedAreaPointIndex2 >= 0 && poly_area_editor__highlightedAreaPointIndex2 < length(poly_area__points)

      query() <| $ [es(REQUIRE=(daeditor__selected, poly_area_point_mover))] (eid : EntityId)
        removeSubTemplate(eid, "daeditor_selected")

      if hasPointHighlighted && !hasPoint2Highlighted
        if int(evt.action) == human_input__zoom
          if length(poly_area__points) > 3
            poly_area__points |> erase(poly_area_editor__highlightedAreaPointIndex)
            poly_area_editor__highlightedAreaPointIndex = -1
            poly_area_editor__highlightedAreaEid = INVALID_ENTITY_ID
          else
            visual_log("Can't remove point, area must have at least 3 points")

      if hasPointHighlighted && hasPoint2Highlighted
        if int(evt.action) == human_input__shoot
          poly_area__points |> push(poly_area_editor__cursorPosition, poly_area_editor__highlightedAreaPointIndex2)
          poly_area_editor__highlightedAreaPointIndex = poly_area_editor__highlightedAreaPointIndex2
          poly_area_editor__highlightedAreaPointIndex2 = -1

          let polyAreaPointCountWarning = 50
          if length(poly_area__points) > polyAreaPointCountWarning
            visual_log("Poly area has more than {polyAreaPointCountWarning} points, it may cause performance issues", E3DCOLOR(0xFFFBFF00))


[es(tag=render)]
def poly_area_editor_update(info : ParallelUpdateFrameDelayed;
                            poly_area_editor__areasEids : EidList;
                            var poly_area_editor__traceFrom : float3&;
                            var poly_area_editor__cursorPosition : float3&;
                            var poly_area_editor__highlightedAreaEid : EntityId&;
                            var poly_area_editor__highlightedAreaPointIndex : int&;
                            var poly_area_editor__highlightedAreaPointIndex2 : int&)
  var isMovingPoint = false
  query() <| $ [es] (human_input__shoot : int)
    isMovingPoint = get_digital_action_state(uint16(human_input__shoot)).bState

  if !isMovingPoint
    poly_area_editor__highlightedAreaEid = INVALID_ENTITY_ID
    poly_area_editor__highlightedAreaPointIndex = -1

  find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if !camera__active
      return false

    let traceDir = transform[2]
    poly_area_editor__traceFrom = transform[3]

    if !isMovingPoint
      let closestPoint = get_closest_point_index_in_fov_from_areas(poly_area_editor__areasEids,
                                                                   poly_area_editor__traceFrom,
                                                                   traceDir,
                                                                   0.999)
      poly_area_editor__highlightedAreaEid = closestPoint.areaEid
      poly_area_editor__highlightedAreaPointIndex = closestPoint.index
      poly_area_editor__highlightedAreaPointIndex2 = -1

      if poly_area_editor__highlightedAreaPointIndex == -1
        let closestSegment = get_closest_segment_indexes_in_fov_from_areas(poly_area_editor__areasEids,
                                                                           poly_area_editor__traceFrom,
                                                                           traceDir)
        poly_area_editor__highlightedAreaEid = closestSegment.areaEid
        poly_area_editor__highlightedAreaPointIndex = closestSegment.index1
        poly_area_editor__highlightedAreaPointIndex2 = closestSegment.index2

    var len = 4000f
    var norm : float3
    var matId = PHYSMAT_INVALID
    var riDesc = RendInstDesc()
    let start = poly_area_editor__traceFrom
    if traceray_normalized(start, traceDir, len, matId, norm, ETF_ALL, riDesc, -1)
      poly_area_editor__cursorPosition = start + traceDir * len
      var waterLen = len
      let end = start + traceDir * len
      if traceray_water_at_time(start, end, info.curTime, waterLen)
        poly_area_editor__cursorPosition = start + traceDir * waterLen
    else
      poly_area_editor__highlightedAreaEid = INVALID_ENTITY_ID
      poly_area_editor__highlightedAreaPointIndex = -1
      poly_area_editor__highlightedAreaPointIndex2 = -1

    if isMovingPoint
      query() <| $ [es(REQUIRE=(daeditor__selected, poly_area_point_mover))] (eid : EntityId)
        removeSubTemplate(eid, "daeditor_selected")
      query(poly_area_editor__highlightedAreaEid) <| $ [es] (var poly_area__points : Point3List&)
        poly_area__points[poly_area_editor__highlightedAreaPointIndex] = poly_area_editor__cursorPosition

    return true


def get_radius(dist : float) : float
  let radiusMinMax = float2(0.3, 4.5)
  let radiusDistScale = float2(10.0, 600.0)
  return cvt(dist, radiusDistScale.x, radiusDistScale.y, radiusMinMax.x, radiusMinMax.y)


def get_color_from_eid(eid : EntityId)
  var seed = int(uint(eid))
  return rnd_color(seed)


[es(no_order)]
def poly_area_editor_draw(info : UpdateStageInfoRenderDebug;
                          poly_area_editor__areasEids : EidList;
                          poly_area_editor__traceFrom : float3;
                          poly_area_editor__cursorPosition : float3;
                          poly_area_editor__highlightedAreaEid : EntityId;
                          poly_area_editor__highlightedAreaPointIndex : int;
                          poly_area_editor__highlightedAreaPointIndex2 : int)
  begin_draw_cached_debug_lines(false, false, false)

  let cursorColor = E3DCOLOR(0xFFFFFFFF)
  let cursorRadiusMult = 1.5
  let highlightedPointRadiusMult = 2.5
  let cursorRadius = get_radius(length(poly_area_editor__traceFrom - poly_area_editor__cursorPosition)) * cursorRadiusMult

  draw_cached_debug_sphere(poly_area_editor__cursorPosition,
                           cursorRadius,
                           cursorColor,
                           24)

  // ideally we should have something like poly_area__name to use here
  // but we only have two types of poly areas for now so lets avoid unnecessary string copies or tracks
  // and just use those names directly
  find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if !camera__active
      return false

    query(poly_area_editor__highlightedAreaEid) <| $ [es] (battleAreaId : string = ""; capzone__areaId : string = "")
      let text = "{battleAreaId}{capzone__areaId}"
      let textMarkPos = poly_area_editor__cursorPosition - transform[1] * cursorRadius * 4.0
      add_debug_text_mark(textMarkPos, text, -1, 0f, get_color_from_eid(poly_area_editor__highlightedAreaEid))
    return true

  for areaEid in poly_area_editor__areasEids
    query(areaEid) <| $ [es] (poly_area__points : Point3List)
      let color = get_color_from_eid(areaEid)

      let isHighlightedArea = poly_area_editor__highlightedAreaEid == areaEid
      let pointsCount = length(poly_area__points)
      for i in range(0, pointsCount)
        let nextI = (i + 1) % pointsCount
        draw_cached_debug_line(poly_area__points[i], poly_area__points[nextI], color)

        let rad = get_radius(length(poly_area_editor__traceFrom - poly_area__points[i]))

        let isDrawnPointHighlighted = isHighlightedArea && poly_area_editor__highlightedAreaPointIndex == i && poly_area_editor__highlightedAreaPointIndex2 == -1
        draw_cached_debug_sphere(poly_area__points[i],
                                 isDrawnPointHighlighted ? rad * highlightedPointRadiusMult : rad,
                                 isDrawnPointHighlighted ? lerp_color(color, E3DCOLOR(0xFF000000), 0.7) : color,
                                 9)

      if isHighlightedArea
        let prevToHighlightedIndex = poly_area_editor__highlightedAreaPointIndex > 0 ? poly_area_editor__highlightedAreaPointIndex - 1 : pointsCount - 1

        let isExactPointHighlight = poly_area_editor__highlightedAreaPointIndex2 == -1
        let i1 = isExactPointHighlight ? prevToHighlightedIndex : poly_area_editor__highlightedAreaPointIndex
        let i2 = isExactPointHighlight ? (poly_area_editor__highlightedAreaPointIndex + 1) % pointsCount : poly_area_editor__highlightedAreaPointIndex2

        draw_cached_debug_line(poly_area__points[i1], poly_area_editor__cursorPosition, cursorColor)
        draw_cached_debug_line(poly_area_editor__cursorPosition, poly_area__points[i2], cursorColor)

  end_draw_cached_debug_lines()


def create_point_movers(var movers : EidList&; eid : EntityId; points : Point3List)
  for pointEid in movers
    destroyEntity(pointEid)

  let pointsCount = length(points)
  resize(movers, pointsCount)

  for i, point in range(pointsCount), points
    movers[i] = createEntity("poly_area_point_mover") <| $(init)
      var tm = IDENT_TM
      tm[3] = point
      init |> set("transform", tm)
      init |> set("poly_area_point_mover__areaEid", eid)
      init |> set("poly_area_point_mover__index", i)


[es(on_appear, track=poly_area__points, after=(poly_battle_area_init_points, poly_capzone_area_create_init))]
def create_point_movers_for_changed_poly_area(evt : Event;
                                              eid : EntityId;
                                              poly_area__points : Point3List;
                                              var poly_area__pointMovers : EidList&)
  if !(find_query() <| $ [es(REQUIRE=poly_area_editor)] () => true)
    return

  if length(poly_area__pointMovers) == length(poly_area__points)
    return

  // if a point was added/removed or a mover was removed just recreate all movers
  poly_area__pointMovers |> create_point_movers(eid, poly_area__points)


[es(on_appear, REQUIRE=poly_area_editor)]
def create_point_movers_for_all_poly_areas(evt : Event)
  query() <| $ [es] (eid : EntityId; poly_area__points : Point3List; var poly_area__pointMovers : EidList&)
    poly_area__pointMovers |> create_point_movers(eid, poly_area__points)


[es(on_disappear, REQUIRE=poly_area_editor)]
def destroy_point_movers_for_all_poly_areas(evt : Event)
  query() <| $ [es] (var poly_area__pointMovers : EidList&)
    for moverEid in poly_area__pointMovers
      destroyEntity(moverEid)
    poly_area__pointMovers |> clear()


[es(no_order, REQUIRE=poly_area_editor)]
def update_poly_area_point_position_from_mover(evt : ParallelUpdateFrameDelayed)
  query() <| $ [es(REQUIRE=daeditor__selected)] (transform : float3x4;
                                                 poly_area_point_mover__areaEid : EntityId;
                                                 poly_area_point_mover__index : int)
    query(poly_area_point_mover__areaEid) <| $ [es] (var poly_area__points : Point3List&)
      poly_area__points[poly_area_point_mover__index] = transform[3]


[es(no_order, REQUIRE=poly_area_editor)]
def update_poly_area_movers_position(evt : ParallelUpdateFrameDelayed)
  query() <| $ [es] (eid : EntityId;
                     poly_area__points : Point3List;
                     poly_area__pointMovers : EidList)
    let pointCount = length(poly_area__points)
    let moversCount = length(poly_area__pointMovers)
    if moversCount != pointCount
      logerr_once("{eid} has {moversCount} movers but {pointCount} points. this should not happen")
      return

    for i, moverEid in range(moversCount), poly_area__pointMovers
      query(moverEid) <| $ [es(REQUIRE_NOT=daeditor__selected)] (poly_area_point_mover__index : int;
                                                                 var transform : float3x4)
        if poly_area_point_mover__index != i
          logerr("Pole area point mover {moverEid} has index {poly_area_point_mover__index} but should have {i}")
          return
        transform[3] = poly_area__points[i]


[es(on_appear, track=poly_area__points, REQUIRE=poly_area__points)]
def save_poly_area_compact(evt : Event; eid : EntityId)
  // temp disable compact system for sandbox until we add better support to the poly area editor
  if get_app_offline_mode()
    return
  entity_obj_editor_saveComponent(eid, "poly_area__points")
