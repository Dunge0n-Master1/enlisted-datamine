from "%enlSqGlob/ui_library.nut" import *

let vehicleState = require("%ui/hud/state/vehicle_seats.nut")
let indicatorCtor = require("%ui/hud/huds/vehicle_change_indicator.nut")

let totalTime = Computed(@() vehicleState.value.switchSeatsTotalTime ?? 0.0)
let startTime = Computed(@() vehicleState.value.switchSeatsTime ?? 0.0)
let endTime = Computed(@() startTime.value + vehicleState.value.switchSeatsTotalTime)

return indicatorCtor(endTime, totalTime, loc("vehicle/hint/change_seats", "Seat change"))