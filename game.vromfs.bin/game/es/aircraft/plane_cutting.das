require ecs
require ecs.common
require math.base
require DagorMath
require DagorRandom
require game.es.events
require dm
require AnimV20
require CollRes
require EnlistedPlane
require Plane
require strings
require DagorSystem
require GeomNodeTree
require DagorDataBlock
require daslib/enum_trait
require game.es.aircraft.plane_cutting_common


let WRECKAGE_NODE_NAMES = [[auto[]
  "wing_l";
  "wing_r";
  "tail";
  "tail";
  "tail";
  "tail"
]]

let WRECKAGE_TYPE_NAMES = [[auto[]
  "wing_l";
  "wing_r";
  "tail";
  "stab_l";
  "stab_r";
  "fin"
]]

let WRECKAGE_CUT_PART_NAMES = [[auto[]
  "wing_l_dm";
  "wing1_l_dm";
  "wing2_l_dm";

  "wing_r_dm";
  "wing1_r_dm";
  "wing2_r_dm";

  "tail_dm";
  "fin_dm";
  "stab_dm";
  "stab1_dm";
  "stab2_dm"
]]

[es(tag=server)]
def plane_cutting_on_repair(evt : EventOnRepaired;
                            var plane_cutting__leftWingCutState : int&;
                            var plane_cutting__rightWingCutState : int&;
                            var plane_cutting__largePartsCut : BoolList&;
                            var plane_cutting__smallPartsCut : BoolList&)
  plane_cutting__leftWingCutState = int(FlightModelCutState FMCS_NONE)
  plane_cutting__rightWingCutState = int(FlightModelCutState FMCS_NONE)
  for val in plane_cutting__largePartsCut
    val = false
  for val in plane_cutting__smallPartsCut
    val = false

[es(tag=server, on_appear)]
def plane_cutting_init(evt : Event;
                       damage_model : DamageModel;
                       plane_cutting__cuttingPlanes : Point4List;
                       var plane_cutting__largePartsCut : BoolList&;
                       var plane_cutting__cuttingPlanesW : FloatList&;
                       var plane_cutting__smallPartsCut : BoolList&)
  plane_cutting__largePartsCut |> clear()
  for _i in each_enum(WreckageType WRECKAGE_WING_L)
    plane_cutting__largePartsCut |> push(false)

  plane_cutting__cuttingPlanesW |> resize(length(plane_cutting__cuttingPlanes))
  for w, plane in plane_cutting__cuttingPlanesW, plane_cutting__cuttingPlanes
    w = plane.w

  plane_cutting__smallPartsCut |> resize(length(damage_model.dmData.parts))
  for val in plane_cutting__smallPartsCut
    val = false

