require ecs
require game.es.vehicle.vehicle_events

def private is_vehicle_has_free_player_seats(vehicle_seats__seatEids : EidList)
  var found = false
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId; seats_order__canPlaceManually : bool)
      found ||= seats_order__canPlaceManually && !(get_bool(seat__ownerEid, "isAlive") ?? false)
  return found

[es(tag=gameClient, track=seat__ownerEid, REQUIRE=seat__ownerEid)]
def vehicle_seat_set_free_seats_es(evt : Event; seat__vehicleEid : EntityId)
  query() <| $ [es(REQUIRE=hero)] (human_anim__vehicleSelected : EntityId;
                                   human_use_object__selectedBuilding : EntityId;
                                   var selected_vehicle__hasFreeSeat : bool&)
    var selectedEid = human_anim__vehicleSelected
    if !selectedEid
      selectedEid = human_use_object__selectedBuilding
    if selectedEid == seat__vehicleEid
      query(seat__vehicleEid) <| $ [es] (vehicle_seats__seatEids : EidList)
        selected_vehicle__hasFreeSeat = is_vehicle_has_free_player_seats(vehicle_seats__seatEids)

[es(tag=gameClient, track=isAlive, REQUIRE=human, REQUIRE=isAlive)]
def human_vehicle_set_free_seats_on_die_es(evt : Event; human_anim__vehicleSelected aka first_human_anim__vehicleSelected : EntityId)
  query() <| $ [es(REQUIRE=hero)] (human_anim__vehicleSelected : EntityId;
                                   human_use_object__selectedBuilding : EntityId;
                                   var selected_vehicle__hasFreeSeat : bool&)
    var selectedEid = human_anim__vehicleSelected
    if !selectedEid
      selectedEid = human_use_object__selectedBuilding
    if first_human_anim__vehicleSelected != selectedEid
      return
    query(selectedEid) <| $ [es] (vehicle_seats__seatEids : EidList)
      selected_vehicle__hasFreeSeat = is_vehicle_has_free_player_seats(vehicle_seats__seatEids)

[es(tag=gameClient, track=(human_anim__vehicleSelected, human_use_object__selectedBuilding), REQUIRE=hero, on_appear)]
def human_vehicle_set_free_seats_es(evt : Event;
                                    human_anim__vehicleSelected : EntityId;
                                    human_use_object__selectedBuilding : EntityId;
                                    var selected_vehicle__hasFreeSeat : bool&)
  var selectedEid = human_anim__vehicleSelected
  if !selectedEid
    selectedEid = human_use_object__selectedBuilding
  selected_vehicle__hasFreeSeat = true // reset to default for hide hint
  query(selectedEid) <| $ [es] (vehicle_seats__seatEids : EidList)
    selected_vehicle__hasFreeSeat = is_vehicle_has_free_player_seats(vehicle_seats__seatEids)
