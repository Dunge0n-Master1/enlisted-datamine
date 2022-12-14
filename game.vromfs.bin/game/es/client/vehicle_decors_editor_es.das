require dm
require ecs
require ecs.common
require AnimV20
require CollRes
require math.ang
require math.base
require DagorMath
require DagorSystem
require GeomNodeTree
require EnlistedCamera
require strings

let ATTACH_TO_TURRET_TOUCH_COUNT = 2

struct HitInfo
  position : float3
  normal : float3
  hit : bool
  canPlace : bool
  nodeId : int
  attachToTurret : bool

def private swap_xz(var tm : float3x4)
  let yTmVec = tm[0]
  tm[0] = tm[2]
  tm[2] = yTmVec

def private find_contact_point(collres : CollisionResource;
                               dm_data : DamageModelData;
                               geom_tree : GeomNodeTree const?;
                               screen_pos : float2;
                               tm : float3x4;
                               offset : float3;
                               allow_parts : StringList;
                               allow_parts_ext : StringList;
                               deny_parts : StringList)
  var worldPoint : float3
  var worldDir : float3
  screen_to_world(screen_pos, worldPoint, worldDir)

  let itm = inverse(tm)
  let localPoint = itm * (worldPoint + offset)
  let localDirection = rotate(itm, worldDir)
  let current = 10f
  var ret = [[HitInfo hit=false]]
  collres_traceray(collres, IDENT_TM, geom_tree, localPoint, localDirection, current, true) <| $ [unused_argument(_)] (_ : bool; isects : CollResIntersectionsType#)
    for isect in isects
      if dmData_isTraceable(dm_data, int(isect.collisionNodeId), /*reverse*/false)
        let nodeName = collres_get_node(collres, int(isect.collisionNodeId)) |> collnode_get_name
        let canPlace = !has_value(each(deny_parts), nodeName) && (has_value(each(allow_parts), nodeName) || has_value(each(allow_parts_ext), nodeName))
        ret <- [[HitInfo
          position=localPoint + localDirection * isect.intersectionT,
          normal=isect.normal,
          hit=true,
          canPlace=canPlace,
          nodeId = int(isect.collisionNodeId),
          attachToTurret = find(nodeName, "turret") >= 0]]
        return

  return ret

def private trace_vehcile(collres : CollisionResource;
                          decor_collres : CollisionResource;
                          dm_data : DamageModelData;
                          geom_tree : GeomNodeTree const?;
                          screen_pos : float2;
                          tm : float3x4;
                          decor_transform : float3x4;
                          bbox : bbox3f;
                          bbox_mult : float;
                          allow_parts : StringList;
                          allow_parts_ext : StringList;
                          deny_parts : StringList;
                          var highlight_collision__nodes : IntList)
  let width = bbox.bmax.xyz - bbox.bmin.xyz
  var camTm := IDENT_TM
  find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if camera__active
      camTm = transform
    return camera__active

  let offsets = [[float3[]
    -(width.x * camTm[1] * bbox_mult - width.y * camTm[0] * bbox_mult);
    -(width.x * camTm[1] * bbox_mult + width.y * camTm[0] * bbox_mult);
    width.x * camTm[1] * bbox_mult + width.y * camTm[0] * bbox_mult;
    width.x * camTm[1] * bbox_mult - width.y * camTm[0] * bbox_mult
  ]]

  var avgNormal = float3()
  var avgPos = float3()
  var hitCount = 0
  var canPlace = true
  var attachToTurret = 0
  highlight_collision__nodes |> clear()
  for offset in offsets
    let hit2 = find_contact_point(collres, dm_data, geom_tree, screen_pos, tm, offset, allow_parts, allow_parts_ext, deny_parts)
    if !hit2.hit
      return [[HitInfo hit=false]]
    canPlace &&= hit2.canPlace
    if hit2.attachToTurret
      attachToTurret += 1
    if !canPlace
      highlight_collision__nodes |> push(hit2.nodeId)
    avgPos += hit2.position
    avgNormal += hit2.normal
    ++hitCount

  // first we do simple check by 4 contact point, and if decor still can place we do a collres check
  if canPlace
    var intersectPoint : float3
    var nodeIdx : uint16
    test_collres_intersection(collres, tm, decor_collres, decor_transform,
      intersectPoint, intersectPoint, nodeIdx, nodeIdx) <| $(nodesIds : array<uint16>#)
      for nodeId in nodesIds
        if !dmData_isTraceable(dm_data, int(nodeId), /*reverse*/false)
          continue
        let nodeName = collres_get_node(collres, int(nodeId)) |> collnode_get_name
        canPlace = !has_value(each(deny_parts), nodeName) && (has_value(each(allow_parts), nodeName) || has_value(each(allow_parts_ext), nodeName))
        if !canPlace
          return

  return [[HitInfo
    hit=true,
    canPlace=canPlace,
    position=avgPos / float(hitCount),
    normal=normalize(avgNormal / float(hitCount)),
    attachToTurret=attachToTurret >= ATTACH_TO_TURRET_TOUCH_COUNT
  ]]

[es(track=(decals_manager__target, decals_manager__active_slot), on_appear, before=decals_manager_update_es)]
def ui_decors_setup_es(evt : Event;
                       current_decal__name : string;
                       decals_manager__target : EntityId;
                       decals_manager__active_slot : int;
                       current_decor__type : string;
                       decor_manager__rootNodeName : string;
                       decor_manager__turretNodeName : string;
                       var current_decal__decorEid : EntityId&)
  if !decals_manager__target || decals_manager__active_slot < 0
    destroyEntity(current_decal__decorEid)
    current_decal__decorEid = INVALID_ENTITY_ID
    return

  if current_decal__decorEid == INVALID_ENTITY_ID && current_decor__type == "vehDecorator"
    query(decals_manager__target) <| $ [es] (animchar : AnimcharBaseComponent)
      let attachNodeId = geomtree_findNodeIndex(*animchar.nodeTree, decor_manager__rootNodeName)
      let turretNodeId = geomtree_findNodeIndex(*animchar.nodeTree, decor_manager__turretNodeName) // Optional node
      if attachNodeId <= -1
        logerr("Invalid node {decor_manager__rootNodeName} on target {getEntityTemplateName(decals_manager__target)}")
        return
      current_decal__decorEid = createEntity("{current_decal__name}+node_attached_itm+node_attached_edit") <| $(var init : ComponentsInitializer)
        var tm : float3x4
        tm |> identity
        set(init, "node_attached__entity", decals_manager__target)
        set(init, "node_attached__nodeId", attachNodeId)
        set(init, "node_attached__localTm", tm)
        set(init, "node_attached__template", current_decal__name)
        set(init, "node_attached__nodeName", decor_manager__rootNodeName)
        set(init, "decor__rootNodeId", attachNodeId)
        set(init, "decor__turretNodeId", turretNodeId)
        set(init, "decor__id", decals_manager__active_slot)
        set(init, "animchar_render__enabled", false)

[es(tag=gameClient, track=(decals_manager__screenPos, current_decal__rotation, decals_manager__target), before=decals_manager_update_es)]
def ui_decors_setup_process_es(info : Event;
                               decals_manager__screenPos : float2;
                               current_decal__decorEid : EntityId;
                               current_decal__rotation : float;
                               decals_manager__target : EntityId)
  query(current_decal__decorEid) <| $ [es] (var node_attached__localTm : float3x4&;
                                            var node_attached__entity : EntityId&;
                                            var decor__canAttach : bool&;
                                            var outline__enabled : bool&;
                                            var animchar_render__enabled : bool&;
                                            var node_attached__nodeId : int&;
                                            decor__rootNodeId : int;
                                            decor__turretNodeId : int;
                                            animchar_bbox : bbox3f;
                                            collres aka decor_collres : CollisionResource;
                                            transform aka decor_transform : float3x4;
                                            decor__boxMult : float = 0.1f;
                                            decor__swapYZ : bool = false)
    query(decals_manager__target) <| $ [es] (transform : float3x4;
                                             animchar : AnimcharBaseComponent;
                                             damage_model : DamageModel;
                                             [[shared_comp]] vehicle_attach__allowParts : StringList;
                                             vehicle_attach__allowPartsExt : StringList;
                                             vehicle_attach__denyParts : StringList;
                                             var highlight_collision__nodes : IntList;
                                             collres : CollisionResource)
      node_attached__entity = decals_manager__target
      let hit = trace_vehcile(collres, decor_collres, damage_model.dmData, animchar.originalNodeTree, decals_manager__screenPos,
        transform, decor_transform, animchar_bbox, decor__boxMult, vehicle_attach__allowParts, vehicle_attach__allowPartsExt, vehicle_attach__denyParts,
        highlight_collision__nodes)
      animchar_render__enabled = hit.hit
      if hit.hit
        var rotTm : float3x4
        make_tm(hit.normal, -current_decal__rotation, rotTm)
        var fwd = float3(1, 0, 0)
        var left = cross(fwd, hit.normal)
        // TODO: there still will be some jitter when different pairs of vectors are taken. Can we do better?
        if length_sq(left) < 1e-5f
          fwd = normalize(cross(hit.normal, float3(0, 0, 1)))
          left = normalize(cross(fwd, hit.normal))
        else
          fwd = normalize(cross(hit.normal, left))
          left = normalize(left)

        var tm := IDENT_TM
        tm[0] = rotTm * fwd
        tm[1] = hit.normal
        tm[2] = rotTm * left
        tm[3] = hit.position
        if decor__swapYZ
          swap_xz(tm)

        if hit.attachToTurret && decor__turretNodeId >= 0
          node_attached__nodeId = decor__turretNodeId
        else
          node_attached__nodeId = decor__rootNodeId

        var wtm : float3x4
        geomtree_getNodeWtmScalar(*animchar.nodeTree, node_attached__nodeId, wtm)
        node_attached__localTm = inverse(wtm) * (transform * tm)

        outline__enabled = !hit.canPlace
        decor__canAttach = hit.canPlace
        query() <| $ [es] (var armor_analyzer__mode : int&)
          armor_analyzer__mode = hit.canPlace ? 0 /*ArmorViewMode::VIEW_NONE*/ : 4 /*ArmorViewMode::VIEW_SEPARATE_NODES*/;

[es(tag=gameClient, on_event=SaveVehicleDecor, before=decor_save_es)]
def decor_editor_set_node_name_es(evt : Event;
                                  current_decal__decorEid : EntityId;
                                  decor_manager__rootNodeName : string = "root";
                                  decor_manager__turretNodeName : string = "bone_turret")
  query(current_decal__decorEid) <| $ [es] (node_attached__nodeId : int;
                                            decor__rootNodeId : int;
                                            decor__turretNodeId : int;
                                            var node_attached__nodeName : das_string&)
    if node_attached__nodeId == decor__rootNodeId
      node_attached__nodeName := decor_manager__rootNodeName
    elif node_attached__nodeId == decor__turretNodeId
      node_attached__nodeName := decor_manager__turretNodeName
