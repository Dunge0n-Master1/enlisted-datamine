require ecs
require ecs.common
require ecs.safe
require math
require math.base
require math.easing
require math.ang
require vehicle
require player
require AnimV20
require GeomNodeTree
require DagorMath
require DagorSystem
require DagorMath
require DagorMathUtils
require WorldRenderer
require game.es.vehicle.vehicle_events
require game.es.vehicle.vehicle_seats_common
require dm
require strings

let
  quat_ident = float4(0.f, 0.f, 0.f, 1.f)

[es(on_appear, on_event=(EventHeroChanged, EventOnSeatOwnersChanged), track=(vehicleCameraType, cockpit__eid, isTpsView), tag=render, REQUIRE=(vehicleCameraType, vehicleWithWatched, cockpit__eid))]
def vehicle_change_cockpit_es(evt : Event;
                              eid : EntityId;
                              [[shared_comp]] vehicle_seats__seats : Array;
                              vehicle_seats__seatEids : EidList;
                              vehicleCameraType : int;
                              isTpsView : bool = false;
                              var vehicle_sight__opacity : float&)
  if isTpsView
    return

  if (vehicleCameraType == int(VehicleCameraType VEHICLE_CAMERA_COMMANDER) ||
      vehicleCameraType == int(VehicleCameraType VEHICLE_CAMERA_DEAD))
    return

  let heroSeatIdx = vehicle_get_watched_seat_idx(vehicle_seats__seatEids)
  if heroSeatIdx < 0
    return

  let hasCockpit = find_query() <| $ [es] (cockpit__vehicleEid : EntityId)
    return cockpit__vehicleEid == eid

  if hasCockpit
    return

  let attachNodeIndex = get_int(vehicle_seats__seatEids[heroSeatIdx], "seat__cameraNodeNo") ?? -1
  if attachNodeIndex < 0
    return

  let seat = get_ecs_object(vehicle_seats__seats[heroSeatIdx])
  let cockpitTemplate = get_string(seat, "cockpitTemplate", "")
  if cockpitTemplate == ""
    return

  let effectors = get_ecs_object(seat, "effectors")

  vehicle_sight__opacity = 0.f

  createEntitySync(cockpitTemplate) <| $(var init : ComponentsInitializer)
    set(init, "cockpit__attachNodeIndex", attachNodeIndex)
    set(init, "cockpit__vehicleEid", eid)
    set(init, "cockpit__seatNo", heroSeatIdx)
    set(init, "cockpit__cameraTime", 1.f)
    set(init, "cockpit__zoomTime", 0.f)
    if effectors != null
      set(init, "cockpit__effectorsInfo", *effectors)

[es(on_appear)]
def cockpit_attach_nodes_init(evt : Event;
                              cockpit__vehicleEid : EntityId;
                              cockpit__attachNodeIndex : int;
                              cockpit__attachNodeNames : StringList;
                              cockpit__slitNodeNames : StringList;
                              var cockpit__attachNodeIndices : IntList)
  ecs::query(cockpit__vehicleEid) <| $ [es] (animchar : AnimcharBaseComponent)
    let slitNodesCount = length(cockpit__slitNodeNames)
    let attachNodesCount = length(cockpit__attachNodeNames)
    let commonNodesCount = min(slitNodesCount, attachNodesCount)
    resize(cockpit__attachNodeIndices, slitNodesCount)
    for i in range(0, commonNodesCount)
      let nodeName = string(cockpit__attachNodeNames[i])
      cockpit__attachNodeIndices[i] = geomtree_findNodeIndex(*animchar.nodeTree, nodeName)
    for i in range(commonNodesCount, slitNodesCount)
      cockpit__attachNodeIndices[i] = cockpit__attachNodeIndex

