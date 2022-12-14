require ecs
require ecs.common
require math.base
require AnimV20
require CollRes
require GeomNodeTree
require DagorSystem

[es(tag=server, on_appear)]
def init_attach_nodes(evt : Event;
                      seat__id : int;
                      seat__vehicleEid : EntityId;
                      var seats_attach_nodes__ignoreAttachNodeRotation : bool&;
                      var seats_attach_nodes__nodeId : int&;
                      var seats_attach_nodes__collNodeId : int&;
                      var seats_attach_nodes__initialTm : float3x4;
                      var seats_attach_nodes__attachTm : float3x4;
                      var seats_attach_nodes__nodeItm : float3x4)
  query(seat__vehicleEid) <| $ [es] ([[shared_comp]] vehicle_seats__seats : Array;
                                     animchar : AnimcharBaseComponent;
                                     collres : CollisionResource)
    let seat = get_ecs_object(vehicle_seats__seats, seat__id)
    if seat == null
      return

    var rootItm : float3x4
    geomtree_getNodeWtmRelScalar(*animchar.nodeTree, 0, rootItm)
    rootItm = inverse(rootItm)

    let nodeName = get_string(*seat, "attachNode", "")
    if nodeName == ""
      logerr("attachNode is not set for {seat__vehicleEid} ({getEntityTemplateName(seat__vehicleEid)})")
      return

    seats_attach_nodes__nodeId     = geomtree_findNodeIndex(*animchar.nodeTree, nodeName)
    seats_attach_nodes__collNodeId = collres_get_node_index_by_name(collres, nodeName)
    seats_attach_nodes__attachTm   = get_TMatrix(*seat, "attachTm") ?? IDENT_TM
    seats_attach_nodes__initialTm  = seats_attach_nodes__attachTm
    seats_attach_nodes__ignoreAttachNodeRotation = get_bool(*seat, "ignoreAttachNodeRotation") ?? false

    if seats_attach_nodes__nodeId >= 0
      geomtree_getNodeWtmRelScalar(*animchar.nodeTree, seats_attach_nodes__nodeId, seats_attach_nodes__nodeItm)
      seats_attach_nodes__nodeItm = rootItm * seats_attach_nodes__nodeItm
    elif seats_attach_nodes__collNodeId >= 0
      collres_get_collision_node_tm(collres, seats_attach_nodes__collNodeId, IDENT_TM, null, seats_attach_nodes__nodeItm)
    else
      logerr("Attach node ({nodeName}) not found for {seat__vehicleEid} ({getEntityTemplateName(seat__vehicleEid)})")

    seats_attach_nodes__nodeItm = inverse(seats_attach_nodes__nodeItm)