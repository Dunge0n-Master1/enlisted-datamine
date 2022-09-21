require ecs
require app
require vehicle
require DagorSystem
require game.es.vehicle.vehicle_events

[es(tag=server, REQUIRE=player)]
def cmd_use_vehicle_on_spawn_es(evt : CmdUseVehicleOnSpawn; eid : ecs::EntityId)
  ecs::query(evt.vehicle) <| $ [es] (vehicle_seats__seatEids : EidList)
    if evt.seatOrderNo >= length(vehicle_seats__seatEids)
      logerr("Seats order index is out of range ({evt.seatOrderNo} >= {length(vehicle_seats__seatEids)})")
      return

    var isPlayer = false
    let seatNo = get_int(vehicle_seats__seatEids[evt.seatOrderNo], "seats_order__seatNo") ?? -1
    ecs::query(evt.possessed) <| $ [es] (possessedByPlr : ecs::EntityId;
                                         var isInVehicle : bool&;
                                         var human_anim__vehicleSelected : ecs::EntityId&;
                                         var human_vehicle__occupiedSeatEid : ecs::EntityId&;
                                         var vehicle__lastEid : ecs::EntityId&;
                                         var vehicle__lastTime : float&)
      if seatNo >= 0
        human_vehicle__occupiedSeatEid = vehicle_seats__seatEids[seatNo]

      isPlayer = possessedByPlr != INVALID_ENTITY_ID
      isInVehicle = true
      human_anim__vehicleSelected = evt.vehicle
      vehicle__lastEid = evt.vehicle
      vehicle__lastTime = get_sync_time()

    if seatNo < 0
      return

    query(vehicle_seats__seatEids[seatNo]) <| $ [es] (seat__component : int;
                                                      var seat__isPlayer : bool&;
                                                      var seat__ownerEid : EntityId&;
                                                      var seat__playerEid : EntityId&;
                                                      var seat__squadEid : EntityId&)
      set(evt.possessed, "", uint(seat__component), true)

      seat__isPlayer = isPlayer
      seat__ownerEid = evt.possessed
      seat__playerEid = eid
      seat__squadEid = evt.squad
