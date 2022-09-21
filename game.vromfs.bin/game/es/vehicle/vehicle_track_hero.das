require ecs
require ecs.common
require vehicle
require game.utils.hero
require game.es.vehicle.vehicle_seats_common
require enlisted.events_enlisted


[es(on_appear, on_event=(EventHeroChanged, EventOnSeatOwnersChanged), tag=gameClient, REQUIRE_NOT=heroVehicle)]
def vehicle_without_hero_es(evt : Event; eid : EntityId; vehicle_seats__seatEids : EidList)
  if is_hero_in_vehicle(vehicle_seats__seatEids)
    // If new vehicle was created while our hero was in some other vehicle
    // then this comes in before vehicle_with_hero_es, so we must remove
    // vehicle_with_hero template here because we need to make sure that there're never
    // two vehicles with heroVehicle at any point in time.
    // Note that es order / es separation won't help here, since these are triggered by different events.
    query() <| $ [es(REQUIRE=heroVehicle)] (eid : EntityId)
      removeSubTemplate(eid, "vehicle_with_hero")
    addSubTemplate(eid, "vehicle_with_hero")


[es(on_appear, on_event=(EventHeroChanged, EventOnSeatOwnersChanged), tag=gameClient, REQUIRE=heroVehicle)]
def vehicle_with_hero_es(evt : Event; eid : EntityId; vehicle_seats__seatEids : EidList)
  if !is_hero_in_vehicle(vehicle_seats__seatEids)
    removeSubTemplate(eid, "vehicle_with_hero")

[es(tag=gameClient)]
def vehicle_with_watched(evt : ParallelUpdateFrameDelayed)
  var watchedByPlrVehicleEid = INVALID_ENTITY_ID
  find_query() <| $ [es(REQUIRE=watchedByPlr)] (human_anim__vehicleSelected : EntityId)
    watchedByPlrVehicleEid = human_anim__vehicleSelected
    return true

  query() <| $ [es(REQUIRE=vehicleWithWatched)] (eid : EntityId)
    if eid != watchedByPlrVehicleEid
      removeSubTemplate(eid, "vehicle_with_watched")

  if !!watchedByPlrVehicleEid && !has(watchedByPlrVehicleEid, "vehicleWithWatched")
    addSubTemplate(watchedByPlrVehicleEid, "vehicle_with_watched")