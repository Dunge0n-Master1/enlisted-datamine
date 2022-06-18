require ecs
require game.utils.team


def get_restrict_to_team(vehicle_seats__seatEids : EidList)
  var restrictToTeam = TEAM_UNASSIGNED
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId)
      query(seat__ownerEid) <| $ [es] (isAlive : bool = true; team : int = TEAM_UNASSIGNED)
        if isAlive
          restrictToTeam = team
    if restrictToTeam != TEAM_UNASSIGNED
      break
  return restrictToTeam

[es(tag=server, REQUIRE=squad_vehicle__canChangeTeam, on_appear)]
def vehicle_drop_team_restrictions_for_squad_vehicle(evt : Event; var vehicle_seats__autoDetectRestrictToTeam : bool&)
  vehicle_seats__autoDetectRestrictToTeam = true

[es(tag=server, on_event=EventOnSeatOwnersChanged)]
def vehicle_restrict_to_team_seat_owner_changed(evt : Event;
                                                vehicle_seats__seatEids : EidList;
                                                vehicle_seats__autoDetectRestrictToTeam : bool;
                                                var vehicle_seats__restrictToTeam : int&)
  if vehicle_seats__autoDetectRestrictToTeam
    vehicle_seats__restrictToTeam = get_restrict_to_team(vehicle_seats__seatEids)

[es(tag=server, on_event=EventEntityDied)]
def vehicle_restrict_to_team_seat_owner_death(evt : Event; human_anim__vehicleSelected : EntityId)
  query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList;
                                                vehicle_seats__autoDetectRestrictToTeam : bool;
                                                var vehicle_seats__restrictToTeam : int&)
    if vehicle_seats__autoDetectRestrictToTeam
      vehicle_seats__restrictToTeam = get_restrict_to_team(vehicle_seats__seatEids)


[es(tag=server, track=vehicle_seats__restrictToTeam, on_appear)]
def autodetect_team(evt : Event;
                    vehicle_seats__restrictToTeam : int;
                    vehicle_seats__autoDetectRestrictToTeam : bool;
                    var team : int&)
  if vehicle_seats__autoDetectRestrictToTeam
    team = vehicle_seats__restrictToTeam
