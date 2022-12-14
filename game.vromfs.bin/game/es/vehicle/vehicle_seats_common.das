module vehicle_seats_common shared
require ecs
require ecs.common
require DagorMath
require player
require vehicle
require game.utils.hero
require app
require EnlistedNet
require math.base
require Grid
require GridCollision
require game.es.events
require game.es.vehicle.vehicle_events
require game.utils.net_utils
require HumanPhys
require game.utils.team
require matching

enum VehicleControlTypes : uint8
  VEHICLE_CONTROLS_MOVEMENT = 1 << 0
  VEHICLE_CONTROLS_TURRETS = 1 << 1
  VEHICLE_CONTROLS_CAMERA = 1 << 2

def find_seat_with_owner(owner_eid, seat_eids)
  if !owner_eid
    return -1
  return find_index_if(each(seat_eids)) <| $(seatEid) : bool
    return (get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID) == owner_eid

def find_seat_eid_with_owner(owner_eid, seat_eids) : EntityId
  let seatNo = find_seat_with_owner(owner_eid, seat_eids)
  return uint(seatNo) >= uint(length(seat_eids)) ? INVALID_ENTITY_ID : seat_eids[seatNo]


def find_seat_no(name : string; seats : ecs::Array) : int
  if name == ""
    return -1
  for seatNo in iter_range(seats)
    let seat = get_ecs_object(seats[seatNo])
    if get_string(seat, "name", "") == name
      return seatNo
  return -1

def find_next_seat_no(name : string; seats : ecs::Array; var nextSeatNo : int&) : bool
  if name == ""
    return false
  if nextSeatNo >= length(seats)
    return false
  if nextSeatNo < 0
    nextSeatNo = -1
  for seatNo in range(nextSeatNo + 1, length(seats))
    let seat = get_ecs_object(seats[seatNo])
    if get_string(seat, "name", "") == name
      nextSeatNo = seatNo
      return true
  nextSeatNo = length(seats)
  return false


def vehicle_get_hero_seat_idx(seat_eids)
  return find_seat_with_owner(get_controlled_hero(), seat_eids)

def vehicle_get_watched_seat_idx(seat_eids : EidList) : int
  return find_seat_with_owner(get_watched_entity(), seat_eids)

def is_hero_in_vehicle(vehicle_seats__seatEids : EidList) : bool
  return vehicle_get_hero_seat_idx(vehicle_seats__seatEids) != -1

def is_watched_in_vehicle(vehicle_seats__seatEids : EidList) : bool
  return vehicle_get_watched_seat_idx(vehicle_seats__seatEids) != -1

def find_seat_order_no(seat_no : int; vehicle_seats__seatEids : EidList) : int
  var seatOrderNo = -1
  for seatNo, seatEid in iter_range(vehicle_seats__seatEids), vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seats_order__seatNo : int)
      if seats_order__seatNo == seat_no
        seatOrderNo = seatNo
  return seatOrderNo

