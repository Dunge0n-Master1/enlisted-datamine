require ecs
require ecs.common
require EnlistedNet
require vehicle
require game.utils.hero
require math
require math.base
require game.es.events
require game.events_game
require game.es.vehicle.vehicle_events
require AnimV20
require GeomNodeTree
require DagorSystem

[es(tag=server, after=create_vehicle_seats, on_appear)]
def vehicle_seats_camera_nodes_init(evt : Event;
                                    eid : EntityId;
                                    animchar : AnimcharBaseComponent;
                                    [[shared_comp]] vehicle_seats__seats : Array;
                                    vehicle_seats__seatEids : EidList;
                                    vehicle_seats_camera_nodes__defaultNode : string = "";
                                    var vehicle_seats_camera_nodes__defaultNodeId : int&)
  let defaultNodeName = vehicle_seats_camera_nodes__defaultNode
  let defaultNodeId = geomtree_findNodeIndex(*animchar.nodeTree, defaultNodeName)
  if defaultNodeId < 0
    logerr("Node {defaultNodeName} for camera not found, entity {eid} <{getEntityTemplateName(eid)}>")
    return

  vehicle_seats_camera_nodes__defaultNodeId = defaultNodeId

  for seatNo, seatEid in iter_range(vehicle_seats__seatEids), vehicle_seats__seatEids
    query(seatEid) <| $ [es] (var seat__cameraNodeNo : int&; var seat__cameraOffset : float3&; var seat__cameraPos : float3&)
      let seat = get_ecs_object(vehicle_seats__seats[seatNo])
      let nodeName = get_string(seat, "cameraNodeName", "")
      let nodeId = nodeName != "" ? geomtree_findNodeIndex(*animchar.nodeTree, nodeName) : defaultNodeId
      if nodeId < 0
        logerr("Node {nodeName} for camera not found, entity {eid} <{getEntityTemplateName(eid)}>")
        return
      seat__cameraNodeNo = nodeId
      seat__cameraOffset = get_Point3(seat, "cameraOffset") ?? float3()
      var rootItm : float3x4
      geomtree_getNodeWtmRelScalar(*animchar.nodeTree, 0, rootItm)
      rootItm = inverse(rootItm)
      var tm : float3x4
      geomtree_getNodeWtmRelScalar(*animchar.nodeTree, seat__cameraNodeNo, tm)
      seat__cameraPos = rootItm * tm * seat__cameraOffset

let
  camera_type_names = [[auto
    "none";
    "passenger";
    "driver";
    "gunner";
    "gunner_cockpit";
    "commander";
    "commander_cockpit";
    "machinegunner_cockpit";
    "dead"
  ]]

[es(on_appear)]
def vehicle_seats_camera_types_init(evt : Event;
                                    seat__id : int;
                                    seat__vehicleEid : EntityId;
                                    var seat__cameraType : int&)
  concept_assert(length(camera_type_names) == int(VehicleCameraType VEHICLE_CAMERA_NUM))
  query(seat__vehicleEid) <| $ [es] ([[shared_comp]] vehicle_seats__seats : Array; [[shared_comp]] defaultCameraTypes : Object)
    let seat = get_ecs_object(vehicle_seats__seats, seat__id)
    if seat == null
      return
    var cameraTypeName = get_string(seat, "cameraType", "")
    if cameraTypeName == ""
      cameraTypeName = get_string(defaultCameraTypes, get_string(seat, "name", ""), "none")
    if cameraTypeName != ""
      let camera_type = find_index(camera_type_names, cameraTypeName)
      seat__cameraType = camera_type >= 0 ? camera_type : int(VehicleCameraType VEHICLE_CAMERA_NONE)

def update_animchar_camera_target(eid : EntityId;
                                  vehicle_seats__seatEids : EidList;
                                  var animchar_camera_target__nodeIndex : int&;
                                  var animchar_camera_target__node_offset : float3?)
  let hasCockpit = find_query() <| $ [es] (cockpit__vehicleEid : EntityId)
    return cockpit__vehicleEid == eid
  if hasCockpit
    return

  let hero = get_watched_entity()
  if !hero
    return
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId; seat__cameraNodeNo : int; seat__cameraOffset : float3)
      if seat__ownerEid != hero
        return
      animchar_camera_target__nodeIndex = seat__cameraNodeNo
      if animchar_camera_target__node_offset != null
        *animchar_camera_target__node_offset = seat__cameraOffset

[es(tag=gameClient, on_appear, on_event=(EventHeroChanged, EventOnSeatOwnersChanged), REQUIRE=vehicleWithWatched, before=vehicle_change_cockpit_es)]
def vehicle_seats_update_animchar_camera_target(evt : Event;
                                                eid : EntityId;
                                                vehicle_seats__seatEids : EidList;
                                                var animchar_camera_target__nodeIndex : int&;
                                                var animchar_camera_target__node_offset : float3?)
  update_animchar_camera_target(eid, vehicle_seats__seatEids, animchar_camera_target__nodeIndex, animchar_camera_target__node_offset)

[es(tag=gameClient, track=vehicleCameraType, REQUIRE=vehicleCameraType, before=vehicle_change_cockpit_es)]
def vehicle_seats_update_animchar_camera_target_type_changed(evt : Event;
                                                             eid : EntityId;
                                                             vehicle_seats__seatEids : EidList;
                                                             var animchar_camera_target__nodeIndex : int&;
                                                             var animchar_camera_target__node_offset : float3?)
  update_animchar_camera_target(eid, vehicle_seats__seatEids, animchar_camera_target__nodeIndex, animchar_camera_target__node_offset)

[es(on_event=EventHeroChanged)]
def vehicle_camera_update(evt : Event; var shooter_cam__alternative_settings : bool&)
  shooter_cam__alternative_settings = false

[es(no_order, tag=gameClient, REQUIRE=heroVehicle, REQUIRE=camNames)]
def vehicle_seats_camera_init(info : UpdateStageInfoAct;
                              eid : EntityId;
                              vehicle_seats__seatEids : EidList;
                              var isCameraInited : bool&)
  if isCameraInited
    return
  let hero = get_controlled_hero()
  if !has(hero, "bindedCamera") // no hero or it's not observed yet
    return
  isCameraInited = true
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId; seat__playerEid : EntityId; seat__isPlayer : bool)
      if seat__ownerEid == hero && seat__isPlayer
        sendEvent(seat__playerEid, [[CmdSwitchCameraByEntity index=0, camNamesEid=eid]])
