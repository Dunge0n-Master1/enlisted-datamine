require ecs
require ecs.common
require game.es.events
require game.es.vehicle.vehicle_events
require game.events_game
require game.es.vehicle.vehicle_seats_common
require vehicle
require EnlistedActor
require EnlistedHuman
require EnlistedNet
require GamePhys

require AnimV20
require CollRes
require GeomNodeTree
require app
require Dacoll
require DagorMath
require math.base


[es(tag=netClient)]
def vehicle_seats_enter_exit_kick_client_es(evt : CmdKickFromVehicle;
                                            eid : EntityId)
  send_net_event(eid, [[RequestKickFromVehicle requester=evt.eid]])

[es(tag=server, REQUIRE=vehicle_seats__seats)]
def vehicle_seats_enter_exit_kick_request_es(evt : RequestKickFromVehicle;
                                             eid : EntityId)
  sendEvent(eid, [[CmdKickFromVehicle eid=evt.requester]])


def private detach_human_from_seat(eid : EntityId; seat__component : int)
  query(eid) <| $ [es] (var isInVehicle : bool&;
                        var isInVehicleHidden : bool&;
                        var human_anim__vehicleSelected : EntityId&;
                        var human_vehicle__occupiedSeatEid : EntityId&)
    isInVehicle = false
    isInVehicleHidden = false
    human_anim__vehicleSelected = INVALID_ENTITY_ID
    human_vehicle__occupiedSeatEid = INVALID_ENTITY_ID

  setOptional(eid, "", uint(seat__component), false)


def private vehicle_trace_exit_pos(var human_net_phys : HumanActor?; var exitPos : float3&; entityTM : float3x4; forcibly : bool = false) : bool
  var pos = entityTM[3]

  if human_net_phys == null
    var dir = exitPos - pos
    var dist = length(dir)
    dir *= safeinv(dist)
    var norm : float3
    if !forcibly && traceray_normalized(pos, dir, dist, norm)
      return false
    let posXZ = pos.xz
    let lmeshHt = traceht_lmesh(posXZ)
    if exitPos.y < lmeshHt
      exitPos.y = lmeshHt
    return true

  assume phys = human_net_phys.phys
  let localCcdPos = phys.ccdPos
  pos = entityTM * localCcdPos
  exitPos += localCcdPos
  let rayMatId = phys.rayMatId
  let additionalCollRad = 0.2
  let collRad = phys.collRad + additionalCollRad
  // cast from old ccd to new ccd
  var toNewCcdOutput = ShapeQueryOutput()
  if distance_sq(pos, exitPos) > 1e-6
    sphere_cast(pos, exitPos, collRad, toNewCcdOutput, rayMatId)
  let sphereCastThreshold = 0.9
  if !forcibly && toNewCcdOutput.t < sphereCastThreshold
    return false
  let exit = lerp(pos, exitPos, float3(toNewCcdOutput.t))
  var wishPos = exit - localCcdPos

  let dropHeight = 6.5
  var t = dropHeight

  if tracedown_normalized(wishPos + float3(0.0, dropHeight * 0.5, 0.0), t, ETF_DEFAULT)
    wishPos.y += dropHeight * 0.5 - t

  if distance_sq(exit, wishPos) > 1e-6
    // cast from new ccd to new location
    var toLocationOutput = ShapeQueryOutput()
    sphere_cast(exit, wishPos, collRad, toLocationOutput, rayMatId)
    wishPos = lerp(exit, wishPos, float3(toLocationOutput.t))

  if length_sq(localCcdPos) > 1e-6
    // fix future position
    assume curState = phys.currentState
    curState.location.P = DPoint3(wishPos)
    curState.height = 1.0
    var newLocationTM : float3x4
    curState.location |> location_toTM(newLocationTM)
    let newCcdPos = newLocationTM * localCcdPos

    // cast from wishPos to newCcdPos
    var fixCcdCastRes = ShapeQueryOutput()
    if sphere_cast(wishPos, newCcdPos, collRad, fixCcdCastRes, rayMatId)
      let penetration = (newCcdPos - wishPos) * (1.0 - fixCcdCastRes.t)
      wishPos -= penetration
      curState.location.P = DPoint3(wishPos)

  exitPos = wishPos
  return true

def private vehicle_teleport_entity_to_node(eid : EntityId; tree : GeomNodeTree const?; node : int; forcibly : bool = false) : bool
  var nodeWtm : float3x4
  *tree |> geomtree_getNodeWtmScalar(node, nodeWtm)
  let entityTM =  get_TMatrix(eid, "transform") ?? IDENT_TM
  var exitPos = nodeWtm[3]
  // rotate nodewtm, so it's vertical
  nodeWtm[1] = float3(0, 1, 0)
  nodeWtm |> orthonormalize()

  var res = false
  query(eid) <| $ [es] (var human_net_phys : HumanActor?)
    if vehicle_trace_exit_pos(human_net_phys, exitPos, entityTM, forcibly)
      nodeWtm[3] = exitPos
      teleport_phys_actor(eid, nodeWtm)
      res = true

  return res

def private vehicle_find_nearest_exit_point(pos : float3; forbidden_radius : float; var nearest_exit_point_tm : float3x4&) : bool
  var bestDistSq = VERY_BIG_NUMBER

  query() <| $ [es] (transform : float3x4; exit_point__accessibility_radius : float)
    let distSq = distance_sq(transform[3], pos)
    if distSq < square(exit_point__accessibility_radius) && distSq < bestDistSq && distSq > square(forbidden_radius)
      bestDistSq = distSq
      nearest_exit_point_tm = transform

  return bestDistSq < VERY_BIG_NUMBER