[es(tag=gameClient, on_appear, on_disappear, on_event=EventOnSeatOwnersChanged, REQUIRE=vehicleWithWatched)]
def vehicle_is_cockpit_seat(evt : Event;
                            [[shared_comp]] vehicle_seats__seats : Array;
                            vehicle_seats__seatEids : EidList;
                            var cockpit__isHeroInCockpit : bool&)
  let heroSeatIdx = vehicle_get_watched_seat_idx(vehicle_seats__seatEids)
  if heroSeatIdx < 0
    cockpit__isHeroInCockpit = false
    return
  let seat = get_ecs_object(vehicle_seats__seats[heroSeatIdx])
  let cockpitTemplate = get_string(seat, "cockpitTemplate", "")
  cockpit__isHeroInCockpit = cockpitTemplate != ""

def reset_all_nodes_filter(var filter : UInt8List; animchar_render : AnimcharRendComponent; baseValue : uint8 = uint8(~0))
  let nodesCount = length(filter)
  for nodeId in range(0, nodesCount)
    if animchar_render.sceneInstance |> scene_instance_is_node_visible(nodeId)
      filter[nodeId] = baseValue
    else
      filter[nodeId] = uint8(0)

def filter_update_hidden(var filter : UInt8List; animchar_render : AnimcharRendComponent)
  let nodesCount = length(filter)
  for nodeId in range(0, nodesCount)
    if !animchar_render.sceneInstance |> scene_instance_is_node_visible(nodeId)
      filter[nodeId] = uint8(0)
    elif filter[nodeId] == uint8(0)
      filter[nodeId] = uint8(~0)

[es(tag=render, after=after_animchar_update_sync, REQUIRE_NOT=cockpit__binocular)]
def vehicle_attach_cockpit_es(info : UpdateStageInfoAct;
                              eid : EntityId;
                              var animchar_render__enabled : bool&;
                              var transform : float3x4;
                              var cockpit__isAttached : bool&;
                              var cockpit__attachNodeIndex : int&;
                              cockpit__attachNodeIndices : IntList const?;
                              cockpit__currentSlit : int;
                              cockpit__cockpitOffsetBySlit : Point3List const?;
                              cockpit__offset : float3;
                              cockpit__vehicleEid : EntityId;
                              cockpit__seatNo : int;
                              cockpit__angles : float3 const?;
                              cockpit__scale = float3(1.0, 1.0, -1.0);
                              cockpit__showInDeadVehicle : bool = false)
  cockpit__isAttached = false
  query(cockpit__vehicleEid) <| $ [es(REQUIRE=vehicleWithWatched)] (animchar : AnimcharBaseComponent;
                                                                    vehicle_seats__seatEids : EidList;
                                                                    vehicleCameraType : int;
                                                                    isTpsView : bool = false;
                                                                    isAlive, isExploded : bool)

    if (!cockpit__showInDeadVehicle && (!isAlive || isExploded)) || isTpsView
      return

    if (vehicleCameraType == int(VehicleCameraType VEHICLE_CAMERA_COMMANDER) ||
       (vehicleCameraType == int(VehicleCameraType VEHICLE_CAMERA_DEAD) && !cockpit__showInDeadVehicle))
      return

    let heroSeatNo = vehicle_get_watched_seat_idx(vehicle_seats__seatEids)
    if heroSeatNo < 0 || heroSeatNo != cockpit__seatNo
      return

    if cockpit__attachNodeIndices != null
      cockpit__attachNodeIndex = (*cockpit__attachNodeIndices)[cockpit__currentSlit]
    cockpit__isAttached = true

    var offset = cockpit__offset
    if cockpit__cockpitOffsetBySlit != null
      offset += (*cockpit__cockpitOffsetBySlit)[cockpit__currentSlit]

    geomtree_getNodeWtmScalar(*animchar.nodeTree, cockpit__attachNodeIndex, transform)
    transform[0] = transform[0] * cockpit__scale.x
    transform[1] = transform[1] * cockpit__scale.y
    transform[2] = transform[2] * cockpit__scale.z

    transform[3] = transform * offset

    if cockpit__angles != null
      transform = transform * make_rot_cw_zyx(*cockpit__angles * DEG_TO_RAD)

  if !cockpit__isAttached
    animchar_render__enabled = false
    destroyEntity(eid)

