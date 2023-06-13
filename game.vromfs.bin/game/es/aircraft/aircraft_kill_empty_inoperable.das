require ecs
require Plane
require DngPlane
require game.es.vehicle.vehicle_seats_common

[es(tag=server, REQUIRE=(airplane, deadIfNoCrewLeft),
    on_appear, on_event=EventOnSeatOwnersChanged,
    track=(plane_landing__isLanded, aircraft__isCapableOfTakeOffAndFly))]
def destroy_empty_plane(evt : Event;
                        plane_landing__isLanded : bool;
                        plane_landing__landedTime : float;
                        aircraft__isCapableOfTakeOffAndFly : bool;
                        vehicle_seats__seatEids : EidList;
                        var kill_empty_vehicle__hadCrewBefore : bool&;
                        var isAlive : bool&)
  let hasAliveCrew = is_vehicle_with_alive_crew(vehicle_seats__seatEids)
  if !kill_empty_vehicle__hadCrewBefore
    kill_empty_vehicle__hadCrewBefore ||= hasAliveCrew
    return
  assume isLanding = plane_landing__landedTime > 0.
  let isCrashLanded = !aircraft__isCapableOfTakeOffAndFly && plane_landing__isLanded
  if isAlive && !hasAliveCrew && (!isLanding || isCrashLanded)
    isAlive = false
