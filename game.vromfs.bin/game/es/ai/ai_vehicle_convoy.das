
require ecs
require ecs.common
require math.base
require vehicle
require DagorSystem
require DagorMathUtils
require DagorConsole
require enlisted.game.es.ai.ai_vehicle_convoy_common



[es(tag=server, on_event=(EventLevelLoaded))]
def generate_navmesh_path_on_init(evt : Event;
                                  ai_vehicle_convoy__pathPoints : Array;
                                  var ai_vehicle_convoy__navmeshPathPoints : Point3List&;
                                  var ai_vehicle_convoy__finalPointsByCapzoneGroup : Object&)
  generate_navmesh_path(ai_vehicle_convoy__pathPoints,
                        ai_vehicle_convoy__navmeshPathPoints,
                        ai_vehicle_convoy__finalPointsByCapzoneGroup)


def private get_entity_positions(vehicles : EidList)
  var positions : array<float3>
  for vehicleEid in vehicles
    query(vehicleEid) <| $ [es] (transform : float3x4)
      push(positions, transform[3])

  return <- positions


def private find_falling_behind_vehicle_id(vehicle_positions : array<float3>; max_distance_sq : float)
  for i in range(1, length(vehicle_positions))
    let distanceSq = length_sq(vehicle_positions[i - 1] - vehicle_positions[i])
    if distanceSq > max_distance_sq
      return i
  return -1


def private set_vehicle_max_throttle(vehicle_eid : EntityId; max_throttle : float)
  query(vehicle_eid) <| $ [es] (var ai_vehicle_driver__maxThrottle : float&)
    ai_vehicle_driver__maxThrottle = max_throttle


[es(tag=server, no_order)]
def validate_distances_between_vehicles_es(info : UpdateStageInfoAct;
                                           ai_vehicle_convoy__vehicles : EidList;
                                           ai_vehicle_convoy__minMaxVehicleDistance : float2;
                                           ai_vehicle_convoy__vehicleLength : float;
                                           ai_vehicle_convoy__leadVehicleMaxThrottle : float;
                                           ai_vehicle_convoy__validateDistancesUpdateInterval : float;
                                           var ai_vehicle_convoy__nextValidateDistanceUpdateAt : float&)
  if ai_vehicle_convoy__nextValidateDistanceUpdateAt > info.curTime || length(ai_vehicle_convoy__vehicles) == 0
    return

  ai_vehicle_convoy__nextValidateDistanceUpdateAt = info.curTime + ai_vehicle_convoy__validateDistancesUpdateInterval

  let minVehicleDistanceSq = square(ai_vehicle_convoy__vehicleLength + ai_vehicle_convoy__minMaxVehicleDistance[0])
  let maxVehicleDistanceSq = square(ai_vehicle_convoy__vehicleLength + ai_vehicle_convoy__minMaxVehicleDistance[1])

  let vehiclePositions <- get_entity_positions(ai_vehicle_convoy__vehicles)
  if length(ai_vehicle_convoy__vehicles) != length(vehiclePositions)
    return

  let fallingBehindVehicleId = find_falling_behind_vehicle_id(vehiclePositions, maxVehicleDistanceSq)

  for i in range(1, length(vehiclePositions))
    let distanceSq = length_sq(vehiclePositions[i - 1] - vehiclePositions[i])
    let isTooCloseToVehicleAhead = distanceSq < minVehicleDistanceSq
    set_vehicle_max_throttle(ai_vehicle_convoy__vehicles[i], isTooCloseToVehicleAhead ? 0.0 : ai_vehicle_convoy__leadVehicleMaxThrottle)

  if fallingBehindVehicleId == -1
    set_vehicle_max_throttle(ai_vehicle_convoy__vehicles[0], ai_vehicle_convoy__leadVehicleMaxThrottle)

  for i in range(0, fallingBehindVehicleId)
    set_vehicle_max_throttle(ai_vehicle_convoy__vehicles[i], 0.0)


[es(tag=server, on_event=(EventEntityCreated, EventComponentsAppear), REQUIRE=(ai_vehicle_driver, deadEntity))]
def remove_vehicle_from_convoy_on_death_es(evt : Event; eid : EntityId)
  find_query() <| $ [es] (var ai_vehicle_convoy__vehicles : EidList&)
    let vehicleId = find_index(ai_vehicle_convoy__vehicles, eid)
    if vehicleId < 0
      return false

    ai_vehicle_convoy__vehicles |> erase(vehicleId)
    return true