[es(tag=render, track=cockpit__isAttached)]
def vehicle_cockpit_slits_init(evt : Event;
                               eid : EntityId;
                               animchar : AnimcharBaseComponent;
                               cockpit__isAttached : bool;
                               cockpit__slitNodeNames : StringList;
                               cockpit__slitAngles : FloatList const?;
                               cockpit__cockpitOffsetBySlit : Point3List const?;
                               cockpit__offset : float3;
                               transform : float3x4;
                               var cockpit__slitNodes : IntList;
                               var cockpit__slitCameraOffsets : Point3List;
                               var cockpit__slitCameraDirs : Point3List)
  if !cockpit__isAttached
    return

  let nodesCount = length(cockpit__slitNodeNames)
  resize(cockpit__slitNodes, nodesCount)
  resize(cockpit__slitCameraOffsets, nodesCount)
  resize(cockpit__slitCameraDirs, nodesCount)

  var cockpitTm := transform
  cockpitTm[2] = -cockpitTm[2]
  let cockpitItm = inverse(cockpitTm)

  for i in range(0, nodesCount)
    let slitNodeId = geomtree_findNodeIndex(*animchar.nodeTree, string(cockpit__slitNodeNames[i]))
    cockpit__slitNodes[i] = slitNodeId
    if slitNodeId < 0
      logerr("Cockpit node '{cockpit__slitNodeNames[i]}' not found. Vehicle {eid} <{getEntityTemplateName(eid)}>")
      continue

    var slitNodeWtm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, slitNodeId, slitNodeWtm)

    var offset = cockpit__offset
    if cockpit__cockpitOffsetBySlit != null
      offset += (*cockpit__cockpitOffsetBySlit)[i]
    offset[2] = -offset[2]

    let slitRelToCockpitTm = cockpitItm * slitNodeWtm
    cockpit__slitCameraOffsets[i] = slitRelToCockpitTm[3] + offset

    if cockpit__slitAngles != null
      let angle = deg_to_rad((*cockpit__slitAngles)[i])
      cockpit__slitCameraDirs[i] = float3(cos(angle), 0.f, sin(angle))
    else
      cockpit__slitCameraDirs[i] = normalize(slitRelToCockpitTm[0])

[es(tag=render, on_appear, after=disable_animchar_nodes_es)]
def nodes_filter_init(evt : Event;
                      animchar_render : AnimcharRendComponent;
                      var animchar_render__nodeVisibleStgFilters : UInt8List)
  let renderNodesCount = int((*animchar_render.sceneInstance).nodeCount)
  resize(animchar_render__nodeVisibleStgFilters, renderNodesCount)
  reset_all_nodes_filter(animchar_render__nodeVisibleStgFilters, animchar_render)

[es(tag=render, on_appear, after=nodes_filter_init, REQUIRE=cockpit__isAttached)]
def cockpit_nodes_filter_init(evt : Event;
                              animchar_render : AnimcharRendComponent;
                              var animchar_render__nodeVisibleStgFilters : UInt8List)
  reset_all_nodes_filter(animchar_render__nodeVisibleStgFilters, animchar_render,
                         uint8(int(~RenderPass RENDER_SHADOW)))

[es(tag=render, on_appear, before=disable_animchar_nodes_es)]
def cockpit_copy_disabled_parts(evt : Event; cockpit__vehicleEid : EntityId; var disableDMParts aka cockpit_disableDMParts : StringList&)
  query(cockpit__vehicleEid) <| $ [es] (disableDMParts aka parent_disableDMParts : StringList)
    cockpit_disableDMParts := parent_disableDMParts

