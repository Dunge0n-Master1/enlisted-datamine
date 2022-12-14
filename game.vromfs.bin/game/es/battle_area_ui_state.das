require game.utils.team
require ecs
require zones
require DagorSystem
require enlisted.events_enlisted
require DagorMath
require math.base

struct BattleAreaInfo
  areaEid : EntityId
  points : array<float2>

struct BattleAreaSegment
  startPoint : float2
  endPoint : float2
  duplicate : bool
  excludeEids : table<uint; bool>

struct CurrentSegment
  seg : BattleAreaSegment
  linkTo : float2
  valid : bool

def check_in_poly_zone(battle_areas : array<BattleAreaInfo>; checking_point : float3; exclude_eids : table<uint; bool>)
  for zone in battle_areas
    let skipZone = exclude_eids |> key_exists(uint(zone.areaEid))
    if !skipZone && is_point_in_polygon_zone(checking_point, zone.points, false)
      return true
  return false

def intersection(start1 : float2; end1 : float2; start2 : float2; end2 : float2; var out_intersection : float2&)
  let dir1 = end1 - start1
  let dir2 = end2 - start2

  let a1 = -dir1.y
  let b1 = dir1.x
  let d1 = -(a1 * start1.x + b1 * start1.y)

  let a2 = -dir2.y
  let b2 = dir2.x
  let d2 = -(a2 * start2.x + b2 * start2.y)

  let seg1Line2Start = a2 * start1.x + b2 * start1.y + d2
  let seg1Line2End = a2 * end1.x + b2 * end1.y + d2
  let seg2Line1Start = a1 * start2.x + b1 * start2.y + d1
  let seg2Line1End = a1 * end2.x + b1 * end2.y + d1

  if seg1Line2Start * seg1Line2End >= 0.f || seg2Line1Start * seg2Line1End >= 0.f
    return false

  let d = seg1Line2Start - seg1Line2End
  let u = safediv(seg1Line2Start, d)
  out_intersection = start1 + u * dir1
  return true

def mk_segment(a : float2; b : float2; eids : table<uint; bool>)
  var segment : BattleAreaSegment
  segment.startPoint = a
  segment.endPoint = b
  for key, value in keys(eids), values(eids)
    segment.excludeEids[key] = value
  return <- segment

def is_segments_equal(a : BattleAreaSegment; b : BattleAreaSegment)
  return a.startPoint == b.startPoint && a.endPoint == b.endPoint

def is_on_segment(p : float2; seg : BattleAreaSegment)
  if p == seg.startPoint || p == seg.endPoint
    return false
  let startSegment = p - seg.startPoint
  let endSegment = seg.endPoint - p
  let segmentDistanceThroughPoint = length(startSegment) + length(endSegment)
  let segmentVec = seg.startPoint - seg.endPoint
  let segmentLength = length(segmentVec)
  return is_equal_float(segmentDistanceThroughPoint, segmentLength, 1e-4)

def split_segment(var segments : array<BattleAreaSegment>&; cur_segment_id : int; dividing_point : float2)
  if dividing_point == segments[cur_segment_id].startPoint || dividing_point == segments[cur_segment_id].endPoint
    return

  let newSegment <- mk_segment(dividing_point, segments[cur_segment_id].endPoint, segments[cur_segment_id].excludeEids)
  segments[cur_segment_id] <- mk_segment(segments[cur_segment_id].startPoint, dividing_point, segments[cur_segment_id].excludeEids)
  segments |> push_clone(newSegment)

def dump_all_active_battle_areas_to_log()
  var heroCaprureTag = "humanTriggerable"
  var heroTeam = TEAM_UNASSIGNED

  query() <| $ [es(REQUIRE=watchedByPlr)] (zones_visitor__triggerTag : string;
                                           team : int)
    heroCaprureTag := zones_visitor__triggerTag
    heroTeam = team

  print("battle areas conflict for team {heroTeam} , list of active groupName")
  query() <| $ [es(REQUIRE=battle_area, REQUIRE_NOT=hideOnMinimap)] (eid : EntityId;
                                                                     active : bool;
                                                                     battle_area__isVisible : bool;
                                                                     battle_area__team : int = TEAM_UNASSIGNED;
                                                                     groupName : string)
    if !active || !battle_area__isVisible || (battle_area__team != heroTeam && battle_area__team != TEAM_UNASSIGNED)
      return

    if !has(eid, heroCaprureTag, ecs_hash(heroCaprureTag))
      return
    print("GroupName = {groupName} {eid}")

