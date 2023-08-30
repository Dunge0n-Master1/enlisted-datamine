module respawn_camera_common shared

require player
require ecs
require game.es.respawn_base_common
require game.utils.team

def setup_camera_as_active(cam_eid : EntityId; cam_name : string)
  query(get_local_player_eid()) <| $ [es] (var activeCamEid : EntityId&; var activeCamName : das_string)
    activeCamEid = cam_eid
    activeCamName := cam_name

def get_polygons_center(polygons : Point2List) : float2
  if length(polygons) == 0
    return float2()

  var polygonsMidPos = float2()
  var circumference = 0.

  for point, pointNo in polygons, iter_range(polygons)
    let nextPointNo = (pointNo + 1) % length(polygons)
    let nextPoint = polygons[nextPointNo]
    let dist = distance(point, nextPoint)
    polygonsMidPos += (point + nextPoint) * 0.5 * dist
    circumference += dist
  return polygonsMidPos / circumference

def get_above_camera_target() : float2
  var aboveCamTarget : float2
  var foundMid = find_query() <| $ [es] (respawn_camera_target__curLookPos : float3)
    aboveCamTarget = respawn_camera_target__curLookPos.xz
    return true
  if foundMid
    return aboveCamTarget
  query() <| $ [es] (battle_area__showActiveArea : bool;
                     battle_area__activeBattleAreasPolygon : Point2List;
                     battle_area__nextBattleAreasPolygon : Point2List)
    if battle_area__showActiveArea && length(battle_area__activeBattleAreasPolygon) != 0
      aboveCamTarget = get_polygons_center(battle_area__activeBattleAreasPolygon)
      foundMid = true
    elif length(battle_area__nextBattleAreasPolygon) != 0
      aboveCamTarget = get_polygons_center(battle_area__nextBattleAreasPolygon)
      foundMid = true
  if foundMid
    return aboveCamTarget
  let respMid = find_middle_resp_point(get_local_player_team())
  return respMid.xz
