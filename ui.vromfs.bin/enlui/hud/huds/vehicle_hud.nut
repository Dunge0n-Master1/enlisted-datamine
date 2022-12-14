from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { gear, neutralGear, rpm, cruiseControl, speed, isAutomaticTransmission
} = require("%ui/hud/state/vehicle_view_state.nut")
let { inTank, isVehicleAlive } = require("%ui/hud/state/vehicle_state.nut")

let mkText = @(txt) {
  rendObj = ROBJ_TEXT
  text = txt
  padding = [0, hdpx(2)]
  minHeight = fsh(2)
  valign = ALIGN_BOTTOM
}.__update(sub_txt)

let mkLabel = @(txt) mkText(txt).__update({ minWidth = fsh(4) })

const CRUISE_CONTROL_MAX = 3

let function mkGear(g, neutral) {
  return g < neutral ? $"{loc("vehicle_hud/GearR")}{neutral-g}"
    : g == neutral ? loc("vehicle_hud/GearN")
    : $"{g-neutral}"
}

let mkCruiseControl = @(cc) cc < 0 ? loc("vehicle_hud/CcR")
  : cc >= CRUISE_CONTROL_MAX ? loc("vehicle_hud/CcMax")
  : $"{cc}"

let vehicleGearInfo = @() {
  watch = [gear, neutralGear]
  flow = FLOW_HORIZONTAL
  children = [
    mkLabel(loc("vehicle_hud/Gear"))
    mkText(mkGear(gear.value, neutralGear.value))
  ]
}

let vehicleRpmInfo = @() {
  watch = rpm
  flow = FLOW_HORIZONTAL
  children = [
    mkLabel(loc("vehicle_hud/Rpm"))
    mkText($"{rpm.value}")
  ]
}

let vehicleSpeedInfo = @() {
  watch = speed
  flow = FLOW_HORIZONTAL
  children = [
    mkLabel(loc("vehicle_hud/Spd"))
    mkText($"{speed.value} {loc("vehicle_hud/Kmh")}")
  ]
}

let vehicleTransmissionInfo = @() {
  watch = [isAutomaticTransmission, cruiseControl]
  flow = FLOW_HORIZONTAL
  children = !isAutomaticTransmission.value
    ? null
    : [
        mkLabel(loc("vehicle_hud/Cc"))
        mkText(mkCruiseControl(cruiseControl.value))
      ]
}

let vehicleHudComponents = [
  vehicleGearInfo
  vehicleRpmInfo
  vehicleSpeedInfo
  vehicleTransmissionInfo
]

return @() {
  flow = FLOW_VERTICAL
  watch = [inTank, isVehicleAlive]
  children = !inTank.value || !isVehicleAlive.value ? null : vehicleHudComponents
}