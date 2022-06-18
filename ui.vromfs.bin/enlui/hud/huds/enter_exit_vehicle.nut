from "%enlSqGlob/ui_library.nut" import *

let {enterVehicleState, exitVehicleState} = require("%ui/hud/state/enter_exit_vehicle.nut")
let indicatorCtor = require("%ui/hud/huds/vehicle_change_indicator.nut")

let enterTotalTime = Computed(@() enterVehicleState.value?.enterTotalTime ?? 0.0)
let enterStartTime = Computed(@() enterVehicleState.value?.enterStartTime ?? 0.0)
let enterEndTime = Computed(@() enterStartTime.value + enterTotalTime.value)

let exitTotalTime = Computed(@() exitVehicleState.value?.exitTotalTime ?? 0.0)
let exitStartTime = Computed(@() exitVehicleState.value?.exitStartTime ?? 0.0)
let exitEndTime = Computed(@() exitStartTime.value + exitTotalTime.value)

return {
  enterVehicleIndicator = indicatorCtor(enterEndTime, enterTotalTime, loc("vehicle/hint/enter", "Enter"))
  exitVehicleIndicator = indicatorCtor(exitEndTime, exitTotalTime, loc("vehicle/hint/exit", "Exit"))
}