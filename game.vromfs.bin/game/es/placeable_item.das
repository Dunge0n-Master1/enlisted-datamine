require ecs
require ecs.common
require EnlistedNet
require common_shooter.events_common_shooter
require GridCollision
require CollisionTraces
require enlisted.events_enlisted
require CollRes
require AnimV20
require Dacoll
require math.base
require DagorMath
require enlisted.game.es.placeable_item_common
require strings
require game.es.events
require game.es.inventory_common


[es(tag=gameClient, before=placeable_item_place_request)]
def placeable_item_detach_reset_es(evt : CmdWeapAttach; var placeable_item__placeRequestReady : bool&)
  if !evt.isAttached
    placeable_item__placeRequestReady = false


[es(tag=gameClient, REQUIRE_NOT=itemInWorld)]
def placeable_item_place_request(evt : CmdWeapPhysUpdate;
                                 eid : EntityId;
                                 slot_attach__attachedTo : EntityId;
                                 animchar_render__root_pos : vec4f;
                                 var placeable_item__placeTm : float3x4&;
                                 var placeable_item__inProgress : bool&;
                                 var placeable_item__placeRequestSend : bool&;
                                 var placeable_item__placeRequestReady : bool&;
                                 var placeable_item__lastPosition : float3&;
                                 placeable_item__minDistanceToWall : float;
                                 placeable_item__additionalHeight : float;
                                 placeable_item__additionalRotation : float3;
                                 placeable_item__maxAnimHeight = 0.2;
                                 placeable_item__allowablePlaceHeight = 0.15f)
  if !evt.isForReal
    return
  let isShootPressed = evt.gctrl.shoot
  placeable_item__placeRequestReady ||= !isShootPressed
  if placeable_item__placeRequestReady && isShootPressed
    placeable_item__inProgress = true
    placeable_item__placeRequestSend = false

  if !placeable_item__inProgress
    return

  var humanTm : float3x4
  var humanAnimcharRenderRootPos : float3
  query(slot_attach__attachedTo) <| $ [es] (transform : float3x4; animchar_render__root_pos : vec4f)
    humanTm = transform
    humanAnimcharRenderRootPos = animchar_render__root_pos.xyz

  let initialHeight = 100.
  var placePos = float3(animchar_render__root_pos.x, animchar_render__root_pos.y, animchar_render__root_pos.z)
  var height = initialHeight
  var norm : float3
  var vehicleEid = INVALID_ENTITY_ID
  var vehicleNodeId = 0
  var startPlace = false

  if has(eid, "attachableToVehicle")
    let traceDir = float3(0., -1., 0.)

    trace_entities_in_grid(ecs_hash("vehicles"), placePos, traceDir, height, INVALID_ENTITY_ID, SortIntersections YES) <| $(intersections : array<IntersectedEntity>#)
      for it in intersections
        if has(it.eid, "vehicle")
          norm = it.norm
          vehicleEid = it.eid
          query(vehicleEid) <| $ [es] (animchar : AnimcharBaseComponent;
                                       collres : CollisionResource)
            let node = collres_get_node(collres, it.collNodeId)
            // 0 - animchar root node id
            vehicleNodeId = uint(node.geomNodeId) < uint(animchar.nodeTree.nodeCount) ? int(node.geomNodeId) : 0
          break

    if !!vehicleEid
      startPlace = height < placeable_item__allowablePlaceHeight || humanAnimcharRenderRootPos.y - placePos.y > placeable_item__maxAnimHeight

  if !startPlace
    var wallNorm : float3
    var distance = placeable_item__minDistanceToWall
    let traceDir = normalize_default(placePos - placeable_item__lastPosition, humanTm[0])
    let traceDirXZ = float3(traceDir.x, 0.0, traceDir.z)
    let isNearbyWall = traceray_normalized(placePos, traceDirXZ, distance, wallNorm, ETF_DEFAULT)
    if isNearbyWall
      placePos += normalize(float3(wallNorm.x, 0.0, wallNorm.z)) * (placeable_item__minDistanceToWall - distance)

    height = initialHeight
    let traceResult = tracedown_normalized(placePos, height, norm, ETF_DEFAULT)

    startPlace = traceResult && (height < placeable_item__allowablePlaceHeight || isNearbyWall)

    if !startPlace && traceResult && humanAnimcharRenderRootPos.y - placePos.y > placeable_item__maxAnimHeight
      height = initialHeight
      if tracedown_normalized(placePos, height, norm, ETF_DEFAULT)
        startPlace = true

    if !startPlace && !traceResult
      let placePosXZ = placePos.xz
      height = placePos.y - traceht_lmesh(placePosXZ)
      startPlace = true

  placeable_item__lastPosition = placePos

  if placeable_item__placeRequestSend || !placeable_item__placeRequestReady || !startPlace
    return

  placeable_item__placeTm = humanTm
  placeable_item__placeTm[1] = normalize_default(norm, float3(0., 1., 0.)) // up
  placeable_item__placeTm[2] = cross(placeable_item__placeTm[0], placeable_item__placeTm[1]) // dir
  placeable_item__placeTm[0] = cross(placeable_item__placeTm[1], placeable_item__placeTm[2]) // side

  let anglesRad = deg_to_rad(placeable_item__additionalRotation)
  var q : quat
  euler_to_quat(anglesRad.y, anglesRad.z, anglesRad.x, q) // yaw, roll, pitch
  var rotTm : float3x4
  make_tm(q, float3(0.0f, 0.0f, 0.0f), rotTm)
  placeable_item__placeTm = placeable_item__placeTm * rotTm
  placeable_item__placeTm[3] = placePos
  placeable_item__placeTm[3].y += placeable_item__additionalHeight - height

  orthonormalize(placeable_item__placeTm) // remove scale

  placeable_item__inProgress = false
  placeable_item__placeRequestSend = true
  placeable_item__placeRequestReady = false

  send_net_event(slot_attach__attachedTo, [[CmdStartPlacePlaceableItem
                                            itemEid = eid,
                                            tm = placeable_item__placeTm,
                                            vehicleEid = vehicleEid,
                                            vehicleNodeId = vehicleNodeId]])


[es(REQUIRE=transform,  on_appear)]
def remove_from_attachments_on_create_es(evt : Event;
                                         eid : EntityId;
                                         placeable_item__ownerEid : EntityId)
  query(placeable_item__ownerEid) <| $ [es] (var attaches_list : EidList&)
    let idxInAttaches = find_index(attaches_list, eid)
    if idxInAttaches != -1
      erase(attaches_list, idxInAttaches)


[es]
def placeable_item_start_place_es(evt : CmdStartPlacePlaceableItem;
                                  eid : EntityId;
                                  transform : float3x4;
                                  team : int;
                                  var itemContainer : EidList&;
                                  var human_weap__gunEids : EidList&;
                                  var human_weap__currentGunEid : EntityId&)
  if human_weap__currentGunEid != evt.itemEid
    return

  let previewTm = evt.tm
  if !verify_place_restrictions(transform[3], previewTm[3], human_weap__currentGunEid)
    return
  let idxInContainer = find_index(itemContainer, human_weap__currentGunEid)
  if idxInContainer != -1
    erase(itemContainer, idxInContainer)
  let idxInGuns = find_index(human_weap__gunEids, human_weap__currentGunEid)
  if idxInGuns != -1
    human_weap__gunEids[idxInGuns] = INVALID_ENTITY_ID
  sendEventImmediate(human_weap__currentGunEid, [[CmdWeapAttach toEid=eid, isAttached=false, slotId=idxInGuns]])
  var placeTemplate = ""
  var keepOldTemplate = true
  query(evt.itemEid) <| $ [es] (placeable_item__removedTemplate : string = "";
                                placeable_item__template : string;
                                placeable_item__keepOldTemplate : bool;
                                attachable_to_vehicle__template = "")
    keepOldTemplate = placeable_item__keepOldTemplate
    if evt.vehicleEid != INVALID_ENTITY_ID && !empty(attachable_to_vehicle__template)
      placeTemplate = attachable_to_vehicle__template
    else
      placeTemplate = placeable_item__template
    if placeable_item__removedTemplate != ""
      removeSubTemplate(human_weap__currentGunEid, placeable_item__removedTemplate)
  addSubTemplate(human_weap__currentGunEid, placeTemplate) <| $(var init : ComponentsInitializer)
    init_placeable_item_components(init, previewTm, eid, team)
    init_attached_to_vehicle_placeable_item_components(init, previewTm, evt.vehicleEid, evt.vehicleNodeId)

  if !keepOldTemplate
    reCreateEntityFrom(human_weap__currentGunEid, placeTemplate)

  sendEvent(eid, [[CmdFinishPlacePlaceableItem
                   tm=previewTm,
                   newTemplate=keepOldTemplate ? add_sub_template_name(evt.itemEid, placeTemplate) : placeTemplate,
                   itemEid=human_weap__currentGunEid,
                   vehicleEid=evt.vehicleEid,
                   vehicleNodeId=evt.vehicleNodeId]])
  human_weap__currentGunEid = INVALID_ENTITY_ID


[es(tag=server)]
def placeable_item_finish_place_es(evt : CmdFinishPlacePlaceableItem;
                                   eid : EntityId;
                                   team : int)
  if !empty(evt.newTemplate) && !!evt.itemEid
    remote_recreate_entity_from(evt.itemEid, "{evt.newTemplate}") <| $(var init : ComponentsInitializer)
      init_placeable_item_components(init, evt.tm, eid, team)
      init_attached_to_vehicle_placeable_item_components(init, evt.tm, evt.vehicleEid, evt.vehicleNodeId)


[es(tag=server)]
def placeable_item_on_loot(evt : EventOnLootPickup; eid : EntityId; var itemContainer : EidList&)
  query(evt.itemEid) <| $ [es(REQUIRE=placeable_item)] (item__template : string)
    let oldItemEidIdx = find_index(itemContainer, evt.itemEid)
    if oldItemEidIdx > -1
      erase(itemContainer, oldItemEidIdx)
    destroyEntity(evt.itemEid)
    push_item_in_cont(eid, item__template)
