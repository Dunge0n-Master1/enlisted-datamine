options always_export_initializer = true

require app
require ecs
require ecs.common
require ecs.safe
require net
require math
require math.base
require BehNodes
require DngWalkerai
require DagorDataBlock
require HumanPhys
require Dacoll
require pathfinder
require DagorRandom
require DagorMath
require DagorMathUtils
require strings
require player
require Covers
require RendInst
require enlisted.events_enlisted
require enlisted.game.es.fortifications_build_common
require enlisted.game.es.ai.ai_covers_common

let
  RESPAWN_POINT_RADIUS = 0.3
  AMMO_BOX_RADIUS = 0.5
  MED_BOX_RADIUS = 0.35

def log_ai_building(player_eid : EntityId; msg : int; arg1 : int = 0; arg2 : int = 0)
  query(player_eid) <| $ [es] (var aiBuilding__debugMsgs : IPoint3List&)
    push(aiBuilding__debugMsgs, int3(msg, arg1, arg2))

def log_ai_building(player_eid : EntityId; msg : int; arg12 : float3)
  query(player_eid) <| $ [es] (var aiBuilding__debugMsgs : IPoint3List&)
    push(aiBuilding__debugMsgs, int3(msg, int(arg12.x * 1000.0), int(arg12.z * 1000.0)))

def log_ai_building(var out_msgs : IPoint3List?; msg : int; arg1 : int = 0; arg2 : int = 0)
  if out_msgs != null
    push(*out_msgs, int3(msg, arg1, arg2))

def log_ai_building(var out_msgs : IPoint3List?; msg : int; arg12 : float3)
  if out_msgs != null
    push(*out_msgs, int3(msg, int(arg12.x * 1000.0), int(arg12.z * 1000.0)))


def find_tool_gun(human_weap__gunEids : EidList; tool_type : string)
  var toolEid = INVALID_ENTITY_ID
  for gunEid in human_weap__gunEids
    query(gunEid) <| $ [es] (item__weapType : string)
      if item__weapType == tool_type
        toolEid = gunEid
        return
  return toolEid

def find_medbox_item_gun(human_weap__gunEids : EidList)
  return find_tool_gun(human_weap__gunEids, "medic_box")

def find_engineer_tool(human_weap__gunEids : EidList)
  return find_tool_gun(human_weap__gunEids, "building_tool")

def find_engineer_tool(soldier_eid : EntityId)
  var toolEid = INVALID_ENTITY_ID
  query(soldier_eid) <| $ [es] (human_weap__gunEids : EidList)
    toolEid = find_engineer_tool(human_weap__gunEids)
  return toolEid

def get_leader_target(bot_eid : EntityId; leader_target_eid_param_name : string; var out_leader_target_pos : float3&)
  if empty(leader_target_eid_param_name)
    return INVALID_ENTITY_ID
  var hasLeaderTarget = false
  var gotTargetEid = INVALID_ENTITY_ID
  query(bot_eid) <| $ [es] (squad_member__squad : EntityId)
    query(squad_member__squad) <| $ [es] (squad__leader : EntityId)
      query(squad__leader) <| $ [es] (beh_tree : BehaviourTree)
        let paramId = beh_tree.blackBoard |> datablock_find_param(leader_target_eid_param_name)
        if paramId != -1
          gotTargetEid = EntityId(uint(beh_tree.blackBoard |> datablock_getInt(paramId)))
          query(gotTargetEid) <| $ [es] (transform : float3x4)
            hasLeaderTarget = true
            out_leader_target_pos = transform[3]
  return hasLeaderTarget ? gotTargetEid : INVALID_ENTITY_ID

def get_team_and_team_eid(player_eid : EntityId; var out_team : int&; var out_team_eid : EntityId&)
  out_team = TEAM_UNASSIGNED
  out_team_eid = INVALID_ENTITY_ID
  query(player_eid) <| $ [es] (team : int)
    out_team = team
    query() <| $ [es] (team__id : int; eid aka team_eid : EntityId)
      if team__id == team
        out_team_eid = team_eid
  return out_team_eid != INVALID_ENTITY_ID


struct HowBuild
  able : bool
  toolEid : EntityId
  previewId : int
  orientTo : int
  targetEid : EntityId
  targetPos : float3
  playerEid : EntityId
  teamEid : EntityId
  team : int

let
  ORIENT_TO_BUILDER = 0
  ORIENT_TO_RANDOM = 1
  ORIENT_TO_TARGET = 2

let
  BUILD_SPAWN_POINT = 1
  BUILD_AMMO_BOX    = 2