[es(tag=server)]
def plane_damage_cutting(evt : EventCutPart;
                         plane_cutting__cutPartsId : IntList;
                         plane_cutting__stabLeftCuttingPos : float2;
                         plane_cutting__stabRightCuttingPos : float2;
                         plane_cutting__finCuttingPos : float2;
                         plane_cutting__tailCuttingPos : float2;
                         plane_cutting__wingLeftCuttingPos : Point2List;
                         plane_cutting__wingRightCuttingPos : Point2List;
                         var plane_cutting__cuttingPlanes : Point4List&;
                         var plane_cutting__leftWingCutState : int&;
                         var plane_cutting__rightWingCutState : int&;
                         var plane_cutting__cutting : bool&;
                         var plane_cutting__largePartsCut : BoolList&;
                         var plane_cutting__cuttingPlanesW : FloatList&;
                         var plane_cutting__smallPartsCut : BoolList&)
  let partId = evt.partNo
  let cutPartId = find_index(plane_cutting__cutPartsId, partId)

  var wreckageNo = -1
  if cutPartId == int(WreckageCutPartId WRECK_PART_PART_WING_L) || cutPartId == int(WreckageCutPartId WRECK_PART_PART_WING1_L) || cutPartId == int(WreckageCutPartId WRECK_PART_PART_WING2_L)
    let cutState = int(FlightModelCutState FMCS_ALL_CUT) - cutPartId + int(WreckageCutPartId WRECK_PART_PART_WING_L)
    if cutState < plane_cutting__leftWingCutState
      return

    wreckageNo = int(WreckageType WRECKAGE_WING_L)

    plane_cutting__largePartsCut[int(WreckageType WRECKAGE_WING_L)] = true
    plane_cutting__leftWingCutState = cutState

    assume leftWingCuttingPos = plane_cutting__wingLeftCuttingPos[plane_cutting__leftWingCutState - 1]
    plane_cutting__cuttingPlanes[wreckageNo].w = lerp(leftWingCuttingPos.x, leftWingCuttingPos.y, 0.5)
  elif cutPartId == int(WreckageCutPartId WRECK_PART_PART_WING_R) || cutPartId == int(WreckageCutPartId WRECK_PART_PART_WING1_R) || cutPartId == int(WreckageCutPartId WRECK_PART_PART_WING2_R)
    let cutState = int(FlightModelCutState FMCS_ALL_CUT) - cutPartId + int(WreckageCutPartId WRECK_PART_PART_WING_R)
    if cutState < plane_cutting__rightWingCutState
      return

    wreckageNo = int(WreckageType WRECKAGE_WING_R)

    plane_cutting__largePartsCut[int(WreckageType WRECKAGE_WING_R)] = true
    plane_cutting__rightWingCutState = cutState

    assume rightWingCuttingPos = plane_cutting__wingRightCuttingPos[plane_cutting__rightWingCutState - 1]
    plane_cutting__cuttingPlanes[wreckageNo].w = lerp(rightWingCuttingPos.x, rightWingCuttingPos.y, 0.5)
  elif cutPartId == int(WreckageCutPartId WRECK_PART_PART_TAIL)
    wreckageNo = int(WreckageType WRECKAGE_TAIL)

    plane_cutting__largePartsCut[int(WreckageType WRECKAGE_TAIL)] = true
    plane_cutting__cuttingPlanes[wreckageNo].w = lerp(plane_cutting__tailCuttingPos.x, plane_cutting__tailCuttingPos.y, 0.5)
  elif cutPartId == int(WreckageCutPartId WRECK_PART_PART_FIN)
    if plane_cutting__largePartsCut[int(WreckageType WRECKAGE_TAIL)]
      return

    wreckageNo = int(WreckageType WRECKAGE_FIN)

    plane_cutting__largePartsCut[int(WreckageType WRECKAGE_FIN)] = true
    plane_cutting__cuttingPlanes[wreckageNo].w = lerp(plane_cutting__finCuttingPos.x, plane_cutting__finCuttingPos.y, 0.5)
  elif cutPartId == int(WreckageCutPartId WRECK_PART_PART_STAB) || cutPartId == int(WreckageCutPartId WRECK_PART_PART_STAB_1) || cutPartId == int(WreckageCutPartId WRECK_PART_PART_STAB_2)
    if plane_cutting__largePartsCut[int(WreckageType WRECKAGE_TAIL)]
      return

    wreckageNo = int(WreckageType WRECKAGE_STAB_L)

    if cutPartId == int(WreckageCutPartId WRECK_PART_PART_STAB)
      plane_cutting__largePartsCut[int(WreckageType WRECKAGE_STAB_L)] = true
      plane_cutting__largePartsCut[int(WreckageType WRECKAGE_STAB_R)] = true
      plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_STAB_L)].w = lerp(plane_cutting__stabLeftCuttingPos.x, plane_cutting__stabLeftCuttingPos.y, 0.5)
      plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_STAB_R)].w = lerp(plane_cutting__stabRightCuttingPos.x, plane_cutting__stabRightCuttingPos.y, 0.5)
    elif cutPartId == int(WreckageCutPartId WRECK_PART_PART_STAB_1)
      plane_cutting__largePartsCut[int(WreckageType WRECKAGE_STAB_L)] = true
      plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_STAB_L)].w = lerp(plane_cutting__stabLeftCuttingPos.x, plane_cutting__stabLeftCuttingPos.y, 0.5)
    elif cutPartId == int(WreckageCutPartId WRECK_PART_PART_STAB_2)
      plane_cutting__largePartsCut[int(WreckageType WRECKAGE_STAB_R)] = true
      plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_STAB_R)].w = lerp(plane_cutting__stabRightCuttingPos.x, plane_cutting__stabRightCuttingPos.y, 0.5)
  else
    plane_cutting__smallPartsCut[partId] = true


  if wreckageNo >= 0
    plane_cutting__cutting = true

    plane_cutting__cuttingPlanesW |> resize(length(plane_cutting__cuttingPlanes))
    for w, plane in plane_cutting__cuttingPlanesW, plane_cutting__cuttingPlanes
      w = plane.w

