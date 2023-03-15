require ecs
require ecs.soa_template
require math.base
require GeomNodeTree
require AnimV20
require DagorSystem
require DagorMath
require enlisted.events_enlisted


// Planes are directly imported from WT and right now we can't change their models (or we wont get any future plane models updates)
// But IK nodes in these models are made specifically for WT soldier model, and our IK node is in a different spot
// These ES's move those nodes in palces more suitable for our soldier model
// Ideally, we should not have these!

[soa_template]
struct MoveCockpitIkNode
  move_cockpit_node__nodeId : int
  move_cockpit_node__offset : float3
  move_cockpit_node__rotation : float2


[es(tag=render, on_appear)]
def init_move_cockpit_nodes_id(evt : Event;
                               eid : EntityId;
                               animchar : AnimcharBaseComponent;
                               move_cockpit_node__nodeName : StringList;
                               var move_cockpit_node__nodeId : IntList&)
  if length(move_cockpit_node__nodeName) != length(move_cockpit_node__nodeId)
    logerr("Plane {getEntityTemplateName(eid)} must have equal size move_cockpit_node__nodeName and move_cockpit_node__nodeId")
    return

  for nodeName, nodeId in move_cockpit_node__nodeName, move_cockpit_node__nodeId
    nodeId = *animchar.nodeTree |> geomtree_findNodeIndex("{nodeName}")

[soa_es, es(tag=render, before=human_vehicle_cockpit_effectors, after=(human_anim_es, plane_anim_es), REQUIRE=cockpit__effectors)]
def move_cockpit_ik_nodes(info : ParallelUpdateFrameDelayed;
                          move_cockpit_ik_node : MoveCockpitIkNode_SOA;
                          var animchar : AnimcharBaseComponent)
  for node in move_cockpit_ik_node
    var tm : float3x4
    if node.move_cockpit_node__nodeId > 0
      *animchar.nodeTree |> geomtree_getNodeWtmScalar(node.move_cockpit_node__nodeId, tm)
      tm[3] += tm[0] * node.move_cockpit_node__offset.x + tm[1] * node.move_cockpit_node__offset.y + tm[2] * node.move_cockpit_node__offset.z

      var rotTm : float3x4
      rotxTM(deg_to_rad(node.move_cockpit_node__rotation.x), rotTm)
      tm = tm * rotTm
      rotzTM(deg_to_rad(node.move_cockpit_node__rotation.y), rotTm)
      tm = tm * rotTm
      *animchar.nodeTree |> geomtree_setNodeWtmScalar(node.move_cockpit_node__nodeId, tm)