def find_how_bot_able_to_build(build_what : int; bot_eid : EntityId; leader_target_eid_param_name : string; check_current_gun : bool)
  var result = [[HowBuild able = false,
                          toolEid = INVALID_ENTITY_ID,
                          previewId = -1,
                          orientTo = ORIENT_TO_BUILDER,
                          targetEid = INVALID_ENTITY_ID,
                          targetPos = float3(),
                          playerEid = INVALID_ENTITY_ID,
                          teamEid = INVALID_ENTITY_ID,
                          team = TEAM_UNASSIGNED]]

  query(bot_eid) <| $ [es] (isAlive : bool;
                            isDowned : bool;
                            transform aka bot_transform : float3x4;
                            human_net_phys__isSwimming : bool = false;
                            human_net_phys__isClimbing : bool = false;
                            human_weap__gunEids : EidList;
                            human_weap__currentGunEid : EntityId;
                            squad_member__playerEid : EntityId)
    if !isAlive || isDowned || human_net_phys__isSwimming || human_net_phys__isClimbing
      return

    result.toolEid = find_engineer_tool(human_weap__gunEids)
    if !result.toolEid
      return
    if check_current_gun && human_weap__currentGunEid != result.toolEid
      return

    if build_what == BUILD_SPAWN_POINT
      if !is_distance_to_capture_points_valid(bot_transform[3], 0.5, true)
        return

    if !get_team_and_team_eid(squad_member__playerEid, result.team, result.teamEid)
      return

    if get_sync_time() < get_float(result.teamEid, "team_bots__buildWaitForTime") ?? 0.0
      return

    if build_what == BUILD_SPAWN_POINT
      result.orientTo = ORIENT_TO_TARGET

      var ourTeamRallyPoints = 0
      query() <| $ [es(REQUIRE=rallypoint)] (team : int)
        if team == result.team
          ++ourTeamRallyPoints

      query(result.teamEid) <| $ [es] (var team_bots__customSpawnsBuildingEids : EidList&;
                                       team_bots__maxCustomSpawns : int)
        var numBuildingSpawns = 0
        var indexToRemove = -1
        for i, spawnEid in iter_range(team_bots__customSpawnsBuildingEids), team_bots__customSpawnsBuildingEids
          if doesEntityExist(spawnEid)
            ++numBuildingSpawns
          else
            indexToRemove = i
        while indexToRemove >= 0
          erase(team_bots__customSpawnsBuildingEids, indexToRemove)
          indexToRemove = -1
          for i, spawnEid in iter_range(team_bots__customSpawnsBuildingEids), team_bots__customSpawnsBuildingEids
            if !doesEntityExist(spawnEid)
              indexToRemove = i
              break

        if ourTeamRallyPoints + numBuildingSpawns < team_bots__maxCustomSpawns
          result.playerEid = squad_member__playerEid
        else
          log_ai_building(squad_member__playerEid, 100, ourTeamRallyPoints, numBuildingSpawns)
    else
      result.playerEid = squad_member__playerEid
    if !result.playerEid
      return

    query(result.toolEid) <| $ [es] (previewTemplate : StringList)
      for i, templateName in iter_range(previewTemplate), previewTemplate
        let tmpl = getTemplateByName(string(templateName))
        if tmpl != null
          if build_what == BUILD_SPAWN_POINT && templateHasComponent(*tmpl, "respawnObject")
            result.previewId = i
          elif build_what == BUILD_AMMO_BOX && templateHasComponent(*tmpl, "ammunitionBoxPreview")
            result.previewId = i
    if result.previewId < 0
      return

    var isBuildingAvailable = true
    query(result.playerEid) <| $ [es] (availableBuildings : IntList)
      if result.previewId < length(availableBuildings) && availableBuildings[result.previewId] <= 0
        isBuildingAvailable = false
    if !isBuildingAvailable
      return

    result.targetEid = get_leader_target(bot_eid, leader_target_eid_param_name, result.targetPos)
    if !result.targetEid
      return

    if build_what == BUILD_AMMO_BOX
      result.orientTo = ORIENT_TO_RANDOM

      var capZoneOk = false
      var insideZone = false
      var numBoxes = 0
      query(result.targetEid) <| $ [es(REQUIRE=capzone)] (active : bool;
                                                          capzone__owningTeam : int;
                                                          capzone__onlyTeamCanCapture : int;
                                                          capzone__mustBeCapturedByTeam : int;
                                                          transform aka capzone_transform : float3x4;
                                                          capzone__approximateRadius = -1.0;
                                                          sphere_zone__radius = 0.0)
        if !active
          return
        let captureDefend1 = capzone__onlyTeamCanCapture >= 1 && capzone__onlyTeamCanCapture != result.team && capzone__owningTeam != capzone__onlyTeamCanCapture
        let captureDefend2 = capzone__mustBeCapturedByTeam >= 1 && capzone__mustBeCapturedByTeam != result.team && capzone__owningTeam != capzone__mustBeCapturedByTeam
        if captureDefend1 || captureDefend2
          capZoneOk = true
          if is_pos_inside_capture_point(bot_transform[3], 0.0, capzone_transform, capzone__approximateRadius, sphere_zone__radius)
            insideZone = true
            query() <| $ [es(REQUIRE=ammunitionBox)] (transform aka ammo_box_transform : float3x4; team : int)
              if team == result.team && is_pos_inside_capture_point(ammo_box_transform[3], 0.0, capzone_transform, capzone__approximateRadius, sphere_zone__radius)
                ++numBoxes
      if !capZoneOk
        log_ai_building(squad_member__playerEid, 270, result.targetPos)
        return
      if !insideZone
        log_ai_building(squad_member__playerEid, 280, result.targetPos)
        return
      if numBoxes > 0
        log_ai_building(squad_member__playerEid, 290, result.targetPos)
        return

    result.able = true
  return result