[es(tag=render, on_disappear)]
def vehicle_cockpit_visible_nodes_destroy(evt : Event;
                                          cockpit__vehicleEid : EntityId)
  ecs::query(cockpit__vehicleEid) <| $ [es] (var animchar_render__nodeVisibleStgFilters : UInt8List;
                                             animchar_render : AnimcharRendComponent)
    reset_all_nodes_filter(animchar_render__nodeVisibleStgFilters, animchar_render)

[es(tag=render, track=cockpit__isAttached)]
def vehicle_cockpit_visible_nodes_init(evt : Event;
                                       cockpit__isAttached : bool;
                                       cockpit__vehicleEid : EntityId;
                                       cockpit__visibleVehicleNodeNames : StringList)
  ecs::query(cockpit__vehicleEid) <| $ [es] (animchar_render : AnimcharRendComponent;
                                             var animchar_render__nodeVisibleStgFilters : UInt8List)
    if cockpit__isAttached
      let nodesCount = length(cockpit__visibleVehicleNodeNames)
      reset_all_nodes_filter(animchar_render__nodeVisibleStgFilters, animchar_render,
                             uint8(int(RenderPass RENDER_SHADOW)))
      for i in range(0, nodesCount)
        let nodeName = string(cockpit__visibleVehicleNodeNames[i])
        let nodeId = ronamemapex_get_name_id((*(*animchar_render.sceneInstance).lodsResource).names.node, nodeName)
        if nodeId < 0
          logerr("Node '{nodeName}' from component cockpit.visibleVehicleNodeNames not found in vehicle {cockpit__vehicleEid} <{getEntityTemplateName(cockpit__vehicleEid)}>")
          continue
        if animchar_render.sceneInstance |> scene_instance_is_node_visible(nodeId)
          animchar_render__nodeVisibleStgFilters[nodeId] = uint8(~0)
    else
      reset_all_nodes_filter(animchar_render__nodeVisibleStgFilters, animchar_render)

[es(tag=render, on_event=NodesVisibilityWasUpdated, REQUIRE=(damage_part_alive, dmg_animchar__renderable))]
def damage_parts_update_filter(evt : Event;
                               animchar_render : AnimcharRendComponent;
                               var animchar_render__nodeVisibleStgFilters : UInt8List)
  filter_update_hidden(animchar_render__nodeVisibleStgFilters, animchar_render)

[es(tag=render, on_appear, REQUIRE_NOT=animchar_render__nodeVisibleStgFilters)]
def vehicle_cockpit_hide_parent_on_create(evt : Event;
                                          cockpit__vehicleEid : EntityId)
  query(cockpit__vehicleEid) <| $ [es(REQUIRE_NOT=animchar_render__nodeVisibleStgFilters)] (var animchar_render__enabled : bool&)
    animchar_render__enabled = false

[es(tag=render, on_disappear, REQUIRE_NOT=animchar_render__nodeVisibleStgFilters)]
def vehicle_cockpit_show_parent_on_destroy(evt : Event;
                                           cockpit__vehicleEid : EntityId)
  query(cockpit__vehicleEid) <| $ [es(REQUIRE_NOT=animchar_render__nodeVisibleStgFilters)] (var animchar_render__enabled : bool&)
    animchar_render__enabled = true

def cockpit_set_cut_parts(cockpit_eid : EntityId; cut_parts : BoolList)
  query(cockpit_eid) <| $ [es] (cockpit__partToAnimcharNodeMap : IntList;
                                var animchar_render : AnimcharRendComponent&)
    for partId, isPartCut in iter_range(cut_parts), cut_parts
      let nodeId = cockpit__partToAnimcharNodeMap?[partId] ?? -1
      if nodeId >= 0
        animchar_render.sceneInstance |> scene_instance_show_node(nodeId, !isPartCut)

[es(tag=render, on_appear, track=(cockpit__eid, plane_cutting__smallPartsCut))]
def plane_cockpit_cut_parts(evt : Event; cockpit__eid : EntityId; plane_cutting__smallPartsCut : BoolList)
  cockpit_set_cut_parts(cockpit__eid, plane_cutting__smallPartsCut)