def private vehicle_teleport_entity_by_bounding_box(eid : EntityId; collres : CollisionResource; vehicle_tm : float3x4)
  let transform = get_TMatrix(eid, "transform")
  if transform == null
    return

  var requesterTm = *transform

  let vehicleBox = BBox3(collres.vFullBBox.bmin.xyz, collres.vFullBBox.bmax.xyz)

  var nearestExitPointTm : float3x4
  if vehicle_find_nearest_exit_point(requesterTm[3], length(vehicleBox.width) * 0.5, nearestExitPointTm)
    var exitPos = nearestExitPointTm[3]
    var t = 50.0
    if tracedown_normalized(exitPos, t, ETF_DEFAULT)
      exitPos.y -= (t - 0.25)

    nearestExitPointTm[3] = exitPos
    teleport_phys_actor(eid, nearestExitPointTm)
    return

  query(eid) <| $ [es] (var human_net_phys : HumanActor?)
    let additionalCollRad = 0.2
    let collRad = (human_net_phys != null ? human_net_phys.phys.collRad : 0.2) + additionalCollRad
    let vehicleLeft = vehicle_tm[2]
    let relativeVehicleTm = inverse(vehicle_tm) * requesterTm

    let existWishPos = [[float3[2]
      requesterTm[3] + sign(relativeVehicleTm[3].z) * 0.5 * (vehicleBox.width.z + collRad) * vehicleLeft;
      requesterTm[3] - sign(relativeVehicleTm[3].z) * 0.5 * (vehicleBox.width.z + collRad) * vehicleLeft ]]

    for i in range(0, 2)
      // Check left & right side
      var exitPos = existWishPos[i]
      if vehicle_trace_exit_pos(human_net_phys, exitPos, requesterTm)
        requesterTm[3] = exitPos
        teleport_phys_actor(eid, requesterTm)
        return



[es(tag=server)]
def vehicle_seats_enter_exit_kick_server_es(evt : CmdKickFromVehicle;
                                            eid : EntityId;
                                            animchar : AnimcharBaseComponent;
                                            transform : float3x4;
                                            collres : CollisionResource;
                                            vehicle_seats__seatEids : EidList;
                                            //vehicle_seats_hide_owner: BoolList;
                                            var last_driver : EntityId&;
                                            var last_driver_leave_time : float&)
  let requester = evt.eid

  let playerEid = get_Eid(requester, "possessedByPlr") ?? INVALID_ENTITY_ID
  if playerEid == INVALID_ENTITY_ID
    for seatNo, seatEid in iter_range(vehicle_seats__seatEids), vehicle_seats__seatEids
      query(seatEid) <| $ [es] (seat__component : int;
                                var seat__isPlayer : bool&;
                                var seat__ownerEid : EntityId&;
                                var seat__playerEid : EntityId&;
                                var seat__squadEid : EntityId&)
        if seat__ownerEid != requester
          return

        seat__isPlayer  = false
        seat__ownerEid  = INVALID_ENTITY_ID
        seat__playerEid = INVALID_ENTITY_ID
        seat__squadEid  = INVALID_ENTITY_ID

        detach_human_from_seat(requester, seat__component)

        vehicle_teleport_entity_by_bounding_box(requester, collres, transform)

        send_enter_vehicle_event(requester, eid, seatNo, false)
        sendEvent(requester, [[GainVehicleVelocity vehicleEid=eid]])
    return

  for seatNo, seatEid in iter_range(vehicle_seats__seatEids), vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__component : int;
                              seat__availableControls : VehicleControlsState;
                              seat__entranceNodeId : int;
                              var seat__isPlayer : bool&;
                              var seat__ownerEid : EntityId&;
                              var seat__playerEid : EntityId&;
                              var seat__squadEid : EntityId&)
      if seat__ownerEid != requester
        return

      seat__isPlayer  = false
      seat__ownerEid  = INVALID_ENTITY_ID
      seat__playerEid = INVALID_ENTITY_ID
      seat__squadEid  = INVALID_ENTITY_ID

      detach_human_from_seat(requester, seat__component)

      if seat__availableControls.canControlVehicle
        last_driver = requester
        last_driver_leave_time = get_sync_time()

      if seat__entranceNodeId >= 0
        if !vehicle_teleport_entity_to_node(requester, animchar.nodeTree, seat__entranceNodeId)
          var found = false
          for otherSeatEid in vehicle_seats__seatEids
            let otherOwnerEid = get_Eid(otherSeatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
            let otherEntranceNodeId = get_int(otherSeatEid, "seat__entranceNodeId") ?? -1
            if otherOwnerEid == requester
              continue
            if otherEntranceNodeId < 0
              continue
            if vehicle_teleport_entity_to_node(requester, animchar.nodeTree, otherEntranceNodeId)
              found = true
              break
          if !found
            vehicle_teleport_entity_to_node(requester, animchar.nodeTree, seat__entranceNodeId, /* forcibly */ true)
      else
        vehicle_teleport_entity_by_bounding_box(requester, collres, transform)

      send_enter_vehicle_event(requester, eid, seatNo, false)
      sendEvent(requester, [[GainVehicleVelocity vehicleEid=eid]])