def find_if_bot_able_to_drop_medbox(bot_eid : EntityId; leader_target_eid_param_name : string; check_current_gun : bool;
                                    var out_medbox_eid : EntityId&; var out_target_eid : EntityId&; var out_team_eid : EntityId&)
  var able = false
  query(bot_eid) <| $ [es] (isAlive : bool;
                            isDowned : bool;
                            transform aka bot_transform : float3x4;
                            human_net_phys__isSwimming : bool = false;
                            human_net_phys__isClimbing : bool = false;
                            human_weap__gunEids : EidList;
                            human_weap__currentGunEid : EntityId;
                            squad_member__playerEid : EntityId)
    if !isAlive || isDowned || human_net_phys__isSwimming || human_net_phys__isClimbing
      return

    out_medbox_eid = find_medbox_item_gun(human_weap__gunEids)
    if !out_medbox_eid
      return
    if check_current_gun && human_weap__currentGunEid != out_medbox_eid
      return

    var ourTeam = TEAM_UNASSIGNED
    out_team_eid = INVALID_ENTITY_ID
    if !get_team_and_team_eid(squad_member__playerEid, ourTeam, out_team_eid)
      return

    if !check_current_gun && get_sync_time() < get_float(out_team_eid, "team_bots__placeMedBoxWaitForTime") ?? 0.0
      return

    var targetPos = float3()
    out_target_eid = get_leader_target(bot_eid, leader_target_eid_param_name, targetPos)
    if !out_target_eid
      query() <| $ [es(REQUIRE=capzone)] (active : bool;
                                          eid aka capzone_eid : EntityId;
                                          transform aka capzone_transform : float3x4;
                                          capzone__approximateRadius = -1.0;
                                          sphere_zone__radius = 0.0)
        if !active
          return
        if is_pos_inside_capture_point(bot_transform[3], 0.0, capzone_transform, capzone__approximateRadius, sphere_zone__radius)
          out_target_eid = capzone_eid
      if !out_target_eid
        return

    var capZoneOk = false
    var insideZone = false
    var numBoxes = 0
    query(out_target_eid) <| $ [es(REQUIRE=capzone)] (active : bool;
                                                      capzone__owningTeam : int;
                                                      capzone__onlyTeamCanCapture : int;
                                                      capzone__mustBeCapturedByTeam : int;
                                                      transform aka capzone_transform : float3x4;
                                                      capzone__approximateRadius = -1.0;
                                                      sphere_zone__radius = 0.0)
      if !active
        return
      let captureDefend1 = capzone__onlyTeamCanCapture >= 1 && capzone__onlyTeamCanCapture != ourTeam && capzone__owningTeam != capzone__onlyTeamCanCapture
      let captureDefend2 = capzone__mustBeCapturedByTeam >= 1 && capzone__mustBeCapturedByTeam != ourTeam && capzone__owningTeam != capzone__mustBeCapturedByTeam
      if captureDefend1 || captureDefend2
        capZoneOk = true
        if is_pos_inside_capture_point(bot_transform[3], 0.0, capzone_transform, capzone__approximateRadius, sphere_zone__radius)
          insideZone = true
          query() <| $ [es(REQUIRE=medBox)] (transform aka med_box_transform : float3x4; team : int)
            if team == ourTeam && is_pos_inside_capture_point(med_box_transform[3], 0.0, capzone_transform, capzone__approximateRadius, sphere_zone__radius)
              ++numBoxes
    if !capZoneOk
      log_ai_building(squad_member__playerEid, 270, targetPos)
      return
    if !insideZone
      log_ai_building(squad_member__playerEid, 280, targetPos)
      return
    if numBoxes > 0
      log_ai_building(squad_member__playerEid, 290, targetPos)
      return

    let waitNextCheckPlaceMedBox = rnd_float(15.0, 20.0)
    query(out_team_eid) <| $ [es] (var team_bots__placeMedBoxWaitForTime : float&)
      team_bots__placeMedBoxWaitForTime = max(team_bots__placeMedBoxWaitForTime, get_sync_time() + waitNextCheckPlaceMedBox)

    able = true
  return able


def check_point_valid_for_bot_to_place(place_pos : float3; place_radius : float; min_dist_to_walls : float; max_underwater : float)
  let extents = float3(0.01, 0.2, 0.01)
  var projectedPos = place_pos
  if !project_to_nearest_navmesh_point(projectedPos, extents)
    return 200
  projectedPos.y = place_pos.y
  if distance_sq(projectedPos, place_pos) > square(0.01)
    return 200
  let distanceToWall = get_distance_to_wall(place_pos, place_radius, min_dist_to_walls, null)
  if distanceToWall < min_dist_to_walls
    return 210
  if is_conflict_with_water(place_pos, max_underwater)
    return 220
  return 0

