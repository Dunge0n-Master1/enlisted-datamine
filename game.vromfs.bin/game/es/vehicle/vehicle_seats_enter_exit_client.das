require ecs
require game.es.events
require game.es.vehicle.vehicle_seats_common
require game.utils.team
require matching

[es(tag=gameClient)]
def vehicle_seats_client_enter_exit_request(evt : HumanUseObjectRequest;
                                            possessedByPlr : EntityId;
                                            eid : EntityId;
                                            squad_member__playerEid : EntityId = INVALID_ENTITY_ID;
                                            human_vehicle__can_take_seat : bool = true;
                                            team : int = TEAM_UNASSIGNED)
  let requester = eid
  query(evt.objectEid) <| $ [es(REQUIRE_NOT=deadEntity)] (eid : EntityId;
                                                          vehicle_seats__seatEids : EidList;
                                                          vehicle_seats__restrictToGroup : int64 = int64(INVALID_GROUP_ID);
                                                          vehicle_seats__enterTime : float = 0.f;
                                                          vehicle_seats__exitTime : float = 0.f;
                                                          vehicle__isPlayerCanEnter : bool = true;
                                                          vehicle_seats__restrictToTeam : int = TEAM_UNASSIGNED)
    let playerGroup = get_int64(squad_member__playerEid, "origGroupId") ?? int64(INVALID_GROUP_ID)
    if !can_use_vehicle(team, vehicle_seats__restrictToTeam, playerGroup, vehicle_seats__restrictToGroup)
      return

    if find_seat_with_owner(requester, vehicle_seats__seatEids) >= 0
      if !cancel_exit_timer(requester)
        start_exit_vehicle_timer(requester, vehicle_seats__exitTime)
    elif vehicle__isPlayerCanEnter && human_vehicle__can_take_seat && find_highest_free_seat(possessedByPlr, vehicle_seats__seatEids) >= 0
      start_enter_vehicle_timer(requester, eid, vehicle_seats__enterTime)
