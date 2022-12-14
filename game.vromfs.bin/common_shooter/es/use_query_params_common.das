module use_query_params_common shared
require ecs
require AnimV20
require GeomNodeTree

struct UseQueryParams
  canUse : bool
  pos : float3
  dir : float3
  dist : float
  dot : float

def get_use_query_params(eid : EntityId) : UseQueryParams
  var result : UseQueryParams
  query(eid) <| $ [es] (animchar : AnimcharBaseComponent;
                        human_use_object__useDist : float;
                        isAlive = true;
                        human_use_object__nodeId = 0;
                        human_use_object__useAltarDirMinDot = 0.7)
    result.dot = human_use_object__useAltarDirMinDot
    result.dist = human_use_object__useDist
    if !isAlive
      return

    find_query() <| $ [es] (camera__active : bool; transform : float3x4)
      if camera__active
        result.canUse = true
        result.dir = transform[2]
        if human_use_object__nodeId > 0
          result.pos = geomtree_getNodeWpos(*animchar.nodeTree, human_use_object__nodeId)
        else
          result.pos = transform[3]
      return camera__active
  return result