def is_point_valid_for_bot_to_build(build_what : int; build_pos : float3; build : HowBuild)
  if build_what == BUILD_SPAWN_POINT
    var wasDestroyedHere = false
    query(build.teamEid) <| $ [es] (team_bots__customSpawnsDestroyed : Point3List;
                                    team_bots__customSpawnsDestroyedAvoidRadius : float;
                                    team_bots__customSpawnsDestroyedMaxAmount : int)
      let avoidRadiusSq = square(team_bots__customSpawnsDestroyedAvoidRadius)
      var numDestroyed = 0
      for point in team_bots__customSpawnsDestroyed
        if distance_sq(point, build_pos) < avoidRadiusSq
          ++numDestroyed
      if numDestroyed >= team_bots__customSpawnsDestroyedMaxAmount
        log_ai_building(build.playerEid, 500, build_pos)
        wasDestroyedHere = true
        return
    if wasDestroyedHere
      return false

  if build_what == BUILD_AMMO_BOX
    var insideDefendCapZone = false
    query(build.targetEid) <| $ [es(REQUIRE=capzone)] (transform aka capzone_transform : float3x4;
                                                       capzone__approximateRadius = -1.0;
                                                       sphere_zone__radius = 0.0)
      if is_pos_inside_capture_point(build_pos, 0.0, capzone_transform, capzone__approximateRadius, sphere_zone__radius)
        insideDefendCapZone = true
    if !insideDefendCapZone
      log_ai_building(build.playerEid, 270, build_pos)
      return false

  var previewTmpl : ecs::Template const? = null
  query(build.toolEid) <| $ [es] (previewTemplate : StringList)
    let tmpl = getTemplateByName(string(previewTemplate[build.previewId]))
    if tmpl != null
      previewTmpl = tmpl
  if previewTmpl == null
    return false

  var isPointValid = false
  query(build.playerEid) <| $ [es] (team aka player_team : int;
                                    botPlayer__customSpawnMinDistanceAround : float;
                                    botPlayer__customSpawnsBetterDistance : float;
                                    botPlayer__customSpawnSightCheckHeight : float;
                                    botPlayer__customSpawnSightCheckDistance : float;
                                    botPlayer__customSpawnSightMaxDistance : float;
                                    var aiBuilding__debugMsgs : IPoint3List?)
    var buildingRadius = 0.3
    if build_what == BUILD_SPAWN_POINT
      buildingRadius = RESPAWN_POINT_RADIUS
    elif build_what == BUILD_AMMO_BOX
      buildingRadius = AMMO_BOX_RADIUS

    let minDistanceToWall = max(buildingRadius, botPlayer__customSpawnMinDistanceAround)
    let maxUnderwaterDistance = getTemplateComponent(*previewTmpl, "building_builder__maxUnderwaterDistance") ?? 0.0

    let placeError = check_point_valid_for_bot_to_place(build_pos, buildingRadius, minDistanceToWall, maxUnderwaterDistance)
    if placeError > 0
      log_ai_building(aiBuilding__debugMsgs, placeError, build_pos)
      return

    if build_what == BUILD_SPAWN_POINT
      let minDistanceToMissionRespawns = getTemplateComponent(*previewTmpl, "building_builder__minDistanceToMissionRespawns") ?? 0.0
      if is_human_respawn_selector_in_radius_for_team(build_pos, minDistanceToMissionRespawns, player_team)
        log_ai_building(aiBuilding__debugMsgs, 230, build_pos)
        return

      let minDistanceToCapturePoints = getTemplateComponent(*previewTmpl, "building_builder__minDistanceToCapturePoints") ?? 0.0
      if !is_distance_to_capture_points_valid(build_pos, minDistanceToCapturePoints, true)
        log_ai_building(aiBuilding__debugMsgs, 240, build_pos)
        return

    let requiredSpaceAboveObject = getTemplateComponent(*previewTmpl, "requiredSpaceAboveObject") ?? 0.0
    let requiredSpaceAboveObjectOffset = getTemplateComponent(*previewTmpl, "requiredSpaceAboveObjectOffset") ?? 0.0
    if requiredSpaceAboveObject > 0.0
      let buildingBoxMin = get_Point3(getTemplateComponent(*previewTmpl, "buildingBoxMin")) ?? float3()
      let buildingBoxMax = get_Point3(getTemplateComponent(*previewTmpl, "buildingBoxMax")) ?? float3()
      let bBoxDiagonal = buildingBoxMax - buildingBoxMin
      let bBoxDiagonalXZLength = length(bBoxDiagonal.xz)
      if !is_required_space_above_object_free(build_pos, bBoxDiagonalXZLength, requiredSpaceAboveObject, requiredSpaceAboveObjectOffset)
        log_ai_building(aiBuilding__debugMsgs, 250, build_pos)
        return

    if is_in_building_restricted_zone(build_pos, player_team)
      log_ai_building(aiBuilding__debugMsgs, 260, build_pos)
      return

    if build_what == BUILD_SPAWN_POINT
      var ourRespCount = 0.0
      var ourRespMidPos = float3()
      var enemyRespCount = 0.0
      var enemyRespMidPos = float3()
      var sightPoints : array<float3>

      let sightCheckDistSq = square(botPlayer__customSpawnSightMaxDistance)
      let newSpawnWantDistSq = square(distance(build.targetPos, build_pos) + botPlayer__customSpawnsBetterDistance)
      let oldSpawnBetter = find_query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=customRespawnBase)] (active : bool; team : int; transform aka spawn_transform : float3x4; respawnbaseType : string)
        if !active || respawnbaseType != "human"
          return false
        if team == player_team
          let oldSpawnDistSq = distance_sq(build.targetPos, spawn_transform[3])
          if oldSpawnDistSq < newSpawnWantDistSq
            log_ai_building(aiBuilding__debugMsgs, 300, build_pos)
            return true
          ourRespCount += 1.0
          ourRespMidPos += spawn_transform[3]
        else
          enemyRespCount += 1.0
          enemyRespMidPos += spawn_transform[3]
          if length(sightPoints) < 3 && distance_sq(build_pos, spawn_transform[3]) < sightCheckDistSq
            push(sightPoints, spawn_transform[3])
        return false
      if oldSpawnBetter
        return

      if ourRespCount > 0.0 && enemyRespCount > 0.0
        ourRespMidPos *= rcp(ourRespCount)
        enemyRespMidPos *= rcp(enemyRespCount)
        let deltaToOurResps = ourRespMidPos - enemyRespMidPos
        if dot(deltaToOurResps.xz, build_pos.xz - build.targetPos.xz) < 0.0
          log_ai_building(aiBuilding__debugMsgs, 400, build_pos)
          return

      push(sightPoints, build.targetPos)

      var inSightCount = 0
      let sightCheckPt = build_pos + float3(0.0, botPlayer__customSpawnSightCheckHeight, 0.0)
      for point in sightPoints
        let traceVec = normalize(point - build_pos)
        var dist = botPlayer__customSpawnSightCheckDistance
        var norm : float3
        if !traceray_normalized(sightCheckPt, traceVec, dist, norm, ETF_ALL) || dist > botPlayer__customSpawnSightCheckDistance
          ++inSightCount
      if inSightCount * 2 >= length(sightPoints) + 1
        log_ai_building(aiBuilding__debugMsgs, 600, build_pos)
        return

    isPointValid = true
  return isPointValid