def is_vehicle_with_crew(vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    if !!ownerEid
      return true
  return false

def is_vehicle_with_crew(vehicle_eid : EntityId)
  var isCrew = false
  query(vehicle_eid) <| $ [es] (vehicle_seats__seatEids : EidList)
    isCrew = is_vehicle_with_crew(vehicle_seats__seatEids)
  return isCrew

def is_vehicle_with_alive_crew(vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    if get_bool(seatEid, "seat__isOwnerAlive") ?? false
      return true
  return false

def is_vehicle_with_alive_crew(vehicle_eid : EntityId)
  var isAliveCrew = false
  query(vehicle_eid) <| $ [es] (vehicle_seats__seatEids : EidList)
    isAliveCrew = is_vehicle_with_alive_crew(vehicle_seats__seatEids)
  return isAliveCrew

def start_enter_vehicle_timer(requester : EntityId; vehicle : EntityId; enter_time : float) : bool
  if enter_time <= 0.f
    return false
  var timerStarted = false
  query(requester) <| $ [es] (possessedByPlr : EntityId;
                              var enter_vehicle__atTime : float&;
                              var enter_vehicle__vehicleEid : EntityId?;
                              entity_mods__vehicleChangeSeatTimeMult : float = 1.0)
    if !possessedByPlr
      return
    timerStarted = true
    let atTime = get_sync_time()
    if enter_vehicle__atTime > atTime
      return
    enter_vehicle__atTime = atTime + enter_time * entity_mods__vehicleChangeSeatTimeMult
    if enter_vehicle__vehicleEid != null
      *enter_vehicle__vehicleEid = vehicle
  return timerStarted

def kick_from_vehicle(eid : EntityId; vehicle_eid : EntityId; vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    if get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID == eid
      sendEventImmediate(vehicle_eid, [[CmdKickFromVehicle eid=eid]])
      break

def kick_all_from_vehicle(vehicle_eid : EntityId; vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    if !!ownerEid
      sendEventImmediate(vehicle_eid, [[CmdKickFromVehicle eid=ownerEid]])

def find_highest_free_seat(player : EntityId; vehicle_seats__seatEids : EidList) : int
  var res = -1
  for orderSeatEid in vehicle_seats__seatEids
    let orderSeatNo = get_int(orderSeatEid, "seats_order__seatNo") ?? -1
    if orderSeatNo < 0
      continue
    let seatEid = vehicle_seats__seatEids[orderSeatNo]
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId = INVALID_ENTITY_ID;
                              seat__playerEid : EntityId = INVALID_ENTITY_ID;
                              seats_order__canPlaceManually : bool = true;
                              seat__isLocked : bool = false;
                              seat__adjacentSeat : int = -1)
      var canEnter = (!seat__isLocked && seats_order__canPlaceManually &&
        ((seat__ownerEid == INVALID_ENTITY_ID) ||
         (seat__playerEid == player) ||
         !(get_bool(seat__ownerEid, "isAlive") ?? true)))

      if canEnter && seat__adjacentSeat > -1
        let adjacentSeatEid = vehicle_seats__seatEids[seat__adjacentSeat]
        query(adjacentSeatEid) <| $ [es] (seat__ownerEid : EntityId)
          canEnter = seat__ownerEid == INVALID_ENTITY_ID || !(get_bool(seat__ownerEid, "isAlive") ?? true)

      if canEnter
        res = orderSeatNo
        return
    if res != -1
      break
  return res

def enter_vehicle_now(requester : EntityId; vehicle : EntityId; requestSeatNo : int)
  if !is_server()
    return
  query(vehicle) <| $ [es] (vehicle_seats__seatEids : EidList)
    let seatEid = vehicle_seats__seatEids[requestSeatNo]
    let curOwner = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    if !(get_bool(curOwner, "isAlive") ?? true)
      kick_from_vehicle(curOwner, vehicle, vehicle_seats__seatEids)
    sendEvent(vehicle, [[CmdAcquireVehicleSeat requester=requester, seat_no=requestSeatNo]])

def enter_vehicle(requester : EntityId; vehicle : EntityId; vehicle_seats__seatEids : EidList; enter_time : float)
  let playerEid = get_Eid(requester, "possessedByPlr") ?? INVALID_ENTITY_ID
  let requestSeatNo = find_highest_free_seat(playerEid, vehicle_seats__seatEids)
  if requestSeatNo < 0
    return
  if !start_enter_vehicle_timer(requester, vehicle, enter_time)
    enter_vehicle_now(requester, vehicle, requestSeatNo)

def cancel_exit_timer(requester : EntityId) : bool
  var res = true
  query(requester) <| $ [es] (var exit_vehicle__atTime : float?)
    if exit_vehicle__atTime == null || *exit_vehicle__atTime < get_sync_time()
      res = false
      return
    *exit_vehicle__atTime = -1.f
  return res

def start_exit_vehicle_timer(requester : EntityId; exit_time : float) : bool
  if exit_time <= 0.f
    return false
  var timerStarted = false
  query(requester) <| $ [es] (possessedByPlr : EntityId;
                              var exit_vehicle__atTime : float&;
                              entity_mods__vehicleChangeSeatTimeMult : float = 1.0)
    if !possessedByPlr
      return
    exit_vehicle__atTime = get_sync_time() + exit_time * entity_mods__vehicleChangeSeatTimeMult
    timerStarted = true
  return timerStarted

def exit_vehicle_now(requester : EntityId; vehicle : EntityId)
  if is_server()
    sendEvent(vehicle, [[CmdKickFromVehicle eid=requester]])

def exit_vehicle(requester : EntityId; vehicle : EntityId; exit_time : float)
  if cancel_exit_timer(requester)
    return
  if !start_exit_vehicle_timer(requester, exit_time)
    exit_vehicle_now(requester, vehicle)

def vehicle_has_owner_around(vehiclePos : float3; ownedBySquad : EntityId; distance : float) : bool
  return !!find_entity_in_grid(ecs_hash("humans"), BSphere3(vehiclePos, distance), GridEntCheck BOUNDING) <| $(humanEid : EntityId)
    var found = false
    ecs::query(humanEid) <| $ [es(REQUIRE_NOT=deadEntity)] (squad_member__squad : ecs::EntityId)
      found = ownedBySquad == squad_member__squad
    return found

def is_vehicle_contain_owner(ownerEid : EntityId;
                             vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    if ownerEid == get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
      return true
  return false

def send_enter_vehicle_event(incomer : EntityId; vehicle : EntityId; seat_no : int; enter : bool)
  let recipients <- target_entity_pos_range(vehicle)
  send_net_event(incomer, [[EventEnterVehicle incomer=incomer, vehicle=vehicle, seat_no=seat_no, enter=enter]], recipients)
  send_net_event(vehicle, [[EventEnterVehicle incomer=incomer, vehicle=vehicle, seat_no=seat_no, enter=enter]], recipients)

def can_bot_replace_seat_owner(owner_eid : EntityId)
  return !owner_eid || has(owner_eid, "deadEntity")

def can_take_adjacent_seat(seat_eid : EntityId)
  var res = false
  query(seat_eid) <| $ [es] (seat__ownerEid : EntityId)
    res = can_bot_replace_seat_owner(seat__ownerEid)
  return res

def find_vehicle_seat_for_bot(seat_eids : EidList)
  var foundSeatNo = -1
  var isSeatWithControlFound = false
  for seatNo in iter_range(seat_eids)
    let seatEid = seat_eids[seatNo]
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId;
                              seat__availableControls : VehicleControlsState;
                              seats_order__notForBots : bool = false;
                              seat__isLocked : bool = false;
                              seat__adjacentSeat : int = -1)
      if !seat__isLocked && !seats_order__notForBots && can_bot_replace_seat_owner(seat__ownerEid)
        if seat__adjacentSeat > -1 && !can_take_adjacent_seat(seat_eids[seat__adjacentSeat])
          return
        foundSeatNo = seatNo
        isSeatWithControlFound = seat__availableControls.canControlVehicleOrTurrets
    if isSeatWithControlFound
      break
  return foundSeatNo

def is_gun_slot_allowed_to_hold_gun_in_hatch(slot : int)
  return slot < int(HUWeaponSlots EWS_MELEE) || slot == int(HUWeaponSlots EWS_GRENADE)

def get_vehicle_driver(seat_eids : EidList)
  var res = INVALID_ENTITY_ID
  var found = false
  for seatEid in seat_eids
    query(seatEid) <| $ [es] (seat__availableControls : VehicleControlsState; seat__ownerEid : EntityId)
      if seat__availableControls.canControlVehicle
        res = seat__ownerEid
        found = true
    if found
      break
  return res

def get_vehicle_driver(vehicle_eid : EntityId)
  var res = INVALID_ENTITY_ID
  query(vehicle_eid) <| $ [es] (vehicle_seats__seatEids : EidList)
    res = get_vehicle_driver(vehicle_seats__seatEids)
  return res

def get_last_vehicle_driver(vehicle_eid : EntityId; max_time_after_leave : float)
  var driver = get_vehicle_driver(vehicle_eid)
  if !driver
    query(vehicle_eid) <| $ [es] (last_driver : EntityId = INVALID_ENTITY_ID; last_driver_leave_time : float = 0.)
      if !!last_driver && (get_sync_time() - last_driver_leave_time < max_time_after_leave)
        driver = last_driver
  return driver

def get_last_vehicle_driver_possessed_by_player(vehicle_eid : EntityId; max_time_after_leave : float)
  let driver = get_last_vehicle_driver(vehicle_eid, max_time_after_leave)
  var res = INVALID_ENTITY_ID
  query(driver) <| $ [es] (possessedByPlr : EntityId = INVALID_ENTITY_ID; squad_member__squad : EntityId = INVALID_ENTITY_ID)
    res = !!possessedByPlr ? driver : get_Eid(squad_member__squad, "squad__leader") ?? INVALID_ENTITY_ID
  return res

def can_use_vehicle(player_team : int; restrict_to_team : int; player_group : int64; vehicle_group : int64)
  return ((restrict_to_team == TEAM_UNASSIGNED || is_teams_friendly(player_team, restrict_to_team)) &&
    (vehicle_group == int64(INVALID_GROUP_ID) || player_group == vehicle_group))