[es(tag=gameClient, before=additional_data_for_plane_cutting_es)]
def plane_damage_update_cutting_plane_offset(info : UpdateStageInfoAct;
                                             plane_cutting__cuttingPlanesW : FloatList;
                                             var plane_cutting__cuttingPlanes : Point4List&)
  for plane, w in plane_cutting__cuttingPlanes, plane_cutting__cuttingPlanesW
    plane.w = w

def create_wreckage_entity(template_name : string;
                           eid : EntityId;
                           node_name : string;
                           type_name : string;
                           plane_net_phys : PlaneActor;
                           offset : float3;
                           transform : float3x4)
  let orient = quat(transform)

  let arm = offset
  let vel = float3(plane_net_phys.phys.currentState.velocity)
  let omega = float3(plane_net_phys.phys.currentState.omega)
  let partVel = vel + cross(omega, arm)

  var tmVel : float3x4
  tmVel[0] = normalize_default(partVel, float3(1, 0, 0))
  tmVel[1] = transform[1]
  tmVel[2] = normalize(cross(tmVel[0], tmVel[1]))
  tmVel[1] = cross(tmVel[2], tmVel[0])

  let impulseCoeffsFrom = float3(-0.03, -0.05, -0.05)
  let impulseCoeffsTo = float3(-0.15, 0.05, 0.05)

  let impulseCoeffs = float3(
    lerp(impulseCoeffsFrom.x, impulseCoeffsTo.x, gfrnd()),
    lerp(impulseCoeffsFrom.y, impulseCoeffsTo.y, gfrnd()),
    lerp(impulseCoeffsFrom.z, impulseCoeffsTo.z, gfrnd())
  )

  let impulse = plane_net_phys.phys.V2 * rotate(tmVel, impulseCoeffs)
  let momentCoeff = 0.1 * (0.2 + 0.8 * gfrnd())
  let moment = momentCoeff * cross(impulse, arm)

  createEntity(template_name) <| $(var init)
    init |> set("transform", transform)
    init |> set("plane_wreckage__nodeName", node_name)
    init |> set("plane_wreckage__typeName", type_name)
    init |> set("plane_wreckage__owner", eid)
    init |> set("plane_wreckage__pos", transform[3] - rotate(transform, offset))
    init |> set("plane_wreckage__offset", offset)
    init |> set("plane_wreckage__orient", float4(orient))
    init |> set("plane_wreckage__startImpulse", impulse)
    init |> set("plane_wreckage__startMoment", moment)
    init |> set("plane_wreckage__vel", partVel)
    init |> set("plane_wreckage__omega", omega)

def update_large_wrecked_part(wreckage_type : int;
                              cut : bool;
                              eid : EntityId;
                              transform : float3x4;
                              plane_net_phys : PlaneActor;
                              plane_cutting__cuttingPlanes;
                              plane_wreckage__template : string;
                              var plane_wreckage__createdLarge : BoolList&)
  if plane_wreckage__createdLarge[wreckage_type] == cut
    return

  if cut
    assume cuttingPlane = plane_cutting__cuttingPlanes[wreckage_type]
    let offset = cuttingPlane.w * cuttingPlane.xyz

    create_wreckage_entity(plane_wreckage__template, eid, WRECKAGE_NODE_NAMES[wreckage_type],
                           WRECKAGE_TYPE_NAMES[wreckage_type], plane_net_phys, offset, transform)

  plane_wreckage__createdLarge[wreckage_type] = cut