def find_bot_build_positions(bot_eid : EntityId; var out_positions : array<float3>; best_height : float; max_dist : float)
  var hasBotPos = false
  var botPos = float3()
  var botForw = float3()
  query(bot_eid) <| $ [es] (transform : float3x4)
    hasBotPos = true
    botPos = transform[3]
    botForw = transform[0]
  if !hasBotPos
    return

  query() <| $ [es] (var covers : CoversComponent&)
    var box : bbox3f
    box.bmax.xyz = botPos + float3(max_dist, 2.5f, max_dist)
    box.bmin.xyz = botPos - float3(max_dist, 1.0f, max_dist)

    var subOptimal = true
    let filterInfo = get_filter_covers_info()
    covers_box_cull(covers, box) <| $ [unused_argument(tm)] (id : int;
                                                             tm : mat44f#)
      assume cover     = covers.list[id]
      assume coverDesc = covers.coverDescs[id]
      if filter_cover(cover, coverDesc, box, 0, filterInfo)
        return

      let slotIdx = rnd_int(0, length(coverDesc.slots) - 1)
      let coverPos = get_cover_slot_pos(cover, coverDesc, slotIdx)

      if min(cover.hLeft, cover.hRight) < best_height
        if subOptimal
          subOptimal = false
          clear(out_positions)
        push(out_positions, coverPos)
      elif subOptimal
        push(out_positions, coverPos)

  if empty(out_positions)
    let BUILD_DISTANCE_AHEAD = 1.1
    let aheadPos = botPos + botForw * BUILD_DISTANCE_AHEAD
    push(out_positions, aheadPos)

def dropdown_bot_build_position(var pos : float3&; over_ground : float)
  pos.y += 0.2
  var height = 2.5
  if tracedown_normalized(pos, height, ETF_DEFAULT)
    pos.y -= height
    pos.y += over_ground

def pick_random_position_to_build(build_what : int;
                                  max_to_check : int;
                                  positions : array<float3>;
                                  over_ground : float;
                                  build : HowBuild;
                                  var out_build_pos : float3&)
  let numPositions = length(positions)
  let baseIdx = rnd_int(0, numPositions - 1)

  let numCheckPositions = min(numPositions, max_to_check)
  for i in range(numCheckPositions)
    let posIdx = (baseIdx + i) % numPositions
    var pos = positions[posIdx]
    dropdown_bot_build_position(pos, over_ground)
    if is_point_valid_for_bot_to_build(build_what, pos, build)
      out_build_pos = pos
      return true
  return false

def pick_random_position_to_place(max_to_check : int;
                                  positions : array<float3>;
                                  over_ground : float;
                                  place_radius : float;
                                  min_dist_to_walls : float;
                                  max_underwater : float;
                                  var out_build_pos : float3&)
  let numPositions = length(positions)
  let baseIdx = rnd_int(0, numPositions - 1)

  let numCheckPositions = min(numPositions, max_to_check)
  for i in range(numCheckPositions)
    let posIdx = (baseIdx + i) % numPositions
    var pos = positions[posIdx]
    dropdown_bot_build_position(pos, over_ground)
    let placeError = check_point_valid_for_bot_to_place(pos, place_radius, min_dist_to_walls, max_underwater)
    if placeError == 0
      out_build_pos = pos
      return true
  return false


def find_point_for_bot_to_build_custom_respawn(bot_eid : EntityId; build : HowBuild; var out_build_pos : float3&)
  var positions : array<float3>
  query(build.playerEid) <| $ [es] (botPlayer__customSpawnSightCheckHeight : float;
                                    botPlayer__customSpawnSearchAroundDistance : float)
    find_bot_build_positions(bot_eid, positions,
                             botPlayer__customSpawnSightCheckHeight,
                             botPlayer__customSpawnSearchAroundDistance)

  return pick_random_position_to_build(BUILD_SPAWN_POINT, 5, positions, 0.05, build, out_build_pos)

def get_pos_in_front_of_bot(bot_eid : EntityId)
  var point = float3()
  query(bot_eid) <| $ [es] (transform : float3x4)
    let botPos = transform[3]
    let botForw = transform[0]
    let PLACE_DISTANCE_AHEAD = 1.1
    point = botPos + botForw * PLACE_DISTANCE_AHEAD
  return point

def get_points_for_bot_to_place_inside_capzone(var out_positions : array<float3>&; bot_eid : EntityId; target_eid : EntityId)
  query(target_eid) <| $ [es] (capzone__insideNavmeshPositions : Point3List)
    for point in capzone__insideNavmeshPositions
      push(out_positions, point)

  if empty(out_positions)
    let aheadPos = get_pos_in_front_of_bot(bot_eid)
    push(out_positions, aheadPos)


[es(tag=server, REQUIRE=rallypoint, on_event=EventOnDestroyBuilding)]
def bot_player_detect_rallypoint_destroyed(evt : Event;
                                           transform : float3x4;
                                           building_destroy__operator : EntityId = INVALID_ENTITY_ID;
                                           team aka rallypoint_team : int)
  var destroyedByEnemy = false
  query(building_destroy__operator) <| $ [es] (squad_member__playerEid : EntityId)
    query(squad_member__playerEid) <| $ [es] (team : int)
      if team != rallypoint_team
        destroyedByEnemy = true
  if !destroyedByEnemy
    return

  query() <| $ [es] (eid aka player_eid : EntityId; team aka player_team : int)
    if rallypoint_team != player_team
      return

    log_ai_building(player_eid, 700, transform[3])

    query() <| $ [es] (team__id : int;
                       var team_bots__customSpawnsDestroyed : Point3List&;
                       team_bots__customSpawnsDestroyedAvoidRadius : float;
                       team_bots__customSpawnsDestroyedMaxAmount : int)
      if team__id != player_team
        return
      let avoidRadiusSq = square(team_bots__customSpawnsDestroyedAvoidRadius)
      var numAlreadyDestroyed = 0
      for point in team_bots__customSpawnsDestroyed
        if distance_sq(point, transform[3]) < avoidRadiusSq
          ++numAlreadyDestroyed
      if numAlreadyDestroyed < team_bots__customSpawnsDestroyedMaxAmount + 1
        push(team_bots__customSpawnsDestroyed, transform[3])
        log_ai_building(player_eid, 710, transform[3])


def is_valid_height_diff(agent_eid : EntityId; build_pos : float3; max_height_diff : float = 0.5)
  var diffH = 0.0
  query(agent_eid) <| $ [es] (transform : float3x4)
    diffH = build_pos.y - transform[3].y
  return abs(diffH) < max_height_diff

class StartBuildBaseNode : BehNodeAdapter
  leaderTargetEidParamName : string
  buildPosParam : int = -1
  buildTargetEidParam : int = -1
  buildingRadius : float = 0.0
  waitStartBuildMaxTime : float = 2.0
  waitTimer : float = 0.0
  waitPos : float3 = float3()

  def override loadFromBlk(var data : DataBlock) : void
    leaderTargetEidParamName = datablock_getStr(data, "leaderTargetEidParam", "leaderTargetEid")
    buildPosParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "buildPosParam", ""), float3())
    buildTargetEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "buildTargetEidParam", ""), 0)
    waitStartBuildMaxTime = datablock_getReal(data, "waitStartBuildMaxTime", waitStartBuildMaxTime)

  def override init() : void
    waitTimer = 0.0

  def abstract build_node_accept_preview(agent_eid : EntityId; preview_eid : EntityId; preview_pos : float3) : void
  def abstract build_node_failed_preview(agent_eid : EntityId) : void
  def abstract build_node_find_how_build(agent_eid : EntityId; build_pos : float3) : HowBuild
  def abstract build_node_check_place_normal(normal : float3) : bool
  def abstract build_node_build_began(build : HowBuild; build_pos : float3) : void

  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if agent == null
      return EBehResult ER_FAILED

    if waitTimer > 0.0
      var phys = agent.phys
      if phys != null
        let crawling = phys.appliedCT |> is_control_bit_set(HumanPhysControlType HCT_CRAWL)
        let crouching = phys.appliedCT |> is_control_bit_set(HumanPhysControlType HCT_CROUCH)
        if crawling || !crouching
          assume ct = phys.producedCT
          ct |> human_control_state_set_neutral_ctrl()
          ct |> human_control_state_set_walk_speed(0.f)
          ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_CRAWL, false)
          ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_CROUCH, true)

      let gotPreview = find_query() <| $ [es(REQUIRE=builder_preview)] (eid aka preview_eid : EntityId; buildByEngineerEid : EntityId; transform : float3x4)
        if buildByEngineerEid != agent.eid
          return false
        let BUILD_POS_TOLERANCE = 0.01
        if distance_sq(transform[3], waitPos) > square(BUILD_POS_TOLERANCE)
          return false
        build_node_accept_preview(agent.eid, preview_eid, transform[3])
        owner.blackBoard |> set(buildTargetEidParam, int(uint(preview_eid)))
        return true
      if gotPreview
        return EBehResult ER_SUCCESS

      waitTimer -= dt
      if waitTimer > 0.0
        return EBehResult ER_RUNNING

      build_node_failed_preview(agent.eid)
      return EBehResult ER_FAILED

    let buildPos = owner.blackBoard |> datablock_getPoint3(buildPosParam)

    let build = build_node_find_how_build(agent.eid, buildPos)
    if !build.able
      return EBehResult ER_FAILED

    var hasPath = false
    query(agent.eid) <| $ [es] (transform : float3x4)
      let extents = float3(0.5, FLT_MAX, 0.5)
      if check_path(buildPos, transform[3], extents, 0.5, 1.0)
        hasPath = true
    if !hasPath
      log_ai_building(build.playerEid, 310, buildPos)
      return EBehResult ER_FAILED

    var ri_preview_name = ""
    query(build.toolEid) <| $ [es] (previewTemplate : StringList; var currentPreviewId : int&)
      let tmpl = getTemplateByName(string(previewTemplate[build.previewId]))
      if tmpl != null
        ri_preview_name = getTemplateComponent(*tmpl, "ri_preview__name") ?? ""
        if empty(ri_preview_name)
          ri_preview_name = getTemplateComponent(*tmpl, "ai_ri_preview_name") ?? ""
        if !empty(ri_preview_name)
          currentPreviewId = build.previewId // NOTE: directly set currentPreviewId
    if empty(ri_preview_name)
      return EBehResult ER_FAILED

    // NOTE: directly force AI engineer to have "unlimited" builder stock
    query(agent.eid) <| $ [es] (var stockOfBuilderCapabilities : float&)
      stockOfBuilderCapabilities = 1000.0

    var buildTM = float3x4()
    if build.orientTo == ORIENT_TO_TARGET
      buildTM[0] = normalize(build.targetPos - buildPos)
    elif build.orientTo == ORIENT_TO_RANDOM
      buildTM[0] = angles_to_dir(float2(rnd_float(0.0, TWOPI), 0.0))
    else
      query(agent.eid) <| $ [es] (transform : float3x4)
        buildTM[0] = normalize(transform[0])

    buildTM[1] = float3(0.0, 1.0, 0.0)
    buildTM[2] = normalize(cross(buildTM[0], buildTM[1]))
    buildTM[3] = buildPos

    var dist = 0.1
    let down = float3(0.0, -1.0, 0.0)
    var norm : float3
    if traceray_normalized(buildPos, down, dist, norm, ETF_ALL) && build_node_check_place_normal(norm)
      buildTM[1] = norm
      buildTM[2] = normalize(cross(buildTM[0], buildTM[1]))
      buildTM[0] = normalize(cross(buildTM[1], buildTM[2]))

    if soft_check_is_conflict_objects_in_building_box(buildTM, BBox3(buildPos, buildingRadius * 2f))
      return EBehResult ER_FAILED

    send_net_event(agent.eid, [[CmdBuildFortification builderGunEid=build.toolEid, tm=buildTM, boxMin=float3(), boxMax=float3()]])

    build_node_build_began(build, buildPos)

    if waitStartBuildMaxTime > 0.0
      query(build.teamEid) <| $ [es] (var team_bots__buildWaitForTime : float&)
        team_bots__buildWaitForTime = max(team_bots__buildWaitForTime, get_sync_time() + waitStartBuildMaxTime + 0.5)

    waitTimer = waitStartBuildMaxTime
    waitPos = buildTM[3]
    return EBehResult ER_RUNNING


