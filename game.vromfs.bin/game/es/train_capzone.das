require ecs
require game.es.events
require enlisted.events_enlisted
require DagorMath
require math.base
require enlisted.game.es.train.train_common

[es(tag=server, no_order, REQUIRE=trainZone)]
def train_capzone_move_capzone_navmesh_point(act : UpdateStageInfoAct;
                                             transform : float3x4;
                                             capzone__update_interval : float;
                                             capzone__checkPathToLastPosInterval : float = 10.f;
                                             var capzone__lastNavmeshValidatedAtPos : float3&;
                                             var capzone__next_update_time : float&;
                                             var capzone__insideNavmeshPositions : Point3List&;
                                             var capzone__outsideNavmeshPositions : Point3List&;
                                             var capzone__hasNearestNavmeshPos : bool&;
                                             var capzone__nearestNavmeshPos : float3&)
  if act.curTime < capzone__next_update_time
    return

  capzone__next_update_time = act.curTime + capzone__update_interval
  if capzone__hasNearestNavmeshPos && length_sq(transform[3] - capzone__lastNavmeshValidatedAtPos) < square(capzone__checkPathToLastPosInterval)
    return

  let railroadInited = find_query() <| $ [es] (railroad__points : Point3List)
    return length(railroad__points) != 0

  if !railroadInited
    return

  capzone__nearestNavmeshPos = project_on_railroad(transform[3])
  capzone__hasNearestNavmeshPos = true

  capzone__lastNavmeshValidatedAtPos = transform[3]
  if length(capzone__insideNavmeshPositions) == 0
    push(capzone__insideNavmeshPositions, capzone__nearestNavmeshPos)
  else
    capzone__insideNavmeshPositions[0] = capzone__nearestNavmeshPos

  if length(capzone__outsideNavmeshPositions) == 0
    push(capzone__outsideNavmeshPositions, capzone__nearestNavmeshPos)
  else
    capzone__outsideNavmeshPositions[0] = capzone__nearestNavmeshPos
