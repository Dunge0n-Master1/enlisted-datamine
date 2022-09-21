from "%enlSqGlob/ui_library.nut" import *

let {switchSeatsEndTime, switchSeatsTotalTime} = require("%ui/hud/state/vehicle_change_seat_time.nut")
let indicatorCtor = require("%ui/hud/huds/vehicle_change_indicator.nut")

return indicatorCtor(switchSeatsEndTime, switchSeatsTotalTime, loc("vehicle/hint/change_seats", "Seat change"))