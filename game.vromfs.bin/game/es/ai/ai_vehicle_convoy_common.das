module ai_vehicle_convoy_common shared

require ecs
require math.base
require DagorSystem
require pathfinder



struct PositionAndGroups
  pos : float3
  groups : array<string>


def private get_position_and_groups_from_path_array(path_points : Array; index : int)
  var positionAndGroups <- [[PositionAndGroups pos = float3(0.0)]]

  let ecsObject = path_points[index] |> get_ecs_object()
  if ecsObject == null
    logerr("Failed to get object index {index} when generating navmesh points for vehicle convoy!")
    return <- positionAndGroups

  let positionObject = *ecsObject |> get_Point3("pos")
  if positionObject == null
    logerr("Failed to get Point3 of object index {index} when generating navmesh points for vehicle convoy!")
    return <- positionAndGroups

  positionAndGroups.pos = *positionObject

  let groups = *ecsObject |> get_ecs_array("groupNames")
  if groups != null
    for group in *groups
      let data = group |> get_ecs_string()
      if data != null
        positionAndGroups.groups |> push <| string(*data)

  return <- positionAndGroups


def generate_navmesh_path(ai_vehicle_convoy__pathPoints : Array;
                          var ai_vehicle_convoy__navmeshPathPoints : Point3List&;
                          var ai_vehicle_convoy__finalPointsByCapzoneGroup : Object&;
                          ai_vehicle_convoy__extraMaxPathLength : float = 30.0)
  clear(ai_vehicle_convoy__navmeshPathPoints)

  if length(ai_vehicle_convoy__pathPoints) < 2
    logerr("A convoy path must have at least 2 points")
    return

  var previousPoint <- get_position_and_groups_from_path_array(ai_vehicle_convoy__pathPoints, 0)

  for group in previousPoint.groups
    if group != ""
      ai_vehicle_convoy__finalPointsByCapzoneGroup |> set(group, 0)

  for i in range(1, length(ai_vehicle_convoy__pathPoints))
    var currentPoint <- get_position_and_groups_from_path_array(ai_vehicle_convoy__pathPoints, i)

    let distance = length(previousPoint.pos - currentPoint.pos)

    let extents = float3(distance + ai_vehicle_convoy__extraMaxPathLength, FLT_MAX, distance + ai_vehicle_convoy__extraMaxPathLength)
    find_path(previousPoint.pos, currentPoint.pos, extents, 10.0, 1.0) <| $(path) //TODO: fix magic values when adding navmesh navigation
      for j in range(length(path) - 1)
        push(ai_vehicle_convoy__navmeshPathPoints, path[j])

    for group in currentPoint.groups
      if group != ""
        ai_vehicle_convoy__finalPointsByCapzoneGroup |> set(group, length(ai_vehicle_convoy__navmeshPathPoints) - 1)

    previousPoint <- currentPoint


def spawn_convoy_vehicles()
  query() <| $ [es] (eid : EntityId;
                     ai_vehicle_convoy__navmeshPathPoints : Point3List;
                     ai_vehicle_convoy__vehiclesCount : int;
                     ai_vehicle_convoy__vehicleTemplate : string;
                     ai_vehicle_convoy__minMaxVehicleDistance : float2;
                     ai_vehicle_convoy__vehicleLength : float;
                     ai_vehicle_convoy__leadVehicleMaxThrottle : float;
                     var ai_vehicle_convoy__vehicles : EidList&)
    if length(ai_vehicle_convoy__navmeshPathPoints) < 2
      logerr("A convoy navmesh path must have at least 2 points")
      return

    let startPoint = ai_vehicle_convoy__navmeshPathPoints[0]
    let nextPoint = ai_vehicle_convoy__navmeshPathPoints[1]

    let startingConvoyDirection = normalize(nextPoint - startPoint)

    for i in range(ai_vehicle_convoy__vehiclesCount)
      let vehicleEid = createEntity("{ai_vehicle_convoy__vehicleTemplate}+ai_vehicle_driver+ai_vehicle_convoy_vehicle+vehicle_control_components") <| $(init)
        let deltaPos = startingConvoyDirection * (ai_vehicle_convoy__vehicleLength + ai_vehicle_convoy__minMaxVehicleDistance[0])
        let vehicleStartPos = startPoint - float(i) * deltaPos
        let nextVehiclePos = vehicleStartPos + deltaPos

        var tm : float3x4 = IDENT_TM
        tm[0] = startingConvoyDirection
        tm[2] = normalize(cross(startingConvoyDirection, tm[1]))
        tm[1] = normalize(cross(tm[2], tm[0]))
        tm[3] = vehicleStartPos
        init |> set("transform", tm)

        init |> set("ai_vehicle_convoy_vehicle__convoyEid", eid)
        init |> set("ai_vehicle_driver__maxThrottle", ai_vehicle_convoy__leadVehicleMaxThrottle)
        init |> set("ai_vehicle_driver__destinationReached", false)
        init |> set("ai_vehicle_driver__destinationReachedThreshold", ai_vehicle_convoy__vehicleLength / 2.0)
        init |> set("ai_vehicle_driver__destination", i == 0 ? nextPoint : nextVehiclePos)
      push(ai_vehicle_convoy__vehicles, vehicleEid)