require enlisted.events_enlisted
require game.es.events
require Dacoll
require DagorMath
require DagorMathUtils
require math.base
require AnimV20
require GeomNodeTree
require EnlistedNet
require ecs

[es] //via event instead of function call because we can't change color in parallel thread because we can render it at same time in main thread.
def update_building_preview_colors(evt : EventUpdateBuildingColors)
  let selectedObject = evt.selectedObject
  let builderPos = evt.builderPos
  let isEngineer = evt.isEngineer
  let engineer_team = evt.engineerTeam
  query() <| $ [es(REQUIRE_NOT=builder_additive_preview, REQUIRE=builder_server_preview)] (
                                                                                           eid : EntityId;
                                                                                           transform : float3x4;
                                                                                           visibleDistance : float;
                                                                                           selectedPlacingColor : float3;
                                                                                           enemyPlacingColor : float3;
                                                                                           previewTeam : int;
                                                                                           previewColor : float3;
                                                                                           var semi_transparent__placingColor : float3&;
                                                                                           var semi_transparent__visible : bool&;
                                                                                           var animchar_render__enabled : bool?;
                                                                                           preview_render__enabled : bool = true)
    if animchar_render__enabled != null
      *animchar_render__enabled = preview_render__enabled

    if !preview_render__enabled
      semi_transparent__visible = false
      return

    if eid == selectedObject
      semi_transparent__visible = true
      if previewTeam == engineer_team
        semi_transparent__placingColor = selectedPlacingColor
      return
    if !isEngineer && has(eid, "onlyForEngineer")
      semi_transparent__visible = false
      return
    let distane = length(transform[3] - builderPos)
    if distane > visibleDistance
      semi_transparent__visible = false
      return ;
    semi_transparent__visible = true
    let colorCoef = 1.0 - distane / visibleDistance
    if previewTeam != engineer_team
      semi_transparent__visible = false // force hiding enemy preview
      semi_transparent__placingColor = enemyPlacingColor * colorCoef
      return
    semi_transparent__placingColor = previewColor * colorCoef

def validate_fortification_action_object_pos(object_pos; trace_from; eps = 0.1f)
  let traceDir = object_pos - trace_from
  let dist = length(traceDir)
  let traceDirNormilised = traceDir * safeinv(dist)
  var norm : float3
  var validDist = max(0.f, dist - eps)
  return !traceray_normalized(trace_from, traceDirNormilised, validDist, norm, ETF_ALL)

def test_segment_sphere_intersection_nonblocking(p0 : float3;
                                                 p1 : float3;
                                                 sphere_center : float3;
                                                 squared_sphere_radius : float)
  let oc = sphere_center - p0

  let l2oc = dot(oc, oc)
  var rsqr = squared_sphere_radius
  if (rsqr > l2oc) // If inside shrink radius to 2/3 distance to center to keep control even close to center of sphere
    rsqr = l2oc * 0.45

  let dir = p1 - p0
  let tca = dot(oc, dir)
  if tca <= 0.0
    return false // Points away.

  let dir2 = dot(dir, dir)
  let tca2 = (tca * tca) / dir2
  let l2hc = rsqr - l2oc + tca2
  if l2hc < 0.0
    return false // Misses the sphere.

  if tca2 + l2hc - 2.0 * sqrt(tca2 * l2hc) > dir2
    return false // Segment ends.

  return true

def find_fortification_object_impl(eid, is_engineer, center, radius, trace_from, trace_to, trace_max_len)
  if (length_sq(trace_from - center) > square(trace_max_len))
    return INVALID_ENTITY_ID
  let onlyForEngineer = has(eid, "onlyForEngineer")
  var isPreviewFound  = !onlyForEngineer || is_engineer
  if isPreviewFound
    let isOnLineOfSight = test_segment_sphere_intersection_nonblocking(trace_from, trace_to, center, square(radius))
    isPreviewFound &&= isOnLineOfSight
  return isPreviewFound ? eid : INVALID_ENTITY_ID

def find_server_preview(is_engineer, trace_from, trace_to, trace_max_len)
  var previewEid = INVALID_ENTITY_ID
  find_query() <| $ [es(REQUIRE_NOT=builder_additive_preview, REQUIRE=builder_server_preview)] (eid : EntityId;
                                                                                                transform : float3x4;
                                                                                                buildingRadius : float;
                                                                                                object__useDist : float const?;
                                                                                                additionalHeight : float = 0.f;
                                                                                                engineer_building__validationHeight : float = 0.5)
    let posOffset = float3(0f, max(-additionalHeight + engineer_building__validationHeight, 0f), 0f)
    let fortificationPos = transform[3] + posOffset
    previewEid = find_fortification_object_impl(eid, is_engineer, fortificationPos, buildingRadius, trace_from, trace_to, object__useDist ?? trace_max_len)
    if !!previewEid && !validate_fortification_action_object_pos(fortificationPos, trace_from)
      previewEid = INVALID_ENTITY_ID
    return !!previewEid
  return previewEid