[beh_node(name="isEngineer")]
class isEngineer : BehNodeAdapter
  def override update(dt : float) : EBehResult
    return !!find_engineer_tool(beh_tree_eid(owner)) ? EBehResult ER_SUCCESS : EBehResult ER_FAILED


[beh_node(name="checkBuildCustomRespawnPoint")]
class CheckBuildCustomRespawnPoint : BehNodeAdapter
  leaderTargetEidParamName : string
  buildPosParam : int = -1

  def override loadFromBlk(var data : DataBlock) : void
    leaderTargetEidParamName = datablock_getStr(data, "leaderTargetEidParam", "leaderTargetEid")
    buildPosParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "buildPosParam", ""), float3())

  def override update(dt : float) : EBehResult
    let agentEid = beh_tree_eid(owner)

    let build = find_how_bot_able_to_build(BUILD_SPAWN_POINT, agentEid, leaderTargetEidParamName, false)
    if !build.able
      return EBehResult ER_FAILED

    var buildPos = float3()
    if !find_point_for_bot_to_build_custom_respawn(agentEid, build, buildPos)
      return EBehResult ER_FAILED

    owner.blackBoard |> set(buildPosParam, buildPos)
    return EBehResult ER_SUCCESS

[beh_node(name="startBuildCustomRespawnPoint")]
class StartBuildCustomRespawnPoint : StartBuildBaseNode
  override buildingRadius = RESPAWN_POINT_RADIUS

  def override build_node_accept_preview(agent_eid : EntityId; preview_eid : EntityId; preview_pos : float3) : void
    query(agent_eid) <| $ [es] (squad_member__playerEid : EntityId)
      query(squad_member__playerEid) <| $ [es] (team : int)
        log_ai_building(squad_member__playerEid, 1000, preview_pos)
        query() <| $ [es] (team__id : int; var team_bots__customSpawnsBuildingEids : EidList&)
          if team__id == team
            push(team_bots__customSpawnsBuildingEids, preview_eid)

  def override build_node_failed_preview(agent_eid : EntityId) : void
    query(agent_eid) <| $ [es] (squad_member__playerEid : EntityId)
      log_ai_building(squad_member__playerEid, 1100)

  def override build_node_find_how_build(agent_eid : EntityId; build_pos : float3) : HowBuild
    var build = find_how_bot_able_to_build(BUILD_SPAWN_POINT, agent_eid, leaderTargetEidParamName, true)
    if !build.able
      return build

    if !is_point_valid_for_bot_to_build(BUILD_SPAWN_POINT, build_pos, build)
      build.able = false
      return build

    if !is_valid_height_diff(agent_eid, build_pos, 0.5)
      build.able = false
      log_ai_building(build.playerEid, 1200, build_pos)
      return build

    return build

  def override build_node_check_place_normal(normal : float3) : bool
    return normal.y > 0.95

  def override build_node_build_began(build : HowBuild; build_pos : float3) : void
    log_ai_building(build.playerEid, 1300, build_pos)


