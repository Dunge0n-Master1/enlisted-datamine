require ecs
require DngNet
require enlisted.events_enlisted
require game.es.vehicle.vehicle_events
require game.es.vehicle.vehicle_seats_common

[es(tag=gameClient)]
def vehicle_change_leader_requester(evt : CmdVehiclePlaceSeat; vehicle_seats__seatEids : EidList)
  let sitterEid = evt.eid
  let seatOrderNo = evt.seat
  if uint(seatOrderNo) >= uint(length(vehicle_seats__seatEids))
    return
  let seatNo = get_int(vehicle_seats__seatEids[seatOrderNo], "seats_order__seatNo") ?? -1
  if uint(seatNo) >= uint(length(vehicle_seats__seatEids))
    return
  let seatEid = vehicle_seats__seatEids[seatNo]
  let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
  let playerEid = get_Eid(seatEid, "seat__playerEid") ?? INVALID_ENTITY_ID
  if (playerEid == (get_Eid(sitterEid, "possessedByPlr") ?? INVALID_ENTITY_ID) && (get_bool(ownerEid, "isAlive") ?? false))
    let squadEid = get_Eid(sitterEid, "squad_member__squad") ?? INVALID_ENTITY_ID
    send_net_event(squadEid, [[RequestSquadChangeLeader eid=ownerEid]])

[es(tag=server, before=vehicle_seats_stop_switch_timer_if_occupied)]
def vehicle_seats_switch_timer_replace_squad_mate(evt : EventEnterVehicle; vehicle_seats__seatEids : EidList)
  if !evt.enter
    return
  let incomerIndex = find_seat_with_owner(evt.incomer, vehicle_seats__seatEids)
  if incomerIndex < 0
    return
  let incomerSeatOwnerEid = get_Eid(vehicle_seats__seatEids[incomerIndex], "seat__ownerEid") ?? INVALID_ENTITY_ID
  let incomerSeatPlayerEid = get_Eid(vehicle_seats__seatEids[incomerIndex], "seat__playerEid") ?? INVALID_ENTITY_ID
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId; seats_switch_time__newSeatNo : int)
      if seats_switch_time__newSeatNo != incomerIndex
        return
      let awaitingChangeEid = seat__ownerEid
      if incomerSeatPlayerEid == (get_Eid(awaitingChangeEid, "possessedByPlr") ?? INVALID_ENTITY_ID)
        let squadEid = get_Eid(awaitingChangeEid, "squad_member__squad") ?? INVALID_ENTITY_ID
        sendEvent(squadEid, [[CmdSwitchSquadLeader eid=incomerSeatOwnerEid]])