[es(tag=render, on_appear, REQUIRE=vehicleWithWatched, track=(cockpit__eid, plane_cutting__cutting, plane_cutting__planes, plane_cutting__largePartsCut))]
def cockpit_copy_cut_planes(evt : Event;
                            cockpit__eid : EntityId;
                            plane_cutting__cutting aka parent_plane_cutting__cutting : bool;
                            plane_cutting__planes aka parent_plane_cutting__planes : Point4List;
                            plane_cutting__largePartsCut aka parent_plane_cutting__largePartsCut : BoolList)
  query(cockpit__eid) <| $ [es] (var plane_cutting__cutting : bool&;
                                 var plane_cutting__planes : Point4List&;
                                 var plane_cutting__largePartsCut : BoolList&)
    plane_cutting__cutting = parent_plane_cutting__cutting
    plane_cutting__planes := parent_plane_cutting__planes
    plane_cutting__largePartsCut := parent_plane_cutting__largePartsCut

[es(tag=render, on_appear)]
def vehicle_cockpit_on_attach_dm_parts_map_init(evt : Event;
                                                cockpit__vehicleEid : EntityId;
                                                animchar_render : AnimcharRendComponent;
                                                var cockpit__partToAnimcharNodeMap : IntList)
  query(cockpit__vehicleEid) <| $ [es] (damage_model : DamageModel)
    assume parts = damage_model.dmData.parts
    for part in parts
      let nodeNameDm = damagePart_getName(part)
      var nodeId = -1
      if nodeNameDm |> ends_with("_dm")
        let nodeName = chop(nodeNameDm, 0, length(nodeNameDm) - 3)
        nodeId = ronamemapex_get_name_id((*(*animchar_render.sceneInstance).lodsResource).names.node, nodeName)
      cockpit__partToAnimcharNodeMap |> push(nodeId)

def get_relative_to_slit_coords(pos : float3;
                                animchar : AnimcharBaseComponent;
                                cockpit__attachNodeIndices : IntList const?;
                                from_slit : int;
                                to_slit : int) : float3
  if cockpit__attachNodeIndices == null
    return pos
  let node_from = (*cockpit__attachNodeIndices)[from_slit]
  let node_to = (*cockpit__attachNodeIndices)[to_slit]
  var fromTm, toTm : float3x4
  geomtree_getNodeWtmScalar(*animchar.nodeTree, node_from, fromTm)
  fromTm[2] = -fromTm[2]
  geomtree_getNodeWtmScalar(*animchar.nodeTree, node_to, toTm)
  toTm[2] = -toTm[2]
  return inverse(toTm) * fromTm * pos

[es(tag=render, track=cockpit__nextSlit)]
def vehicle_cockpit_on_slit_change(evt : Event;
                                   cockpit__prevSlit : int;
                                   cockpit__nextSlit : int;
                                   cockpit__slitCameraDirs : Point3List;
                                   cockpit__slitCameraOffsets : Point3List;
                                   cockpit__attachNodeIndices : IntList const?;
                                   cockpit__minZoom : float;
                                   cockpit__seatNo : int;
                                   cockpit__vehicleEid : EntityId;
                                   var cockpit__cameraTime : float&;
                                   var cockpit__startCameraPos : float3&;
                                   var cockpit__endCameraPos : float3&)

  let prevCameraOffset = cockpit__slitCameraOffsets[cockpit__prevSlit]
  let prevCameraDir    = cockpit__slitCameraDirs[cockpit__prevSlit]
  let prevOffset       = prevCameraDir * cockpit__minZoom

  let cameraOffset = cockpit__slitCameraOffsets[cockpit__nextSlit]
  let cameraDir    = cockpit__slitCameraDirs[cockpit__nextSlit]
  let offset       = cameraDir * cockpit__minZoom

  var endPos = cameraOffset + offset
  query(cockpit__vehicleEid) <| $ [es] (animchar : AnimcharBaseComponent; vehicle_seats__seatEids : EidList)
    setOptional(vehicle_seats__seatEids[cockpit__seatNo], "seat__canControlTurrets", false)
    endPos[2] = -endPos[2]
    endPos = get_relative_to_slit_coords(endPos, animchar, cockpit__attachNodeIndices, cockpit__nextSlit, cockpit__prevSlit)
    endPos[2] = -endPos[2]

  cockpit__startCameraPos = prevCameraOffset + prevOffset
  cockpit__endCameraPos   = endPos
  cockpit__cameraTime     = 0.f