[beh_node(name="checkBuildAmmoBox")]
class CheckBuildAmmoBox : BehNodeAdapter
  leaderTargetEidParamName : string
  buildPosParam : int = -1

  def override loadFromBlk(var data : DataBlock) : void
    leaderTargetEidParamName = datablock_getStr(data, "leaderTargetEidParam", "leaderTargetEid")
    buildPosParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "buildPosParam", ""), float3())

  def override update(dt : float) : EBehResult
    let agentEid = beh_tree_eid(owner)

    let build = find_how_bot_able_to_build(BUILD_AMMO_BOX, agentEid, leaderTargetEidParamName, false)
    if !build.able
      return EBehResult ER_FAILED

    var positions : array<float3>
    get_points_for_bot_to_place_inside_capzone(positions, agentEid, build.targetEid)

    var buildPos = float3()
    if !pick_random_position_to_build(BUILD_AMMO_BOX, 5, positions, -0.05, build, buildPos)
      return EBehResult ER_FAILED

    owner.blackBoard |> set(buildPosParam, buildPos)
    return EBehResult ER_SUCCESS

[beh_node(name="startBuildAmmoBox")]
class StartBuildAmmoBox : StartBuildBaseNode
  override buildingRadius = AMMO_BOX_RADIUS

  [unused_argument(preview_eid)] def override build_node_accept_preview(agent_eid : EntityId; preview_eid : EntityId; preview_pos : float3) : void
    query(agent_eid) <| $ [es] (squad_member__playerEid : EntityId)
      log_ai_building(squad_member__playerEid, 1000, preview_pos)

  def override build_node_failed_preview(agent_eid : EntityId) : void
    query(agent_eid) <| $ [es] (squad_member__playerEid : EntityId)
      log_ai_building(squad_member__playerEid, 1100)

  def override build_node_find_how_build(agent_eid : EntityId; build_pos : float3) : HowBuild
    var build = find_how_bot_able_to_build(BUILD_AMMO_BOX, agent_eid, leaderTargetEidParamName, true)
    if !build.able
      return build

    if !is_point_valid_for_bot_to_build(BUILD_AMMO_BOX, build_pos, build)
      build.able = false
      return build

    if !is_valid_height_diff(agent_eid, build_pos, 0.5)
      build.able = false
      log_ai_building(build.playerEid, 1200, build_pos)
      return build

    return build

  def override build_node_check_place_normal(normal : float3) : bool
    return normal.y > 0.91

  def override build_node_build_began(build : HowBuild; build_pos : float3) : void
    log_ai_building(build.playerEid, 1300, build_pos)


