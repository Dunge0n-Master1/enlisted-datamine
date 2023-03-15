require ecs
require ecs.common
require dm
require DmFire
require AnimV20
require GeomNodeTree
require game.es.node_attach_common
require strings

def init_part_ids_array(damage_model; part_names; var info_obj : Object)
  using() <| $(var arr : Array)
    for partNameObj in part_names
      let partName = get_string(partNameObj, "")
      if partName == ""
        continue
      let partId = damage_model |> find_part_id_by_name(partName)
      if partId < 0
        continue
      arr |> push(partId)
    info_obj |> set("partIds", arr)

def init_nodes_ids_array(animchar : AnimcharBaseComponent; nodes; var info_obj : Object&)
  using() <| $(var arr : Array)
    for nodeObj in nodes
      let nodeName = get_string(nodeObj, "")
      if nodeName == ""
        continue
      let nodeId = *animchar.nodeTree |> geomtree_findNodeIndex(nodeName)
      if nodeId < 0
        continue
      arr |> push(nodeId)
    info_obj |> set("nodeIds", arr)

def is_fire_connected_to_part(node_info : Object; part_id : int)
  let parts = get_ecs_array(node_info, "partIds")
  if parts == null
    return false
  for partIdObj in *parts
    let partId = get_int(partIdObj) ?? - 1
    if partId >= 0 && partId == part_id
      return true
  return false

def create_vehicle_external_fire(vehicle_eid : EntityId; fire_template : string; node_id : int)
  let fireEid = createEntity(fire_template) <| $(var init : ComponentsInitializer)
    var tm : float3x4
    get_node_wpos(vehicle_eid, node_id, tm)
    init |> set("transform", tm) // without offset

  attach_to_node_pos(fireEid, vehicle_eid, node_id, float3(0))
  return fireEid

def collect_nodes(node_info : Object; var out_nodes : IntList&)
  let nodes = get_ecs_array(node_info, "nodeIds")
  if nodes == null
    return
  for nodeObj in *nodes
    let nodeId = get_int(nodeObj) ?? -1
    if nodeId >= 0 && find_index(out_nodes, nodeId) < 0
      out_nodes |> push(nodeId)

def collect_affected_nodes(fire_damage_state : FireDamageState; nodes_info : Array; var out_nodes : IntList&)
  for state in fire_damage_state.states
    for nodeInfoObj in nodes_info
      let nodeInfo = get_ecs_object(nodeInfoObj)
      if nodeInfo != null && is_fire_connected_to_part(*nodeInfo, int(state.partId.id))
        collect_nodes(*nodeInfo, out_nodes)

[es(tag=server, on_appear)]
def init_vehicle_external_fire_node_info(evt : Event;
                                         damage_model : DamageModel;
                                         animchar : AnimcharBaseComponent;
                                         [[shared_comp]] vehicle_external_fire__info : Array;
                                         var vehicle_external_fire__infoIds : Array&)
  for infoObj in vehicle_external_fire__info
    let info = get_ecs_object(infoObj)
    if info == null
      continue
    let partNames = get_ecs_array(*info, "dmParts")
    let nodesNames = get_ecs_array(*info, "nodes")
    if partNames == null || nodesNames == null
      continue
    using() <| $(var infoIds : Object)
      init_part_ids_array(damage_model, *partNames, infoIds)
      init_nodes_ids_array(animchar, *nodesNames, infoIds)
      vehicle_external_fire__infoIds |> push(infoIds)

[es(tag=server, track=fire_damage_state)]
def vehicle_external_fire_track_tank_fire_damage_state(evt : Event;
                                                       fire_damage_state : FireDamageState;
                                                       vehicle_external_fire__infoIds : Array;
                                                       var vehicle_external_fire__nodes : IntList&)
  clear(vehicle_external_fire__nodes)
  collect_affected_nodes(fire_damage_state, vehicle_external_fire__infoIds, vehicle_external_fire__nodes)

[es(tag=server, track=vehicle_external_fire__nodes)]
def vehicle_external_fire_track_tank_nodes(evt : Event;
                                           eid : EntityId;
                                           vehicle_external_fire__nodes : IntList;
                                           vehicle_external_fire__template : string;
                                           var vehicle_external_fire__fires : Object&)
  using() <| $(var obj : Object)
    for nodeId in vehicle_external_fire__nodes
      let key = "{nodeId}"
      let fireEid = get_Eid(vehicle_external_fire__fires, key)
      if fireEid != null && !!(*fireEid)
        obj |> set(key, *fireEid)
        vehicle_external_fire__fires |> erase(key)
      else
        obj |> set(key, create_vehicle_external_fire(eid, vehicle_external_fire__template, nodeId))
    for kv in vehicle_external_fire__fires
      destroyEntity(get_Eid(kv.value) ?? INVALID_ENTITY_ID)
    vehicle_external_fire__fires |> move(obj)

[es(tag=server, on_disappear)]
def destroy_vehicle_external_fire(evt : Event; vehicle_external_fire__fires : Object)
  for kv in vehicle_external_fire__fires
    destroyEntity(get_Eid(kv.value) ?? INVALID_ENTITY_ID)