def update_small_wrecked_part(part_id : int;
                              cut : bool;
                              eid : EntityId;
                              transform : float3x4;
                              plane_net_phys : PlaneActor;
                              damage_model : DamageModel;
                              collres : CollisionResource;
                              plane_wreckage__template : string;
                              var animchar_render : AnimcharRendComponent&;
                              var plane_wreckage__createdSmall : BoolList&)
  if plane_wreckage__createdSmall[part_id] == cut
    return

  let collisionNodeId = damage_model.dmData.parts[part_id].collisionNodeId
  let node = collres_get_node(collres, collisionNodeId)
  if node != null
    let nodeNameDm = node |> collnode_get_name()
    let nodeName = ends_with(nodeNameDm, "_dm") ? chop(nodeNameDm, 0, length(nodeNameDm) - 3) : nodeNameDm

    assume sceneInstance = animchar_render.sceneInstance
    let nodeId = *sceneInstance |> scene_instance_getNodeId(nodeName)
    if nodeId >= 0
      if (cut)
        *sceneInstance |> scene_instance_setNodeOpacity(uint(nodeId), 0.0)
        sceneInstance |> scene_instance_show_node(nodeId, false)

        assume templateName = plane_wreckage__template

        create_wreckage_entity(templateName, eid, nodeName, nodeName, plane_net_phys, node.tm[3], transform)
      else
        *sceneInstance |> scene_instance_setNodeOpacity(uint(nodeId), 1.0)
        sceneInstance |> scene_instance_show_node(nodeId, true)

  plane_wreckage__createdSmall[part_id] = cut

[es(tag=gameClient, no_order)]
def plane_damage_cutting_draw_es(info : UpdateStageInfoAct;
                                 eid : EntityId;
                                 plane_wreckage__template : string;
                                 transform : float3x4;
                                 plane_net_phys : PlaneActor;
                                 damage_model : DamageModel;
                                 collres : CollisionResource;
                                 plane_cutting__cuttingPlanes : Point4List;
                                 plane_cutting__largePartsCut : BoolList;
                                 plane_cutting__smallPartsCut : BoolList;
                                 var animchar_render : AnimcharRendComponent&;
                                 var plane_wreckage__createdLarge : BoolList&;
                                 var plane_wreckage__createdSmall : BoolList&)
  for wreckageType in each_enum(WreckageType WRECKAGE_WING_L)
    update_large_wrecked_part(int(wreckageType), plane_cutting__largePartsCut[int(wreckageType)], eid, transform, plane_net_phys,
                              plane_cutting__cuttingPlanes, plane_wreckage__template, plane_wreckage__createdLarge)

  for partId in iter_range(plane_cutting__smallPartsCut)
    update_small_wrecked_part(partId, plane_cutting__smallPartsCut[partId], eid, transform, plane_net_phys,
                              damage_model, collres, plane_wreckage__template, animchar_render, plane_wreckage__createdSmall)

[es(on_appear)]
def plane_damage_cutting_common_es(evt : Event;
                                   damage_model : DamageModel;
                                   var plane_wreckage__createdLarge : BoolList&;
                                   var plane_wreckage__createdSmall : BoolList&)
  plane_wreckage__createdLarge |> clear()
  for _i in each_enum(WreckageType WRECKAGE_WING_L)
    plane_wreckage__createdLarge |> push(false)

  plane_wreckage__createdSmall |> clear()
  for _i in iter_range(damage_model.dmData.parts)
    plane_wreckage__createdSmall |> push(false)