[beh_node(name="checkPlaceMedBox")]
class CheckPlaceMedBox : BehNodeAdapter
  leaderTargetEidParamName : string
  buildPosParam : int = -1

  def override loadFromBlk(var data : DataBlock) : void
    leaderTargetEidParamName = datablock_getStr(data, "leaderTargetEidParam", "leaderTargetEid")
    buildPosParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "buildPosParam", ""), float3())

  def override update(dt : float) : EBehResult
    let agentEid = beh_tree_eid(owner)

    var tmpMedBoxEid = INVALID_ENTITY_ID
    var targetEid = INVALID_ENTITY_ID
    var tmpTeamEid = INVALID_ENTITY_ID
    if !find_if_bot_able_to_drop_medbox(agentEid, leaderTargetEidParamName, false, tmpMedBoxEid, targetEid, tmpTeamEid)
      return EBehResult ER_FAILED

    var positions : array<float3>
    get_points_for_bot_to_place_inside_capzone(positions, agentEid, targetEid)

    if empty(positions)
      return EBehResult ER_FAILED

    let minDistToWalls = 0.5
    let maxUnderwater = 0.2

    let maxNearDistance = 10.0
    let maxNearDistanceSq = square(maxNearDistance)

    var botPos = float3()
    query(agentEid) <| $ [es] (transform : float3x4)
      botPos = transform[3]

    var pickPositions : array<float3>
    var nearestPosition = float3()
    var bestDistSq = FLT_MAX
    for point in positions
      var pos = point
      dropdown_bot_build_position(pos, 0.0)
      let placeError = check_point_valid_for_bot_to_place(pos, MED_BOX_RADIUS, minDistToWalls, maxUnderwater)
      if placeError == 0
        let distSq = distance_sq(point, botPos)
        if distSq < maxNearDistanceSq
          push(pickPositions, pos)
        elif distSq < bestDistSq
          nearestPosition = pos
          bestDistSq = distSq

    var buildPos = botPos
    if !empty(pickPositions)
      buildPos = pickPositions[rnd_int(0, length(pickPositions) - 1)]
    else
      buildPos = nearestPosition
      if bestDistSq >= FLT_MAX
        return EBehResult ER_FAILED

    owner.blackBoard |> set(buildPosParam, buildPos)
    return EBehResult ER_SUCCESS

[beh_node(name="placeMedBox")]
class PlaceMedBox : BehNodeAdapter
  leaderTargetEidParamName : string
  buildPosParam : int = -1

  waitTimer : float = 0.0
  waitDropTime : float = 0.5

  def override loadFromBlk(var data : DataBlock) : void
    leaderTargetEidParamName = datablock_getStr(data, "leaderTargetEidParam", "leaderTargetEid")
    buildPosParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "buildPosParam", ""), float3())

  def override init() : void
    waitTimer = 0.0

  def override exit() : void
    var agent = beh_tree_entity_agent(*owner)
    if waitTimer > 0.0 && agent.phys != null
      agent.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_SHOOT, false)

  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if agent == null
      return EBehResult ER_FAILED

    if waitTimer > 0.0
      var phys = agent.phys
      if phys != null
        let crawling = phys.appliedCT |> is_control_bit_set(HumanPhysControlType HCT_CRAWL)
        let crouching = phys.appliedCT |> is_control_bit_set(HumanPhysControlType HCT_CROUCH)
        if crawling || !crouching
          assume ct = phys.producedCT
          ct |> human_control_state_set_neutral_ctrl()
          ct |> human_control_state_set_walk_speed(0.f)
          ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_CRAWL, false)
          ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_CROUCH, true)

      waitTimer -= dt
      if waitTimer > 0.0
        return EBehResult ER_RUNNING

      if agent.phys != null
        agent.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_SHOOT, false)

      return EBehResult ER_SUCCESS

    var medBoxEid = INVALID_ENTITY_ID
    var tmpTargetEid = INVALID_ENTITY_ID
    var teamEid = INVALID_ENTITY_ID
    if !find_if_bot_able_to_drop_medbox(agent.eid, leaderTargetEidParamName, true, medBoxEid, tmpTargetEid, teamEid)
      return EBehResult ER_FAILED

    var slotEid = INVALID_ENTITY_ID
    var additionalHeight = 0.0
    query(medBoxEid) <| $ [es] (slot_attach__attachedTo : EntityId;
                                placeable_item__additionalHeight : float = 0.0)
      slotEid = slot_attach__attachedTo
      additionalHeight = placeable_item__additionalHeight
    if !slotEid
      return EBehResult ER_FAILED

    if agent.phys != null
      agent.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_SHOOT, true)

    let buildPos = owner.blackBoard |> datablock_getPoint3(buildPosParam)
    var placeTM = float3x4()

    query(agent.eid) <| $ [es] (transform : float3x4)
      placeTM[0] = normalize(transform[0])

    placeTM[1] = float3(0.0, 1.0, 0.0)
    placeTM[2] = normalize(cross(placeTM[0], placeTM[1]))
    placeTM[3] = buildPos + float3(0.0, additionalHeight, 0.0)

    var dist = 0.1
    let down = float3(0.0, -1.0, 0.0)
    var norm : float3
    if traceray_normalized(buildPos, down, dist, norm, ETF_ALL) && norm.y > 0.91
      placeTM[1] = norm
      placeTM[2] = normalize(cross(placeTM[0], placeTM[1]))
      placeTM[0] = normalize(cross(placeTM[1], placeTM[2]))

    if soft_check_is_conflict_objects_in_building_box(placeTM, BBox3(placeTM[3], MED_BOX_RADIUS * 2f))
      return EBehResult ER_FAILED

    send_net_event(slotEid, [[CmdStartPlacePlaceableItem
                              itemEid = medBoxEid,
                              tm = placeTM,
                              vehicleEid = INVALID_ENTITY_ID,
                              vehicleNodeId = 0]])

    waitTimer = waitDropTime
    return EBehResult ER_RUNNING