def find_next_segment(segmentToExtend; var segments : array<BattleAreaSegment>&)
  var curSeg : CurrentSegment
  for s in segments
    if !is_segments_equal(s, segmentToExtend.seg) && is_equal_float(s.startPoint.x, segmentToExtend.linkTo.x) && is_equal_float(s.startPoint.y, segmentToExtend.linkTo.y)
      curSeg.seg := s
      curSeg.linkTo = s.endPoint
      curSeg.valid = true
      return <- curSeg
  for s in segments
    if !is_segments_equal(s, segmentToExtend.seg) && is_equal_float(s.endPoint.x, segmentToExtend.linkTo.x) && is_equal_float(s.endPoint.y, segmentToExtend.linkTo.y)
      curSeg.seg := s
      curSeg.linkTo = s.startPoint
      curSeg.valid = true
      return <- curSeg
  logerr("Can't build battleAreas ui polygon, see debug for more info")
  print("All segnent's {segments}, calculating broken on segment = {segmentToExtend}")
  dump_all_active_battle_areas_to_log()
  return <- curSeg

def build_polygon(var segments : array<BattleAreaSegment>&; var polygon : Point2List&)
  let segmentsCount = length(segments)
  if segmentsCount == 0
    return

  var currentSegment : CurrentSegment
  currentSegment.seg := segments[0]
  currentSegment.linkTo = segments[0].endPoint

  for _i in range(segmentsCount)
    let p = currentSegment.linkTo
    polygon |> push(p)
    currentSegment <- find_next_segment(currentSegment, segments)


def split_overlapping_segments(var segments : array<BattleAreaSegment>&)
  let segmentsCount = length(segments)
  for i in range(segmentsCount)
    for j in range(segmentsCount)
      if (is_on_segment(segments[i].startPoint, segments[j]))
        split_segment(segments, j, segments[i].startPoint)
      if (is_on_segment(segments[i].endPoint, segments[j]))
        split_segment(segments, j, segments[i].endPoint)

def mark_duplicates(var segments : array<BattleAreaSegment>&)
  let segmentsCount = length(segments)
  for i in range(segmentsCount)
    for j in range(i + 1, segmentsCount)
      if segments[j].duplicate
        continue
      if is_segments_equal(segments[i], segments[j])
        segments[j].duplicate = true
        for key, value in keys(segments[j].excludeEids), values(segments[j].excludeEids)
          segments[i].excludeEids[key] = value

def build_battle_area_polygon(battle_areas : array<BattleAreaInfo>; var polygon : Point2List&)
  var segments : array<BattleAreaSegment>
  for battleArea in battle_areas
    let count = length(battleArea.points)
    for i in range(count)
      var excludeEidsCreate : table<uint; bool>
      excludeEidsCreate[uint(battleArea.areaEid)] = true

      segments |> emplace([[BattleAreaSegment
        startPoint = battleArea.points[i],
        endPoint = battleArea.points[(i + 1) % count],
        excludeEids := excludeEidsCreate,
        duplicate = false
      ]])

  split_overlapping_segments(segments)
  mark_duplicates(segments)
  var i = 0
  while i < length(segments)
    if segments[i].duplicate
      i++
      continue
    var j = 0
    while j < length(segments)
      assume start1 = segments[i].startPoint
      assume end1 = segments[i].endPoint
      assume start2 = segments[j].startPoint
      assume end2 = segments[j].endPoint
      if segments[j].duplicate || j == i || start1 == start2 || start1 == end2 || end1 == start2 || end1 == end2
        j++
        continue
      var intersectionPoint : float2
      if intersection(start1, end1, start2, end2, intersectionPoint)
        split_segment(segments, i, intersectionPoint)
        split_segment(segments, j, intersectionPoint)
      j++
    i++
  var resultSegments : array<BattleAreaSegment>
  for segment in segments
    let checkingPoint = float3((segment.startPoint.x + segment.endPoint.x) * 0.5, 0.f, (segment.startPoint.y + segment.endPoint.y) * 0.5)
    if !segment.duplicate && !check_in_poly_zone(battle_areas, checkingPoint, segment.excludeEids)
      resultSegments |> push_clone(segment)
  build_polygon(resultSegments, polygon)

[es(tag=ui, on_appear, REQUIRE=battle_area)]
def init_battle_areas_ui(evt : Event)
  let battleAreaUiInfoEid = getSingletonEntity("battle_area_ui_state")
  if !battleAreaUiInfoEid
    createEntitySync("battle_area_ui_state")

def set_require_update_battle_areas_in_ui()
  query() <| $ [es] (var battle_area__requireUpdate : bool&)
    battle_area__requireUpdate = true