[es(tag=server, track=ai_vehicle_driver__destinationReached)]
def update_destination_on_arrival(evt : Event;
                                  eid : EntityId;
                                  var ai_vehicle_driver__destinationReached : bool&;
                                  var ai_vehicle_driver__destination : float3&;
                                  var ai_vehicle_convoy_vehicle__currentReachedPointId : int&;
                                  ai_vehicle_convoy_vehicle__convoyEid : EntityId)
  if !ai_vehicle_driver__destinationReached
    return

  query(ai_vehicle_convoy_vehicle__convoyEid) <| $ [es] (ai_vehicle_convoy__vehicles : EidList;
                                                         ai_vehicle_convoy__navmeshPathPoints : Point3List;
                                                         ai_vehicle_convoy__finalPointId : int;
                                                         var ai_vehicle_convoy__reachedPointId : int&)
    let vehicleId = find_index(ai_vehicle_convoy__vehicles, eid)
    if vehicleId < 0
      return

    let atPathEnd = ai_vehicle_convoy_vehicle__currentReachedPointId >= length(ai_vehicle_convoy__navmeshPathPoints) - 1
    let atFinalPoint = ai_vehicle_convoy_vehicle__currentReachedPointId >= ai_vehicle_convoy__finalPointId
    if atPathEnd || atFinalPoint
      return

    let nextDestination = ai_vehicle_convoy__navmeshPathPoints[ai_vehicle_convoy_vehicle__currentReachedPointId + 1]
    ai_vehicle_driver__destination = nextDestination
    ai_vehicle_convoy_vehicle__currentReachedPointId += 1
    ai_vehicle_driver__destinationReached = false

    if vehicleId == 0
      ai_vehicle_convoy__reachedPointId += 1


[es(tag=server, on_event=(EventLevelLoaded))]
def spawn_convoys(evt : Event)
  spawn_convoy_vehicles()


[es(tag=server, on_event=(EventLevelLoaded, EventEntityCreated, EventComponentsAppear), track=active, REQUIRE=capzone)]
def update_final_point_on_capzone_activation(evt : Event;
                                             active : bool;
                                             groupName : string)
  if !active
    return

  query() <| $ [es] (ai_vehicle_convoy__finalPointsByCapzoneGroup : Object;
                     ai_vehicle_convoy__reachedPointId : int;
                     ai_vehicle_convoy__vehicles : EidList;
                     var ai_vehicle_convoy__finalPointId : int&)
    let newFinalPoint = ai_vehicle_convoy__finalPointsByCapzoneGroup |> get_int(groupName)
    if newFinalPoint == null
      return

    let atFinalPoint = ai_vehicle_convoy__reachedPointId == ai_vehicle_convoy__finalPointId

    if length(ai_vehicle_convoy__vehicles) != 0 && atFinalPoint
      query(ai_vehicle_convoy__vehicles[0]) <| $ [es] (var ai_vehicle_driver__destinationReached : bool&)
        ai_vehicle_driver__destinationReached = false

    ai_vehicle_convoy__finalPointId = *newFinalPoint


[es(tag=server, before=vehicle_input_driver_es)]
def ai_vehicle_driver_es(info : UpdateStageInfoAct;
                         transform : float3x4;
                         ai_vehicle_driver__maxThrottle : float;
                         ai_vehicle_driver__steeringDeadZone : float;
                         ai_vehicle_driver__steeringSmoothness : float;
                         ai_vehicle_driver__destination : float3;
                         ai_vehicle_driver__destinationReachedThreshold : float;
                         var ai_vehicle_driver__destinationReached : bool&;
                         var vehicle_net_phys : VehiclePhysActor&)
  var steering = 0.0
  var throttle = 0.0
  var brake = 0.0

  var dist = length(ai_vehicle_driver__destination - transform[3])
  ai_vehicle_driver__destinationReached = dist <= ai_vehicle_driver__destinationReachedThreshold

  var moveDir = ai_vehicle_driver__destination - transform[3]
  moveDir.y = 0.0
  dist = length(moveDir)

  if !ai_vehicle_driver__destinationReached
    moveDir *= safeinv(dist)
    let vehicleDirAngle = dir_to_angles(transform[0])
    let targetDir = dir_to_angles(moveDir)
    let normAng = renorm_ang(targetDir.x, vehicleDirAngle.x) - vehicleDirAngle.x

    if abs(normAng) > ai_vehicle_driver__steeringDeadZone && vehicle_net_phys.phys.haveSeparateBrakes
      throttle = 0.0
      steering = sign(-normAng)
    else
      throttle = ai_vehicle_driver__maxThrottle
      steering = clamp(-normAng * ai_vehicle_driver__steeringSmoothness, -1.0, 1.0)

  if ai_vehicle_driver__destinationReached || throttle == 0.0
    brake = 1.0

  assume producedCT = vehicle_net_phys.phys.producedCT

  producedCT |> ground_control_state_setAutomaticTransmission(true)
  producedCT |> ground_control_state_setKeepDrivingDirectionMode(false)

  producedCT |> ground_control_state_setAxisValue(EGroundControlAxis GCA_STEERING, steering)
  producedCT |> ground_control_state_setAxisValue(EGroundControlAxis GCA_THROTTLE, throttle)
  producedCT |> ground_control_state_setAxisValue(EGroundControlAxis GCA_HAND_BRAKE, brake)
  producedCT |> ground_control_state_setAxisValue(EGroundControlAxis GCA_BRAKE_LEFT, brake)
  producedCT |> ground_control_state_setAxisValue(EGroundControlAxis GCA_BRAKE_RIGHT, brake)
