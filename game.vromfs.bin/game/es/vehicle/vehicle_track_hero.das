require ecs
require ecs.common
require vehicle
require game.utils.hero
require game.es.vehicle.vehicle_seats_common
require enlisted.events_enlisted

[es(tag=gameClient)]
def vehicle_without_hero_es(evt : ParallelUpdateFrameDelayed)
  var heroVehicleEid = INVALID_ENTITY_ID
  find_query() <| $ [es(REQUIRE=hero)] (human_anim__vehicleSelected : EntityId)
    heroVehicleEid = human_anim__vehicleSelected
    return true

  query() <| $ [es(REQUIRE=heroVehicle)] (eid : EntityId)
    if eid != heroVehicleEid
      removeSubTemplate(eid, "vehicle_with_hero")

  if !!heroVehicleEid && !has(heroVehicleEid, "heroVehicle")
    addSubTemplate(heroVehicleEid, "vehicle_with_hero")

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