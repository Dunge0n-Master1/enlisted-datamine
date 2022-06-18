import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { TEAM_UNASSIGNED } = require("team")
let { localPlayerTeam } = require("%ui/hud/state/local_player.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let { logerr } = require("dagor.debug")
let { is_point_in_poly_battle_area } = require("ecs.utils")
let { fabs } = require("math")
let { Point2, Point3 } = require("dagor.math")

let activeBattleAreasState = Watched(null)
let battleAreasPolygon = Watched(null)


let function checkInSquareZone(battleAreaZones, checkingPoint){ //lines are sorted clockwise
  foreach(zone in battleAreaZones){
    let D1 = (zone.line1.end.x - zone.line1.start.x) * (checkingPoint.y - zone.line1.start.y) -
               (zone.line1.end.y - zone.line1.start.y) * (checkingPoint.x - zone.line1.start.x)
    let D2 = (zone.line2.end.x - zone.line2.start.x) * (checkingPoint.y - zone.line2.start.y) -
               (zone.line2.end.y - zone.line2.start.y) * (checkingPoint.x - zone.line2.start.x)
    let D3 = (zone.line3.end.x - zone.line3.start.x) * (checkingPoint.y - zone.line3.start.y) -
               (zone.line3.end.y - zone.line3.start.y) * (checkingPoint.x - zone.line3.start.x)
    let D4 = (zone.line4.end.x - zone.line4.start.x) * (checkingPoint.y - zone.line4.start.y) -
               (zone.line4.end.y - zone.line4.start.y) * (checkingPoint.x - zone.line4.start.x)
    let eps = 0.05
    if (D1 > eps && D2 > eps && D3 > eps && D4 > eps)
      return true
  }
  return false
}

let function checkInPolyZone(polyBattleAreaZones, checkingPoint, excludeEids){
  let checkingPoint3 = Point3(checkingPoint.x,0,checkingPoint.y)
  foreach(zone in polyBattleAreaZones){
    local skipZone = false
    foreach (excludeEid in excludeEids){
      skipZone = zone == excludeEid
      if (skipZone)
        break
    }
    if (!skipZone && is_point_in_poly_battle_area(checkingPoint3, zone))
      return true
  }
  return false
}

let function intersection(start1, end1, start2, end2){
  local  out_intersection = Point2()
  let dir1 = end1 - start1
  let dir2 = end2 - start2

  let a1 = -dir1.y
  let b1 = dir1.x
  let d1 = -(a1*start1.x + b1*start1.y)

  let a2 = -dir2.y
  let b2 = dir2.x
  let d2 = -(a2*start2.x + b2*start2.y)

  let seg1_line2_start = a2*start1.x + b2*start1.y + d2
  let seg1_line2_end = a2*end1.x + b2*end1.y + d2
  let seg2_line1_start = a1*start2.x + b1*start2.y + d1
  let seg2_line1_end = a1*end2.x + b1*end2.y + d1

  if (seg1_line2_start * seg1_line2_end >= 0 || seg2_line1_start * seg2_line1_end >= 0)
    return false

  let u = seg1_line2_start / (seg1_line2_start - seg1_line2_end)
  out_intersection =  start1 + Point2(u*dir1.x, u*dir1.y)
  return out_intersection
}

let mkFilterByTeam = @(team_id)
  @"or(eq(opt(battle_area__team,{1}),{0}),eq(opt(battle_area__team,{1}),{1}))".subst(team_id, TEAM_UNASSIGNED)

let battleAreaFilterStr = "and(and(eq(active,true),eq(battle_area__isVisible,true)),{0})"

let boxBattleAreaQuery = ecs.SqQuery("boxBattleAreaQuery", {
  comps_ro = [
    ["transform", ecs.TYPE_MATRIX],
    ["active", ecs.TYPE_BOOL],
    ["battle_area__isVisible", ecs.TYPE_BOOL],
    ["battle_area__team", ecs.TYPE_INT, TEAM_UNASSIGNED],
  ],
  comps_rq = ["battle_area", "box_zone"],
  comps_no = ["hideOnMinimap"]
})

let function floats_equal(a, b, eps = 0.01) {
  return fabs(a - b) < eps
}

let polyBattleAreaQuery = ecs.SqQuery("polyBattleAreaQuery", {
  comps_ro = [
    ["battleAreaPoints", ecs.TYPE_POINT2_LIST],
    ["active", ecs.TYPE_BOOL],
    ["battle_area__isVisible", ecs.TYPE_BOOL],
    ["battle_area__team", ecs.TYPE_INT, TEAM_UNASSIGNED],
  ],
  comps_rq = ["battle_area"],
  comps_no = ["hideOnMinimap"]
})

let mkSegment = @(a, b, eids = []) {start = Point2(a.x, a.y), end = Point2(b.x, b.y), excludeCheckEids = eids}
let isPointsEqual = @(a,b) (a.x == b.x) && (a.y == b.y)
let isSegmentsEqual = @(a,b) isPointsEqual(a.start, b.start) && isPointsEqual(a.end, b.end)

let function is_on_segment(p, seg) {
  if (isPointsEqual(p, seg.start) || isPointsEqual(p, seg.end))
    return false
  let startSegment = p - seg.start
  let endSegment = seg.end - p
  let segmentDistanceThroughPoint = startSegment.length() + endSegment.length()
  let segmentVec = seg.start - seg.end
  let segmentLength = segmentVec.length()
  return floats_equal(segmentDistanceThroughPoint,segmentLength, 1e-4)
}

let function splitSegment(segments, curSegmentId, dividingPoint){
  if (isPointsEqual(dividingPoint, segments[curSegmentId].start) ||
      isPointsEqual(dividingPoint, segments[curSegmentId].end))
    return
  let curSegExcludeEids = segments[curSegmentId]?.excludeCheckEids ?? []
  let newSegment = mkSegment(dividingPoint, segments[curSegmentId].end, curSegExcludeEids)
  segments[curSegmentId] = mkSegment(segments[curSegmentId].start, dividingPoint, curSegExcludeEids)
  segments.append(newSegment)
}

let allTypeBattleAreasQuery = ecs.SqQuery("allTypeBattleAreasQuery", {
  comps_ro = [
    ["groupName", ecs.TYPE_STRING],
    ["active", ecs.TYPE_BOOL],
    ["battle_area__isVisible", ecs.TYPE_BOOL],
    ["battle_area__team", ecs.TYPE_INT, TEAM_UNASSIGNED],
  ],
  comps_rq = ["battle_area"],
  comps_no = ["hideOnMinimap"]
})

let function dumpAllActiveBattleAreasToLog() {
  let filter = battleAreaFilterStr.subst(mkFilterByTeam(localPlayerTeam.value))
  log($"battle areas conflict for team {localPlayerTeam.value} , list of active groupName")
  allTypeBattleAreasQuery.perform(function(_eid, comps) { log($"GroupName = {comps.groupName}") }, filter)
}

let function findNextSegment(segmentToExtend, segments) {
  foreach (s in segments)
    if (s != segmentToExtend.seg && floats_equal(s.start.x, segmentToExtend.linkTo.x) && floats_equal(s.start.y, segmentToExtend.linkTo.y))
      return {seg = s, linkTo = s.end}
  foreach (s in segments)
    if (s != segmentToExtend.seg && floats_equal(s.end.x, segmentToExtend.linkTo.x) && floats_equal(s.end.y, segmentToExtend.linkTo.y))
      return {seg = s, linkTo = s.start}
  logerr("Can't build battleAreas ui polygon, see debug for more info")
  dumpAllActiveBattleAreasToLog()
  return null
}

const BIGNUM = 10000.0
let function buildPolygon(segments) {
  if (segments.len() == 0)
    return null
  let polygon = []
  local currentSegment = {seg = segments[0], linkTo = segments[0].end}
  let minPoint = Point2(BIGNUM, BIGNUM)
  let maxPoint = Point2(-BIGNUM, -BIGNUM)
  for (local i = 0; i < segments.len(); i++) {
    let p = currentSegment.linkTo
    polygon.append(p)
    currentSegment = findNextSegment(currentSegment, segments)
    if (currentSegment == null)
      return null
    maxPoint.x = max(maxPoint.x, p.x)
    maxPoint.y = max(maxPoint.y, p.y)
    minPoint.x = min(minPoint.x, p.x)
    minPoint.y = min(minPoint.y, p.y)
  }

  local radius = 0.0
  if (minPoint.x != BIGNUM && minPoint.y != BIGNUM && maxPoint.x != -BIGNUM && maxPoint.y != -BIGNUM)
    radius = 0.5 * max(maxPoint.x - minPoint.x, maxPoint.y - minPoint.y)

  return { points = polygon, radius = radius }
}

let function splitOverlappingSegments(segments) {
  for(local i = 0; i < segments.len(); i++)
    for(local j = 0; j < segments.len(); j++){
      if (is_on_segment(segments[i].start, segments[j]))
        splitSegment(segments, j, segments[i].start)
      if (is_on_segment(segments[i].end, segments[j]))
        splitSegment(segments, j, segments[i].end)
    }
}

local function clearDuplicates(segments) {
  for(local i = 0; i < segments.len(); i++){
    for(local j = i+1; j < segments.len(); j++) {
      if (segments[j]?.duplicate == true)
        continue
      if (isSegmentsEqual(segments[i],segments[j])) {
        segments[j].duplicate <- true
        if (!segments[j]?.excludeCheckEids)
          segments[j].excludeCheckEids <- []
        if (!segments[i]?.excludeCheckEids)
          continue
        segments[i].excludeCheckEids.extend(segments[j].excludeCheckEids)
      }
    }
  }
  segments = segments.filter(@(v) v?.duplicate != true)
}

let isTagsEqual = @(eid, heroTag) heroTag != null && ecs.obsolete_dbg_get_comp_val(eid, heroTag) != null

let function battleAreaHud(_evt, _eid, _comp) {
  local segments = []
  let squareBattleAreaZones = []
  let polyBattleAreaZones = []

  local activeBattleAreas = []
  let filter = battleAreaFilterStr.subst(mkFilterByTeam(localPlayerTeam.value))
  boxBattleAreaQuery.perform(function(eid, _comps) { activeBattleAreas.append(eid) }, filter)
  polyBattleAreaQuery.perform(function(eid, _comps) { activeBattleAreas.append(eid) }, filter)

  let heroCaprureTag = ecs.obsolete_dbg_get_comp_val(watchedHeroEid.value, "zones_visitor__triggerTag")
  activeBattleAreas = activeBattleAreas.filter(@(battleAreaEid) isTagsEqual(battleAreaEid, heroCaprureTag))
  let prevActiveBattleAreas = activeBattleAreasState.value ?? []
  if (prevActiveBattleAreas.len() == activeBattleAreas.len()) {
    local isEq = true
    foreach (areaEid in activeBattleAreas)
      if (prevActiveBattleAreas.indexof(areaEid) == null) {
        isEq = false
        break
      }
    if (isEq)
      return
  }

  activeBattleAreasState.update(activeBattleAreas)

  boxBattleAreaQuery.perform(function(eid, comps){
    if (!isTagsEqual(eid, heroCaprureTag))
      return
    let tm = comps["transform"]
    let diag2 = tm.getcol(0) * 0.5 + tm.getcol(2) * 0.5
    let diag1 = tm.getcol(0) * 0.5 - tm.getcol(2) * 0.5
    let pos = tm.getcol(3)
    let line1 = {start = Point2(pos.x - diag2.x,pos.z - diag2.z),
                   end = Point2(pos.x + diag1.x, pos.z + diag1.z)}
    let line2 = {start = Point2(pos.x + diag1.x,pos.z + diag1.z),
                   end = Point2(pos.x + diag2.x, pos.z + diag2.z)}
    let line3 = {start = Point2(pos.x + diag2.x,pos.z + diag2.z),
                   end = Point2(pos.x - diag1.x, pos.z - diag1.z)}
    let line4 = {start = Point2(pos.x - diag1.x,pos.z - diag1.z),
                   end = Point2(pos.x - diag2.x, pos.z - diag2.z)}
    squareBattleAreaZones.append({line1 = line1, line2=line2, line3 = line3, line4 = line4})
    segments.append(line1,line2,line3,line4)
  }, filter)

  polyBattleAreaQuery.perform(function(eid, comps){
    if (!isTagsEqual(eid, heroCaprureTag))
      return
    let points = comps["battleAreaPoints"]
    let count = points.len()
    for(local i = 0; i < count; i++) {
      let segment = {start = points[i], end = points[(i+1) % count], excludeCheckEids = [eid]}
      segments.append(segment)
    }
    polyBattleAreaZones.append(eid)
  }, filter)

  splitOverlappingSegments(segments)
  clearDuplicates(segments)

  for(local i = 0; i < segments.len(); i++)
    for(local j = i+1; j < segments.len(); j++){
        let intersectionPoint = intersection(segments[i].start, segments[i].end,
                                               segments[j].start, segments[j].end)
        if (intersectionPoint){
          let segIExcludeEids = segments[i]?.excludeCheckEids ?? []
          let segJExcludeEids = segments[j]?.excludeCheckEids ?? []
          let line1 = mkSegment(intersectionPoint, segments[i].end, segIExcludeEids)
          let line2 = mkSegment(intersectionPoint, segments[j].end, segJExcludeEids)
          segments[i] = mkSegment(segments[i].start, intersectionPoint, segIExcludeEids)
          segments[j] = mkSegment(segments[j].start, intersectionPoint, segJExcludeEids)
          segments.append(line1,line2)
        }
      }

  segments = segments.filter(function(item) {
    let checkingPoint = Point2((item.start.x + item.end.x) * 0.5, (item.start.y + item.end.y) * 0.5)
    let excludeEids = item?.excludeCheckEids ?? []
    return !(checkInSquareZone(squareBattleAreaZones,checkingPoint) || checkInPolyZone(polyBattleAreaZones, checkingPoint, excludeEids))
  })
  let polygon = buildPolygon(segments)
  battleAreasPolygon(polygon?.points)
}

ecs.register_es("battle_areas_ui_state", {
    onUpdate = @(_dt, eid, comp) battleAreaHud(null, eid, comp)
  },
  { },
  { updateInterval = 1.0, tags="gameClient", after="*", before="*" }
)
return {
  activeBattleAreas = activeBattleAreasState
  battleAreasPolygon = battleAreasPolygon
}
