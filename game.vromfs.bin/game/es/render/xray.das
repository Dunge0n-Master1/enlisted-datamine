require ecs
require Xray
require AnimV20
require GeomNodeTree
require enlisted.events_enlisted

def get_node_no(node : uint)
  return int(node) & int(0xFFFF)

def get_remapped_node_no(node : uint)
  return (int(node) >> 16) & int(0xFFFF)


[es(tag=render, on_appear)]
def xray_skeleton_init_es(evt : Event;
                          animchar : AnimcharBaseComponent;
                          xray_resource : XrayResourceHolder&;
                          var xray_resource__animRemap : UInt32List)
  clear(xray_resource__animRemap)

  let allNodes = int(xray_resource.xrayRes.nodeTree.nodeCount)
  for i in range(allNodes)
    let nodeName = *xray_resource.xrayRes.nodeTree |> geomtree_getNodeName(i)
    let nodeIdx = *animchar.nodeTree |> geomtree_findNodeIndex(nodeName)
    if nodeIdx >= 0
      assert(nodeIdx <= 65536)
      assert(i <= 65536)
      push(xray_resource__animRemap, uint(nodeIdx << 16 | i))

def xray_skeleton_update_impl_es(target_eid : EntityId)
  query(target_eid) <| $ [es] (xray_resource__animRemap : UInt32List;
                               animchar : AnimcharBaseComponent;
                               var xray_resource : XrayResourceHolder&)
    var tm : float3x4
    for node in xray_resource__animRemap
      let animNodeId = get_remapped_node_no(node)
      let xrayNodeId = get_node_no(node)
      geomtree_getNodeWtmRelScalar(*animchar.nodeTree, animNodeId, tm)
      geomtree_setNodeWtmRelScalar(*xray_resource.xrayRes.nodeTree, xrayNodeId, tm)
      geomtree_recalcTm(*xray_resource.xrayRes.nodeTree, xrayNodeId, false)


[es(tag=render, no_order)]
def hitcamera_xray_skeleton_update_es(info : ParallelUpdateFrameDelayed;
                                      hitcamera__target : EntityId)
  xray_skeleton_update_impl_es(hitcamera__target)

[es(tag=render, no_order)]
def armor_analyzer_xray_skeleton_update_es(info : ParallelUpdateFrameDelayed;
                                           armor_analyzer__target : EntityId)
  xray_skeleton_update_impl_es(armor_analyzer__target)
