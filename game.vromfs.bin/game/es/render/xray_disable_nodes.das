require ecs
require AnimV20
require GeomNodeTree
require math.base
require DagorSystem

[es(on_appear)]
def xray_init_disable_nodes_ids(evt : Event;
                                eid : EntityId;
                                animchar : AnimcharBaseComponent;
                                xray__saveNodesTmsNames : StringList;
                                var xray__saveNodesTmsIds : IntList&)
  let idsCount = length(xray__saveNodesTmsNames)
  resize(xray__saveNodesTmsIds, idsCount)
  for i in range(idsCount)
    let nodeId = geomtree_findNodeIndex(*animchar.nodeTree, string(xray__saveNodesTmsNames[i]));
    if nodeId == -1
      logerr("<{getEntityTemplateName(eid)}> does not have '{xray__saveNodesTmsNames[i]}' animchar node. Failed to assign flamethrower.streamEffectNodeIdx")
    xray__saveNodesTmsIds[i] = nodeId