def find_usable_buildings(is_engineer, trace_from, trace_to, trace_max_len)
  var buildingEid = INVALID_ENTITY_ID
  find_query() <| $ [es(REQUIRE=(engineer_building__isUsable), REQUIRE_NOT=(builder_additive_preview, builder_server_preview))] (eid : EntityId;
                                                                                                                                 transform : float3x4;
                                                                                                                                 buildingRadius : float;
                                                                                                                                 object__useDist : float const?)
    buildingEid = find_fortification_object_impl(eid, is_engineer, transform[3], buildingRadius, trace_from, trace_to, object__useDist ?? trace_max_len)
    return !!buildingEid
  return buildingEid

def find_destroyable_buildings(is_engineer, trace_from, trace_to, trace_max_len)
  var previewEid = INVALID_ENTITY_ID
  find_query() <| $ [es(REQUIRE=buildByPlayer, REQUIRE_NOT=(builder_additive_preview, builder_server_preview))] (eid : EntityId;
                                                                                                                 transform : float3x4;
                                                                                                                 buildingRadius : float;
                                                                                                                 object__useDist : float const?)
    previewEid = find_fortification_object_impl(eid, is_engineer, transform[3], buildingRadius, trace_from, trace_to, object__useDist ?? trace_max_len)
    return !!previewEid
  return previewEid

[es(tag=gameClient, REQUIRE=watchedByPlr, after=hero_human_use_human_object_es, after=hero_human_use_stationary_gun_object_es, after=hero_human_pre_use_object_es, before=hero_human_final_use_object_sync)]
def find_bilding_action_target(info : ParallelUpdateFrameDelayed;
                               bindedCamera : EntityId;
                               team : int;
                               human_weap__currentGunEid : EntityId;
                               human_use_object__nodeId : int;
                               human_use_object__useDist : float;
                               animchar : AnimcharBaseComponent;
                               transform : float3x4;
                               isInVehicle : bool = false;
                               human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                               human_binocular__mode : bool = false;
                               var human_use_object__selectedObject : EntityId&;
                               var human_use_object__selectedBuilding : EntityId&)
  if has(bindedCamera, "spectator")
    return

  let isEngineer = !isInVehicle && has(human_weap__currentGunEid, "previewEid")
  if isInVehicle
    broadcastEvent([[EventUpdateBuildingColors selectedObject = human_use_object__selectedBuilding,
                                               builderPos = transform[3],
                                               isEngineer = isEngineer,
                                               engineerTeam = team]])
    return
  let camTmRef = get_TMatrix(bindedCamera, "transform")
  if camTmRef == null
    return
  let camTm = *camTmRef
  let traceDir : float3 = camTm[2]
  let tracePos : float3 = (human_use_object__nodeId > 0
    ? geomtree_getNodeWpos(*animchar.nodeTree, human_use_object__nodeId)
    : camTm[3])
  let endOfTrace = tracePos + traceDir * human_use_object__useDist
  if human_binocular__mode || !!human_attached_gun__attachedGunEid
    human_use_object__selectedBuilding = INVALID_ENTITY_ID
    return
  human_use_object__selectedBuilding = find_server_preview(isEngineer, tracePos, endOfTrace, human_use_object__useDist)
  if !human_use_object__selectedBuilding
    human_use_object__selectedBuilding = find_destroyable_buildings(isEngineer, tracePos, endOfTrace, human_use_object__useDist)
  if !human_use_object__selectedObject
    human_use_object__selectedObject = find_usable_buildings(isEngineer, tracePos, endOfTrace, human_use_object__useDist)
  broadcastEvent([[EventUpdateBuildingColors selectedObject = human_use_object__selectedBuilding,
                                             builderPos = camTm[3],
                                             isEngineer = isEngineer,
                                             engineerTeam = team]])

[es(tag=server, track=(isAlive, isDowned, human_weap__mortarMode, human_weap__radioMode, burning__isBurning), REQUIRE=building_action__target)]
def building_action_reset_on_die(evt : Event;
                                 eid : EntityId;
                                 isAlive : bool;
                                 isDowned : bool;
                                 human_weap__mortarMode : bool;
                                 burning__isBurning : bool;
                                 human_weap__radioMode : bool)
  if !isAlive || isDowned || human_weap__mortarMode || human_weap__radioMode || burning__isBurning
    send_net_event(eid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])

[es(tag=server, track=building_action__target)]
def building_action_reset_timer(evt : Event;
                                building_action__target : EntityId;
                                var building_action__lastActionAtTime : float&)
  if building_action__target == INVALID_ENTITY_ID
    building_action__lastActionAtTime = -1.0

[es(tag=server, REQUIRE=human_use_object__selectedBuilding)]
def building_action_net_start(evt : EventSetBuildingTarget;
                              isAlive : bool;
                              isDowned : bool;
                              human_weap__mortarMode : bool;
                              burning__isBurning : bool;
                              human_weap__radioMode : bool;
                              var building_action__target : EntityId&)
  if !isAlive || isDowned || human_weap__mortarMode || human_weap__radioMode || burning__isBurning
    building_action__target = INVALID_ENTITY_ID
  else
    building_action__target = evt.target