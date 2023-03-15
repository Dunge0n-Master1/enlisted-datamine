from "%enlSqGlob/ui_library.nut" import *

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor, titleTxtColor } = require("%enlSqGlob/ui/designConst.nut")
let { vehicleInfo } = require("%enlist/soldiers/model/state.nut")
let { curSoldiersDataList } = require("%enlist/soldiers/model/curSoldiersState.nut")
let mkVehicleSeats = require("%enlSqGlob/squad_vehicle_seats.nut")
let colorize = require("%ui/components/colorize.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontSmall)


let seatsOrderWatch = mkVehicleSeats(vehicleInfo)
let freeSeatsInVehicle = Computed(@() seatsOrderWatch.value.slice(curSoldiersDataList.value.len()))

let freeSeatsBlock = @() {
    watch = freeSeatsInVehicle
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = freeSeatsInVehicle.value.len() <= 0 ? null
      : loc("vehicle_seats/free", { seats = ", ".join(freeSeatsInVehicle.value.map(@(seat)
          colorize(titleTxtColor, loc(seat.locName)))) })
  }.__update(defTxtStyle)

return freeSeatsBlock

