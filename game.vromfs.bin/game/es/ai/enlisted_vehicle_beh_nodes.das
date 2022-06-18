options always_export_initializer = true

require ecs
require math.base
require common_shooter.es.ai.beh_node_common
require DagorDataBlock
require BehNodes
require EnlistedWalkerai
require vehicle
require game.es.events


def can_bot_replace_seat_owner(owner_eid : EntityId)
  return !owner_eid || has(owner_eid, "deadEntity")

def can_take_adjacent_seat(seat_eid : EntityId)
  var res = false
  query(seat_eid) <| $ [es] (seat__ownerEid : EntityId)
    res = can_bot_replace_seat_owner(seat__ownerEid)
  return res

def find_vehicle_seat(seat_eids : EidList)
  var foundSeatNo = -1
  var isSeatWithControlFound = false
  for seatNo in iter_range(seat_eids)
    let seatEid = seat_eids[seatNo]
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId;
                              seat__availableControls : VehicleControlsState;
                              seat__isLocked : bool = false;
                              seat__adjacentSeat : int = -1)
      if !seat__isLocked && can_bot_replace_seat_owner(seat__ownerEid)
        if seat__adjacentSeat > -1 && !can_take_adjacent_seat(seat_eids[seat__adjacentSeat])
          return
        foundSeatNo = seatNo
        isSeatWithControlFound = seat__availableControls.canControlVehicleOrTurrets
    if isSeatWithControlFound
      break
  return foundSeatNo

[beh_node(name="findVehicle")]
class FindVehicleNode : BehNodeAdapter
  posParam : int = -1
  useVehicleDistanceSq : float = 25.0

  def override loadFromBlk(var data : DataBlock) : void
    let ownerEid = beh_tree_eid(owner)
    var ownerPos : float3
    query(ownerEid) <| $ [es] (transform : float3x4)
      ownerPos = transform[3]
    posParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "posParam", "wishPosition"), ownerPos)
    useVehicleDistanceSq = square(datablock_getReal(data, "useVehicleDistance", 5.0))

  def override update(dt : float) : EBehResult
    let ownerEid = beh_tree_eid(owner)
    var res = EBehResult ER_FAILED
    query(ownerEid) <| $ [es] (isInVehicle : bool = false;
                               transform : float3x4;
                               squad_member__squad : EntityId;
                               squad_member__orderType : int;
                               squad_member__orderUseEntity : EntityId;
                               squad_member__isPersonalOrder : bool)
      if isInVehicle
        return

      let ownerPos = transform[3]
      var vehicleEid = INVALID_ENTITY_ID

      if squad_member__isPersonalOrder && squad_member__orderType == int(SquadMateOrder ESMO_USE_VEHICLE)
        vehicleEid = squad_member__orderUseEntity

      if !vehicleEid
        query(squad_member__squad) <| $ [es] (squad__orderType : int;
                                              squad__orderUseEntity : EntityId;
                                              squad__leader : EntityId)
          if !squad_member__isPersonalOrder && squad__orderType == int(SquadOrder ESO_USE_VEHICLE)
            vehicleEid = squad__orderUseEntity
          elif squad__orderType == int(SquadOrder ESO_FOLLOW_ME) && squad_member__orderType == int(SquadMateOrder ESMO_NO_ORDER)
            vehicleEid = squad__leader |> get_Eid("human_anim__vehicleSelected") ?? INVALID_ENTITY_ID

      query(vehicleEid) <| $ [es] (transform : float3x4; vehicle_seats__seatEids : EidList)
        let seatNo = find_vehicle_seat(vehicle_seats__seatEids)
        if seatNo >= 0
          let vehiclePos = transform[3]
          if length_sq(ownerPos - vehiclePos) < useVehicleDistanceSq
            sendEvent(vehicleEid, [[CmdUseVehicle requester=ownerEid, seat_no=seatNo]])
            owner.blackBoard |> datablock_setPoint3(posParam, ownerPos)
          else
            owner.blackBoard |> datablock_setPoint3(posParam, vehiclePos)
        res = EBehResult ER_SUCCESS

    return res