def init_transition(camera_dir : float3; cockpit_tm : float3x4; owner_eid : EntityId; var start_dir : float3&; var end_orient : float4&)
  query(owner_eid) <| $ [es] (human_input__aimAngle : float2)
    let endDir = rotate(cockpit_tm, camera_dir)
    start_dir = angles_to_dir(human_input__aimAngle)
    end_orient = float4(quat_rotation_arc(start_dir, endDir))

def init_cockpit_transition(cur_attach_tm : float3x4;
                            next_attach_tm : float3x4;
                            var out_orient_x : float4&;
                            var out_orient_y : float4&)
  out_orient_x = float4(quat_rotation_arc(cur_attach_tm[0], next_attach_tm[0]))
  out_orient_y = float4(quat_rotation_arc(cur_attach_tm[1], next_attach_tm[1]))

def get_cockpit_offset_for_slit(cockpit__offset : float3;
                                cockpit__cockpitOffsetBySlit : Point3List const?;
                                current_slit : int) : float3
  if cockpit__cockpitOffsetBySlit == null
    return cockpit__offset
  let currentPos = (*cockpit__cockpitOffsetBySlit)[current_slit]
  return cockpit__offset + currentPos

def get_cockpit_transition_offset(cockpit__offset : float3;
                                  animchar : AnimcharBaseComponent;
                                  cockpit__attachNodeIndices : IntList const?;
                                  cockpit__cockpitOffsetBySlit : Point3List const?;
                                  current_slit : int;
                                  next_slit : int;
                                  t : float) : float3
  let fromPos = get_cockpit_offset_for_slit(cockpit__offset, cockpit__cockpitOffsetBySlit, current_slit)
  var toPos = get_cockpit_offset_for_slit(cockpit__offset, cockpit__cockpitOffsetBySlit, next_slit)
  toPos = get_relative_to_slit_coords(toPos, animchar, cockpit__attachNodeIndices, next_slit, current_slit)
  return lerp(fromPos, toPos, float3(t))

def set_cockpit_transition_rotation(cockpit__endOrientX : float4;
                                    cockpit__endOrientY : float4;
                                    t : float;
                                    var in_out_tm : float3x4&)
  let cockpitQuatX = quat(normalize(lerp(quat_ident, cockpit__endOrientX, float4(t))))
  let cockpitQuatY = quat(normalize(lerp(quat_ident, cockpit__endOrientY, float4(t))))
  var x = cockpitQuatX * in_out_tm[0]
  let y = cockpitQuatY * in_out_tm[1]
  let z = cross(x, y)
  x = cross(y, z)
  in_out_tm[0] = x
  in_out_tm[1] = y
  in_out_tm[2] = z

