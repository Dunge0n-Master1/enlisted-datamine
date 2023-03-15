options always_export_initializer = true

require ecs
require DagorDataBlock
require BehNodes
require game.es.events
require game.es.vehicle.vehicle_seats_common
require math.base
require CollRes

[beh_node(name="useVehicle")]
class UseVehicle : BehNodeAdapter
  targetUnitParam : int = -1

  def override loadFromBlk(var data : DataBlock) : void
    targetUnitParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "targetUnitParam", "vehicleEid"), 0)

  def override update(dt : float) : EBehResult
    var res = EBehResult ER_FAILED

    query(beh_tree_eid(owner)) <| $ [es] (isInVehicle : bool; human_use_object__useDist : float; transform aka walker_transform : float3x4)
      if isInVehicle
        res = EBehResult ER_SUCCESS
        return

      let vehicleEid = EntityId(uint(owner.blackBoard |> datablock_getInt(targetUnitParam)))

      query(vehicleEid) <| $ [es] (vehicle_seats__seatEids : EidList; transform aka vehicle_transform : float3x4; collres : CollisionResource)
        if distance_sq(walker_transform[3], vehicle_transform[3]) > square(human_use_object__useDist + collres.boundingSphere.r)
          return
        let seatNo = find_vehicle_seat_for_bot(vehicle_seats__seatEids)
        if seatNo >= 0
          sendEvent(vehicleEid, [[CmdUseVehicle requester=beh_tree_eid(owner), seat_no=seatNo]])
          res = EBehResult ER_SUCCESS

    return res