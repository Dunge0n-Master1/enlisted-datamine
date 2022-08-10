import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let armyData = require("%ui/hud/state/armyData.nut")

let function getCrewCount(template) {
  let gametemplate = template == null ? null
    : ecs.g_entity_mgr.getTemplateDB().getTemplateByName(template)
  if (gametemplate == null)
    return 0
  return gametemplate.getCompValNullable("vehicle_seats__seats")?.len() ?? 0
}

let function collectVehicleData(vehicle, armyId, squadId, country) {
  let res = {}
  foreach (key in ["guid", "gametemplate"])
    res[key] <- vehicle[key]

  return res.__update({
    armyId = armyId
    squadId = squadId
    country = country
    crew = getCrewCount(vehicle.gametemplate)
  })
}

let vehicles = Computed(function() {
  let res = {}
  let squadsList = armyData.value?.squads
  if (squadsList == null)
    return res

  let armyId = armyData.value.armyId
  let country = armyData.value.country
  foreach (squad in squadsList) {
    let vehicle = squad?.curVehicle
    if (vehicle != null)
      res[vehicle.guid] <- collectVehicleData(vehicle, armyId, squad.squadId, country)
  }
  return res
})

return vehicles