[es(tag=render, after=(vehicle_cockpit_slits, vehicle_attach_cockpit_es), before=animchar_cam_target__with_offset_es)]
def vehicle_cockpit_slits_transition(info : UpdateStageInfoAct;
                                     cockpit__seatNo : int;
                                     cockpit__attachNodeIndex : int;
                                     cockpit__startCameraPos : float3;
                                     cockpit__endCameraPos : float3;
                                     cockpit__vehicleEid : EntityId;
                                     cockpit__nextSlit : int;
                                     cockpit__slitCameraDirs : Point3List;
                                     cockpit__cockpitOffsetBySlit : Point3List const?;
                                     cockpit__attachNodeIndices : IntList const?;
                                     cockpit__offset : float3;
                                     var transform : float3x4;
                                     var cockpit__startCameraDir : float3&;
                                     var cockpit__endCameraOrient : float4&;
                                     var cockpit__endOrientX : float4&;
                                     var cockpit__endOrientY : float4&;
                                     var cockpit__currentSlit : int&;
                                     var cockpit__zoomTime : float&;
                                     var cockpit__cameraTime : float&;
                                     cockpit__zoomTimeMul = 1.f;
                                     cockpit__cameraTimeMul = 1.f)
  let inTransition = cockpit__cameraTime < 1.f

  let wasInZoom = cockpit__zoomTime > 0.f
  cockpit__zoomTime = saturate(cockpit__zoomTime + (inTransition ? -info.dt : info.dt) * cockpit__zoomTimeMul)

  let inZoom = cockpit__zoomTime > 0.f
  if inZoom
    return

  if !inTransition
    return

  cockpit__cameraTime += info.dt * cockpit__cameraTimeMul

  ecs::query(cockpit__vehicleEid) <| $ [es] (animchar : AnimcharBaseComponent; vehicle_seats__seatEids : EidList; var animchar_camera_target__node_offset : float3&; var cockpit__cameraDir : float3&)
    geomtree_getNodeWtmScalar(*animchar.nodeTree, cockpit__attachNodeIndex, transform)

    if wasInZoom
      let cameraDir = cockpit__slitCameraDirs[cockpit__nextSlit]
      var nextAttachTm : float3x4
      if cockpit__attachNodeIndices != null
        geomtree_getNodeWtmScalar(*animchar.nodeTree, (*cockpit__attachNodeIndices)[cockpit__nextSlit], nextAttachTm)
        init_cockpit_transition(transform, nextAttachTm, cockpit__endOrientX, cockpit__endOrientY)
      let cockpitTm = cockpit__attachNodeIndices != null ? nextAttachTm : transform
      let seatEid = vehicle_seats__seatEids[cockpit__seatNo]
      let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
      init_transition(cameraDir, cockpitTm, ownerEid,
                      cockpit__startCameraDir, cockpit__endCameraOrient)

    let t = saturate(inOutSine(cockpit__cameraTime))
    let q = quat(normalize(lerp(quat_ident, cockpit__endCameraOrient, float4(t))))
    cockpit__cameraDir = q * cockpit__startCameraDir
    animchar_camera_target__node_offset = lerp(cockpit__startCameraPos, cockpit__endCameraPos, float3(t))

    transform[2] = -transform[2]
    transform[3] = transform * get_cockpit_transition_offset(cockpit__offset, animchar, cockpit__attachNodeIndices, cockpit__cockpitOffsetBySlit,
                                                             cockpit__currentSlit, cockpit__nextSlit, t)
    if cockpit__attachNodeIndices != null
      set_cockpit_transition_rotation(cockpit__endOrientX, cockpit__endOrientY, t, transform)

    let seatEid = vehicle_seats__seatEids[cockpit__seatNo]
    let humanInCockpitEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    query(humanInCockpitEid) <| $ [es] (var human_input__aimAngle : float2&)
      human_input__aimAngle = dir_to_angles(cockpit__cameraDir)

  if cockpit__cameraTime >= 1.0f
    cockpit__currentSlit = cockpit__nextSlit

[es(tag=render, REQUIRE=cockpit__vehicleEid, after=(after_animchar_update_sync, vehicle_attach_cockpit_es, vehicle_cockpit_slits_transition))]
def vehicle_cockpit_update_animchar(info : UpdateStageInfoAct;
                                    transform : float3x4;
                                    var animchar : AnimcharBaseComponent;
                                    var animchar_node_wtm : AnimcharNodesMat44;
                                    var animchar_render__root_pos : vec4f&)
  animchar_set_tm(animchar, transform, true)
  animchar_act(animchar, info.dt, true)
  animchar_copy_nodes(animchar, animchar_node_wtm, animchar_render__root_pos)