[es(tag=ui, on_appear, REQUIRE=(watchedByPlr, zones_visitor__triggerTag), track=zones_visitor__triggerTag)]
def reinit_battle_areas_on_trigger_changed(evt : Event)
  set_require_update_battle_areas_in_ui()

[es(tag=ui, on_appear, on_disappear, track=(active, battle_area__deactivatedAtTime),  REQUIRE=(active, battle_area__deactivatedAtTime, battle_area))]
def reinit_battle_areas_on_zone_changed(evt : Event)
  set_require_update_battle_areas_in_ui()

def init_box_battle_area_lines(tm : float3x4; var points : array<float2>&)
  let diag2 = (tm[0].xz + tm[2].xz) * 0.5
  let diag1 = (tm[0].xz - tm[2].xz) * 0.5
  let pos = tm[3].xz
  points |> push(pos + diag2)
  points |> push(pos - diag1)
  points |> push(pos - diag2)
  points |> push(pos + diag1)

[es(tag=ui, no_order)]
def areas_update_es(info : ParallelUpdateFrameDelayed;
                    var battle_area__requireUpdate : bool&;
                    var battle_area__activeBattleAreasPolygon : Point2List;
                    var battle_area__nextBattleAreasPolygon : Point2List)
  if !battle_area__requireUpdate
    return

  battle_area__requireUpdate = false
  clear(battle_area__activeBattleAreasPolygon)
  clear(battle_area__nextBattleAreasPolygon)

  var battleAreasInfo : array<BattleAreaInfo>
  var nextBattleAreasInfo : array<BattleAreaInfo>

  var heroCaprureTag = "humanTriggerable"
  var heroTeam = TEAM_UNASSIGNED

  query() <| $ [es(REQUIRE=watchedByPlr)] (zones_visitor__triggerTag : string;
                                           team : int)
    heroCaprureTag := zones_visitor__triggerTag
    heroTeam = team

  query() <| $ [es(REQUIRE=battle_area, REQUIRE_NOT=hideOnMinimap)] (eid : EntityId;
                                                                     active : bool;
                                                                     battleAreaPoints : Point2List;
                                                                     battle_area__isVisible : bool;
                                                                     battle_area__team : int = TEAM_UNASSIGNED;
                                                                     battle_area__deactivatedAtTime : float = -1.f;
                                                                     deactivationDelay : float = 0.f)
    if !active || !battle_area__isVisible || (battle_area__team != heroTeam && battle_area__team != TEAM_UNASSIGNED)
      return

    if !has(eid, heroCaprureTag, ecs_hash(heroCaprureTag))
      return

    var polyBattleAreaPoits : array<float2>
    for point in battleAreaPoints
      polyBattleAreaPoits |> push(point)

    battleAreasInfo |> emplace([[BattleAreaInfo
      areaEid = eid,
      points := polyBattleAreaPoits
    ]])
    let deactivationTime = battle_area__deactivatedAtTime >= 0.f ? battle_area__deactivatedAtTime + deactivationDelay : -1.f
    if deactivationTime < 0.
      nextBattleAreasInfo |> emplace([[BattleAreaInfo
        areaEid = eid,
        points := polyBattleAreaPoits
      ]])

  query() <| $ [es(REQUIRE=(battle_area, box_zone), REQUIRE_NOT=hideOnMinimap)] (eid : EntityId;
                                                                                 active : bool;
                                                                                 transform : float3x4;
                                                                                 battle_area__isVisible : bool;
                                                                                 battle_area__team : int = TEAM_UNASSIGNED;
                                                                                 battle_area__deactivatedAtTime : float = -1.f;
                                                                                 deactivationDelay : float = 0.f)
    if !active || !battle_area__isVisible || (battle_area__team != heroTeam && battle_area__team != TEAM_UNASSIGNED)
      return

    if !has(eid, heroCaprureTag, ecs_hash(heroCaprureTag))
      return

    var boxBattleAreaPoits : array<float2>
    init_box_battle_area_lines(transform, boxBattleAreaPoits)
    battleAreasInfo |> emplace([[BattleAreaInfo
      areaEid = eid,
      points := boxBattleAreaPoits
    ]])
    let deactivationTime = battle_area__deactivatedAtTime >= 0.f ? battle_area__deactivatedAtTime + deactivationDelay : -1.f
    if deactivationTime < 0.
      nextBattleAreasInfo |> emplace([[BattleAreaInfo
        areaEid = eid,
        points := boxBattleAreaPoits
      ]])

  build_battle_area_polygon(battleAreasInfo, battle_area__activeBattleAreasPolygon)
  build_battle_area_polygon(nextBattleAreasInfo, battle_area__nextBattleAreasPolygon)