[es(on_appear)]
def plane_damage_initial_cutting_es(evt : Event;
                                    plane_cutting__wingLeftCuttingPos : Point2List;
                                    plane_cutting__wingRightCuttingPos : Point2List;
                                    plane_cutting__tailCuttingPos : float2;
                                    plane_cutting__initialCutType : int;
                                    plane_cutting__initialCut : float;
                                    plane_cutting__leftWingCutState : int;
                                    plane_cutting__rightWingCutState : int;
                                    var plane_cutting__cuttingPlanes : Point4List&)
  if plane_cutting__initialCutType == int(WreckageType WRECKAGE_WING_L)
    let leftWingCuttingPos = plane_cutting__wingLeftCuttingPos[plane_cutting__leftWingCutState - 1]
    plane_cutting__cuttingPlanes[plane_cutting__initialCutType].w = lerp(leftWingCuttingPos.x, leftWingCuttingPos.y, plane_cutting__initialCut)
  elif plane_cutting__initialCutType == int(WreckageType WRECKAGE_WING_R)
    let rightWingCuttingPos = plane_cutting__wingRightCuttingPos[plane_cutting__rightWingCutState - 1]
    plane_cutting__cuttingPlanes[plane_cutting__initialCutType].w = lerp(rightWingCuttingPos.x, rightWingCuttingPos.y, plane_cutting__initialCut)
  elif plane_cutting__initialCutType == int(WreckageType WRECKAGE_TAIL)
    plane_cutting__cuttingPlanes[plane_cutting__initialCutType].w = lerp(plane_cutting__tailCuttingPos.x, plane_cutting__tailCuttingPos.y, plane_cutting__initialCut)

[es(tag=gameClient, on_appear)]
def plane_wreckage_tm_init_es(evt : Event;
                              plane_wreckage__nodeName : string;
                              animchar : AnimcharBaseComponent;
                              var plane_wreckage__tm : float3x4&)
  assume geom = *animchar.nodeTree

  var rootTm : float3x4
  geom |> geomtree_getNodeWtmRelScalar(0, rootTm)
  rootTm = inverse(rootTm)

  let nodeNo = geom |> geomtree_findNodeIndex(plane_wreckage__nodeName)
  if nodeNo < 0
    logerr("[wreckage]: Node '{plane_wreckage__nodeName}' not found")
    return

  geom |> geomtree_getNodeWtmRelScalar(nodeNo, plane_wreckage__tm)
  plane_wreckage__tm = rootTm * plane_wreckage__tm

[es(on_appear)]
def init_plane_wreckage_part_type_id(evt : Event;
                                     plane_wreckage__typeName : string;
                                     plane_wreckage__nodeName : string;
                                     var animchar_render : AnimcharRendComponent&;
                                     var plane_wreckage__typeId : int&)
  plane_wreckage__typeId = find_index(WRECKAGE_TYPE_NAMES, plane_wreckage__typeName)

  assume sceneInstance = animchar_render.sceneInstance
  let nodeId = scene_instance_getNodeId(*sceneInstance, plane_wreckage__nodeName)

  for id in(*(*sceneInstance).lodsResource).names.node.id
    *sceneInstance |> scene_instance_setNodeOpacity(uint(id), 0.0)
    sceneInstance |> scene_instance_show_node(int(id), false)

  *sceneInstance |> scene_instance_setNodeOpacity(uint(nodeId), 1.0)
  sceneInstance |> scene_instance_show_node(nodeId, true)

def find_model_root_cutting_point(geom : GeomNodeTree; name : string; var out_point : float3&)
  let nodeIndex = geom |> geomtree_findNodeIndex(name)
  if nodeIndex >= 0
    var rootTm = IDENT_TM
    geom |> geomtree_getNodeWtmRelScalar(0, rootTm)
    rootTm = inverse(rootTm)
    out_point = rootTm * geomtree_getNodeWposRel(geom, nodeIndex)
    return true
  out_point = float3()
  return false

def find_blk_cutting_point(blk : DataBlock; name : string; var out_point : float3&)
  let paramNum = blk |> datablock_find_param(name)
  if paramNum >= 0
    let paramType = blk |> datablock_getParamType(uint(paramNum))
    if paramType == int(DataBlockParamType TYPE_MATRIX)
      out_point = datablock_getTm(blk, paramNum)[3]
      return true
    elif paramType == int(DataBlockParamType TYPE_POINT3)
      out_point = blk |> datablock_getPoint3(paramNum)
      return true
    else
      logerr("emitter {name} in blk has incorrect type = {paramType}")
  out_point = float3()
  return false