[es(tag=render, after=(animchar_es, vehicle_attach_cockpit_es), before=animchar_cam_target__with_offset_es)]
def vehicle_cockpit_slits(info : UpdateStageInfoAct;
                          cockpit__isAttached : bool;
                          cockpit__zoomTime : float;
                          cockpit__minZoom : float;
                          cockpit__attachNodeIndex : int;
                          cockpit__vehicleEid : EntityId;
                          cockpit__currentSlit : int;
                          cockpit__slitNodes : IntList;
                          cockpit__slitForwardOffset : FloatList;
                          cockpit__slitCameraOffsets : Point3List;
                          cockpit__slitCameraDirs : Point3List;
                          var cockpit__zoom : float&)
  if !cockpit__isAttached || cockpit__currentSlit >= length(cockpit__slitNodes)
    return

  let nodeId = cockpit__slitNodes[cockpit__currentSlit]
  if nodeId < 0
    return

  let t = inOutSine(cockpit__zoomTime)
  let zoom = lerp(cockpit__minZoom, cockpit__slitForwardOffset[cockpit__currentSlit], t)
  cockpit__zoom = zoom

  let cameraOffset = cockpit__slitCameraOffsets[cockpit__currentSlit]
  let cameraDir    = cockpit__slitCameraDirs[cockpit__currentSlit]
  let offset       = cameraDir * zoom

  ecs::query(cockpit__vehicleEid) <| $ [es] (animchar : AnimcharBaseComponent;
                                             var vehicle_sight__opacity : float&;
                                             var animchar_camera_target__node_offset : float3&;
                                             var animchar_camera_target__nodeIndex : int&;
                                             var cockpit__cameraDir : float3&)
    animchar_camera_target__nodeIndex = cockpit__attachNodeIndex
    animchar_camera_target__node_offset = cameraOffset + offset

    var cockpitTm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, cockpit__attachNodeIndex, cockpitTm)

    cockpit__cameraDir = rotate(cockpitTm, cameraDir)

    vehicle_sight__opacity = inQuintic(cockpit__zoomTime)


[es(tag=render, after=(animchar_es, vehicle_attach_cockpit_es), before=vehicle_cockpit_slits)]
def vehicle_cockpit_camera_dir(info : UpdateStageInfoAct;
                               cockpit__isAttached : bool;
                               cockpit__attachNodeIndex : int;
                               cockpit__vehicleEid : EntityId)
  if !cockpit__isAttached
    return

  query(cockpit__vehicleEid) <| $ [es] (animchar : AnimcharBaseComponent;
                                        var cockpit__cameraDir : float3&)

    var cockpitTm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, cockpit__attachNodeIndex, cockpitTm)

    cockpit__cameraDir = cockpitTm[0]

def set_cockpit_eid_to_vehicle_impl(eid, cockpit__vehicleEid : EntityId)
  ecs::query(cockpit__vehicleEid) <| $ [es] (var cockpit__eid : EntityId&)
    cockpit__eid = eid

[es(tag=gameClient, on_appear)]
def set_cockpit_eid_to_vehicle(evt : Event; eid, cockpit__vehicleEid : EntityId)
  set_cockpit_eid_to_vehicle_impl(eid, cockpit__vehicleEid)

[es(tag=gameClient, on_event=EventEntityDestroyed)]
def reset_cockpit_eid_to_vehicle(evt : Event; cockpit__vehicleEid : EntityId)
  set_cockpit_eid_to_vehicle_impl(INVALID_ENTITY_ID, cockpit__vehicleEid)


[es(tag=render, on_appear, before=init_decals_es)]
def set_decals_to_cockpit(evt : Event;
                          cockpit__vehicleEid : EntityId;
                          var animcharDecalsData aka cockpit_animcharDecalsData : Array&)
  query(cockpit__vehicleEid) <| $ [es] (animcharDecalsData : Array)
    cockpit_animcharDecalsData := animcharDecalsData
