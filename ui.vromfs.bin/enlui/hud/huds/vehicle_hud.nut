from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { gear, neutralGear, rpm, cruiseControl, speed, isAutomaticTransmission } = require("%ui/hud/state/vehicle_view_state.nut")
let { inTank, isVehicleAlive } = require("%ui/hud/state/vehicle_state.nut")

let mkText = @(txt) {
  rendObj = ROBJ_TEXT
  text = txt
  padding = [0,hdpx(2),0,hdpx(2)]
  minHeight = fsh(2)
  valign = ALIGN_BOTTOM
}.__update(sub_txt)

let mkLabel = @(txt) mkText(txt).__update({ minWidth = fsh(4) })

let mkRow = @(children) {
  children = children
  flow = FLOW_HORIZONTAL
}

const CRUISE_CONTROL_MAX = 3

let function mkGear(g, neutral){
  let rStr = loc("vehicle_hud/GearR")
  let nStr = loc("vehicle_hud/GearN")
  return g < neutral ? $"{rStr}{neutral-g}" : g == neutral ? nStr : $"{g-neutral}"
}

let mkCruiseControl = @(cc) cc < 0 ? loc("vehicle_hud/CcR")
  : cc >= CRUISE_CONTROL_MAX ? loc("vehicle_hud/CcMax") : $"{cc}"

return function() {
  let kmhStr = loc("vehicle_hud/Kmh")
  return {
    flow = FLOW_VERTICAL
    watch = [gear, rpm, cruiseControl, speed, isAutomaticTransmission, inTank]
    children = (!inTank.value || !isVehicleAlive.value) ? null : [
      mkRow([mkLabel(loc("vehicle_hud/Gear")), mkText(mkGear(gear.value, neutralGear.value))])
      mkRow([mkLabel(loc("vehicle_hud/Rpm")),  mkText($"{rpm.value}")])
      mkRow([mkLabel(loc("vehicle_hud/Spd")),  mkText($"{speed.value} {kmhStr}")])
      isAutomaticTransmission.value
        ? mkRow([mkLabel(loc("vehicle_hud/Cc")), mkText(mkCruiseControl(cruiseControl.value))])
        : null
    ]
  }
}