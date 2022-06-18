import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

local seatsOrder = null

let function getSeatsOrder() {
  if (seatsOrder)
    return seatsOrder

  let seatsOrderTpl = ecs.g_entity_mgr.getTemplateDB().getTemplateByName("vehicle_seats_order")
  seatsOrder = seatsOrderTpl?.getCompValNullable("vehicleSeatsOrder").getAll() ?? []
  return seatsOrder
}

let mkVehicleSeats = @(vehicleWatch) Computed(function() {
  let { gametemplate = null } = vehicleWatch.value
  if (!gametemplate)
    return []

  let vehicleTpl = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(gametemplate)
  let seats = vehicleTpl?.getCompValNullable("vehicle_seats__seats").getAll() ?? []
  let isSeatsSorted = vehicleTpl?.getCompValNullable("vehicle_seats__seatsProvideOrder") != null

  local sorted
  if (isSeatsSorted)
    sorted = seats
  else {
    sorted = []
    foreach (order in getSeatsOrder()) {
      let idx = seats.findindex(@(seat) seat?.name == order.name)
      if (idx != null)
        sorted.append(seats.remove(idx))
    }
    sorted = sorted.extend(seats)
  }

  return sorted.map(function(seat) {
    // FIXME workaround for absent vehicle seats localization at templates
    seat.locName <- seat?.locName ?? (seat?.name ? $"vehicle_seats/{seat.name}" : "unknown")
    return seat
  })
})

return mkVehicleSeats