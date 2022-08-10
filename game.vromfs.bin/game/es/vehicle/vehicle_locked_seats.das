require ecs
require game.es.vehicle.vehicle_seats_common
require game.es.vehicle.vehicle_events
require debug.logerr_once

[es(tag=server, on_appear)]
def vehicle_locked_seats_init(evt : Event;
                              seat__id : int;
                              seat__vehicleEid : EntityId;
                              var seat__lockSeats : IntList;
                              var seat__isLocked : bool&)
  query(seat__vehicleEid) <| $ [es] ([[shared_comp]] vehicle_seats__seats : Array)
    let seat = get_ecs_object(vehicle_seats__seats, seat__id)
    if seat == null
      return
    seat__isLocked = get_bool(seat, "locked") ?? false
    let lockedSeats = get_ecs_StringList(seat, "lockSeats")
    if lockedSeats != null
      for seatName in *lockedSeats
        let seatNo = find_seat_no(string(seatName), vehicle_seats__seats)
        if seatNo >= 0
          seat__lockSeats |> push(seatNo)
        else
          logerr_once("seat {seatName} cannot be locked (not found) for vehicle {getEntityTemplateName(seat__vehicleEid)}. Check lockSeats.")

def lock_seats(seat__lockSeats : IntList; vehicle_seats__seatEids : EidList)
  for seatNo in seat__lockSeats
    let seatEid = vehicle_seats__seatEids[seatNo]
    query(seatEid) <| $ [es] (var seat__isLocked : bool&)
      seat__isLocked = true

def unlock_seats(seat__lockSeats : IntList; vehicle_seats__seatEids : EidList)
  for seatNo in seat__lockSeats
    let seatEid = vehicle_seats__seatEids[seatNo]
    query(seatEid) <| $ [es] (var seat__isLocked : bool&)
      seat__isLocked = false

[es(tag=server, on_appear, track=seat__ownerEid)]
def vehicle_lock_seats_on_seat_owner_changed(evt : Event;
                                             seat__vehicleEid : EntityId;
                                             seat__ownerEid : EntityId;
                                             seat__lockSeats : IntList)
  query(seat__vehicleEid) <| $ [es] (vehicle_seats__seatEids : EidList)
    if !!seat__ownerEid
      lock_seats(seat__lockSeats, vehicle_seats__seatEids)
    else
      unlock_seats(seat__lockSeats, vehicle_seats__seatEids)

[es(tag=server, track=seat__isLocked)]
def vechicle_lock_seats_kick_owner(evt : Event;
                                   seat__ownerEid : EntityId;
                                   seat__vehicleEid : EntityId;
                                   seat__adjacentSeat : int;
                                   seat__id : int;
                                   seat__isLocked : bool)
  if seat__isLocked && !!seat__ownerEid
    if seat__adjacentSeat > -1
      sendEvent(seat__vehicleEid, [[CmdVehicleSwapSeats seatNo1=seat__id, seatNo2=seat__adjacentSeat]])
    else
      sendEvent(seat__vehicleEid, [[CmdKickFromVehicle eid=seat__ownerEid]])