def find_root_cutting_point(geom : GeomNodeTree; name : string; blk : DataBlock?; var out_point : float3&)
  if find_model_root_cutting_point(geom, name, out_point)
    return true
  elif blk != null
    return find_blk_cutting_point(*blk, name, out_point)
  out_point = float3()
  return false

[es(on_appear, after=plane_cutting_planes_init_es)]
def init_plane_cutting(evt : Event;
                       animchar : AnimcharBaseComponent;
                       damage_model : DamageModel;
                       plane_phys_damage__blk : string;
                       var plane_cutting__tailCuttingPos : float2&;
                       var plane_cutting__finCuttingPos : float2&;
                       var plane_cutting__wingLeftCuttingPos : Point2List&;
                       var plane_cutting__wingRightCuttingPos : Point2List&;
                       var plane_cutting__wingBiplaneCuttingPlane : float4&;
                       var plane_cutting__wingLowerCuttingPlane : float4&;
                       var plane_cutting__cuttingPlanes : Point4List&;
                       var plane_cutting__wingRearCuttingPlane : float4&;
                       var plane_cutting__wingUpperCuttingPlane : float4&;
                       var plane_cutting__finsFrontCuttingPlane : float4&;
                       var plane_cutting__stabLeftCuttingPos : float2&;
                       var plane_cutting__stabRightCuttingPos : float2&;
                       var plane_cutting__cutPartsId : IntList)
  plane_cutting__cuttingPlanes |> clear()
  for _i in each_enum(WreckageType WRECKAGE_WING_L)
    plane_cutting__cuttingPlanes |> emplace(float4())

  plane_cutting__wingLeftCuttingPos |> clear()
  plane_cutting__wingRightCuttingPos |> clear()
  for _i in each_enum(FlightModelCutState FMCS_NONE)
    plane_cutting__wingLeftCuttingPos |> emplace(float2())
    plane_cutting__wingRightCuttingPos |> emplace(float2())

  let partsSize = typeinfo(enum_length type<WreckageCutPartId>)
  if partsSize != length(WRECKAGE_CUT_PART_NAMES)
    logerr("plane cutting: WRECKAGE_CUT_PART_NAMES and WreckageCutPartId have different size")
  let wreckageTypeCount = typeinfo(enum_length type<WreckageType>)
  if length(WRECKAGE_NODE_NAMES) != wreckageTypeCount
    logerr("plane cutting: WRECKAGE_NODE_NAMES and WreckageType have different size")
  if length(WRECKAGE_TYPE_NAMES) != wreckageTypeCount
    logerr("plane cutting: WRECKAGE_TYPE_NAMES and WreckageType have different size")

  plane_cutting__cutPartsId |> resize(partsSize)
  for cutPartId, partName in plane_cutting__cutPartsId, WRECKAGE_CUT_PART_NAMES
    cutPartId = damage_model |> find_part_id_by_name(partName)

  plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_WING_L)] = float4(0, 0, 0, 1)
  plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_WING_R)] = float4(0, 0, 0, 1)
  plane_cutting__wingRearCuttingPlane = float4(0, 0, 0, -1)
  plane_cutting__wingUpperCuttingPlane = float4(0, 0, 0, -1)

  using() <| $(var planeBlk : DataBlock)
    if !datablock_load(planeBlk, plane_phys_damage__blk)
      return

    assume geom = *animchar.nodeTree

    let cuttingBlk = planeBlk |> datablock_get_block_by_name("cutting")

    for s in range(2)
      let side = s == 0 ? "l" : "r"
      let dir = s == 0 ? float3(0, 0, 1) : float3(0, 0, -1)

      assume wingCuttingPos = s == 0 ? plane_cutting__wingLeftCuttingPos : plane_cutting__wingRightCuttingPos

      plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_WING_L) + s] = float4(0, 0, 0, 1)
      var directionIsFound = false

      var wingCutFromPoint : float3
      var wingCutToPoint : float3

      let wingFromCutPointPresents = find_root_cutting_point(geom, "emtr_break_wing0_{side}_from", cuttingBlk, wingCutFromPoint)
      let wingToCutPointPresents = find_root_cutting_point(geom, "emtr_break_wing0_{side}_to", cuttingBlk, wingCutToPoint)

      if wingFromCutPointPresents && wingToCutPointPresents
        plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_WING_L) + s] = float4(-normalize(wingCutToPoint - wingCutFromPoint), 0.0)
        directionIsFound = true
        wingCuttingPos[int(FlightModelCutState FMCS_ALL_CUT) - 1] = float2(dot(dir, wingCutFromPoint), dot(dir, wingCutToPoint))

      var wing1CutFromPoint : float3
      var wing1CutToPoint : float3
      let wing1FromCutPointPresents = find_root_cutting_point(geom, "emtr_break_wing1_{side}_from", cuttingBlk, wing1CutFromPoint)
      let wing1ToCutPointPresents = find_root_cutting_point(geom, "emtr_break_wing1_{side}_to", cuttingBlk, wing1CutToPoint)

      if wing1FromCutPointPresents && wing1ToCutPointPresents
        plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_WING_L) + s] = float4(-normalize(wing1CutToPoint - wing1CutFromPoint), 0.0)
        directionIsFound = true
        wingCuttingPos[int(FlightModelCutState FMCS_MID_CUT) - 1] = float2(dot(dir, wing1CutFromPoint), dot(dir, wing1CutToPoint))

      var wing2CutFromPoint : float3
      var wing2CutToPoint : float3
      let wing2FromCutPointPresents = find_root_cutting_point(geom, "emtr_break_wing2_{side}_from", cuttingBlk, wing2CutFromPoint)
      let wing2ToCutPointPresents = find_root_cutting_point(geom, "emtr_break_wing2_{side}_to", cuttingBlk, wing2CutToPoint)
      if wing2FromCutPointPresents && wing2ToCutPointPresents
        plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_WING_L) + s] = float4(-normalize(wing2CutToPoint - wing2CutFromPoint), 0.0)
        directionIsFound = true
        wingCuttingPos[int(FlightModelCutState FMCS_SMALL_CUT) - 1] = float2(dot(dir, wing2CutFromPoint), dot(dir, wing2CutToPoint))

    var wingRearCutPoint : float3
    if find_root_cutting_point(geom, "emtr_break_wing_tail", cuttingBlk, wingRearCutPoint)
      let wingCutDir = normalize(wingRearCutPoint)
      plane_cutting__wingRearCuttingPlane = float4(wingCutDir, -abs(dot(float3(-1, 0, 0), wingRearCutPoint)))
      plane_cutting__finsFrontCuttingPlane = float4(-wingCutDir, abs(dot(float3(1, 0, 0), wingRearCutPoint)))
    else
      plane_cutting__wingRearCuttingPlane = float4(0, 0, 0, -1)
      plane_cutting__finsFrontCuttingPlane = float4(0, 0, 0, -1)

    var wingBiplaneCutPoint : float3
    if find_root_cutting_point(geom, "emtr_break_wing_biplane", cuttingBlk, wingBiplaneCutPoint)
      plane_cutting__wingBiplaneCuttingPlane = float4(0.0, -1.0, 0.0, -abs(wingBiplaneCutPoint.y))

    var wingLowerCutPoint : float3
    if find_root_cutting_point(geom, "emtr_break_wing_lower", cuttingBlk, wingLowerCutPoint)
      plane_cutting__wingLowerCuttingPlane = float4(0.0, -1.0, 0.0, -abs(wingLowerCutPoint.y))

    var wingUpperCutPoint : float3
    if find_root_cutting_point(geom, "emtr_break_wing_upper", cuttingBlk, wingUpperCutPoint)
      let wingUpperCuttingLen = length(wingUpperCutPoint)
      let wingUpperCuttingDir = wingUpperCutPoint / max(wingUpperCuttingLen, 0.001)
      plane_cutting__wingUpperCuttingPlane = float4(wingUpperCuttingDir, -wingUpperCuttingLen)

    var tailWreckedId = int(WreckageType WRECKAGE_TAIL)
    if cuttingBlk != null && cuttingBlk |> datablock_getBool("finCut", false)
      tailWreckedId = int(WreckageType WRECKAGE_FIN)

    assume tailFinCuttingPos = tailWreckedId == int(WreckageType WRECKAGE_TAIL) ? plane_cutting__tailCuttingPos : plane_cutting__finCuttingPos
    var tailFinCutFrom : float3
    var tailFinCutTo : float3
    if find_model_root_cutting_point(geom, "emtr_break_tail_from", tailFinCutFrom) && find_model_root_cutting_point(geom, "emtr_break_tail_to", tailFinCutTo)
      let tailFinCutNorm = normalize(tailFinCutFrom - tailFinCutTo)
      plane_cutting__cuttingPlanes[tailWreckedId] = float4(tailFinCutNorm.x, tailFinCutNorm.y, tailFinCutNorm.z, 0.0)
      tailFinCuttingPos = float2(dot(-tailFinCutFrom, tailFinCutNorm), dot(-tailFinCutTo, tailFinCutNorm))
    else
      plane_cutting__cuttingPlanes[tailWreckedId] = float4(0, 0, 0, 1)
      tailFinCuttingPos = float2(1, 1)

    if tailWreckedId != int(WreckageType WRECKAGE_TAIL)
      var tailCutFrom : float3
      var tailCutTo : float3
      if find_blk_cutting_point(*cuttingBlk, "emtr_break_tail_from", tailCutFrom) && find_blk_cutting_point(*cuttingBlk, "emtr_break_tail_to", tailCutTo)
        let tailCutNorm = normalize(tailCutFrom - tailCutTo)
        plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_TAIL)] = float4(tailCutNorm.x, tailCutNorm.y, tailCutNorm.z, 0.0)
        plane_cutting__tailCuttingPos = float2(dot(-tailCutFrom, tailCutNorm), dot(-tailCutTo, tailCutNorm))
      else
        plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_TAIL)] = float4(0, 0, 0, 1)
        plane_cutting__tailCuttingPos = float2(1, 1)
    else
      var finCutFrom : float3
      var finCutTo : float3
      if find_root_cutting_point(geom, "emtr_break_fin_from", cuttingBlk, finCutFrom) && find_root_cutting_point(geom, "emtr_break_fin_to", cuttingBlk, finCutTo)
        let finCutNorm = normalize(finCutFrom - finCutTo)
        plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_FIN)] = float4(finCutNorm.x, finCutNorm.y, finCutNorm.z, 0.0)
        plane_cutting__finCuttingPos = float2(dot(-finCutFrom, finCutNorm), dot(-finCutTo, finCutNorm))
      else
        plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_FIN)] = float4(0, 0, 0, 1)
        plane_cutting__finCuttingPos = float2(1, 1)

    for s in range(2)
      let side = s == 0 ? "l" : "r"
      assume stabCuttingPos = s == 0 ? plane_cutting__stabLeftCuttingPos : plane_cutting__stabRightCuttingPos
      var stabCutFrom : float3
      var stabCutTo : float3
      if find_root_cutting_point(geom, "emtr_break_stab_{side}_from", cuttingBlk, stabCutFrom) && find_root_cutting_point(geom, "emtr_break_stab_{side}_to", cuttingBlk, stabCutTo)
        let stabCutNorm = normalize(stabCutFrom - stabCutTo)
        plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_STAB_L) + s] = float4(stabCutNorm.x, stabCutNorm.y, stabCutNorm.z, 0.0)
        stabCuttingPos = float2(dot(-stabCutFrom, stabCutNorm), dot(-stabCutTo, stabCutNorm))
      else
        plane_cutting__cuttingPlanes[int(WreckageType WRECKAGE_STAB_L) + s] = float4(0, 0, 0, 1)
        stabCuttingPos = float2(1, 1)
