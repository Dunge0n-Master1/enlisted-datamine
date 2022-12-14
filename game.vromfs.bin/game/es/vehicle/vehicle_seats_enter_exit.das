require ecs
require game.es.events
require game.es.vehicle.vehicle_events
require game.es.vehicle.vehicle_seats_common
require game.utils.team
require danetlibs.native_dasevents.main.native_events
require matching

[es(REQUIRE_NOT=deadEntity)]
def vehicle_seats_es_enter_exit(evt : CmdUse;
                                eid : EntityId;
                                vehicle_seats__seatEids : EidList;
                                vehicle_seats__restrictToGroup : int64 = int64(INVALID_GROUP_ID);
                                vehicle_seats__exitTime : float = 0.f;
                                vehicle_seats__enterTime : float = 0.f;
                                vehicle_seats__restrictToTeam : int = TEAM_UNASSIGNED;
                                vehicle__isPlayerCanEnter = true;
                                vehicle__isPlayerCanExit = true)
  let requester = evt.requesterEid
  query(requester) <| $ [es] (team : int;
                              isInVehicle : bool;
                              squad_member__playerEid : EntityId;
                              human_vehicle__can_take_seat : bool = true;
                              human_use_object__lockVehicleUse : bool = false)
    if !isInVehicle && !vehicle__isPlayerCanEnter
      sendEvent(requester, [[CmdHeroLogEvent event="can_not_vehicle_use", text="hint/vehicle/lockUse"]])
      return

    let playerGroup = get_int64(squad_member__playerEid, "origGroupId") ?? int64(INVALID_GROUP_ID)
    if !can_use_vehicle(team, vehicle_seats__restrictToTeam, playerGroup, vehicle_seats__restrictToGroup)
      return

    if vehicle__isPlayerCanExit && find_seat_with_owner(requester, vehicle_seats__seatEids) >= 0
      exit_vehicle(requester, eid, vehicle_seats__exitTime)
    elif vehicle__isPlayerCanEnter && human_vehicle__can_take_seat && !human_use_object__lockVehicleUse
      enter_vehicle(requester, eid, vehicle_seats__seatEids, vehicle_seats__enterTime)

[es(REQUIRE=vehicle_seats__seats)]
def vehicle_seats_use_req(evt : CmdUseVehicle; eid : EntityId)
  let requester = evt.requester
  let seatNo = evt.seat_no
  if (seatNo >= 0)
    sendEvent(eid, [[CmdAcquireVehicleSeat requester=requester, seat_no=seatNo]])

[es(on_event=EventEntityDied)]
def vehicle_seats_client_exit_on_die_es(evt : Event; eid : EntityId; isInVehicle : bool)
  if isInVehicle
    cancel_exit_timer(eid)
