from "%enlSqGlob/ui_library.nut" import *

let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let {DEFAULT_TEXT_COLOR, FAIL_TEXT_COLOR} = require("%ui/hud/style.nut")
let {vehicleEngineBroken, vehicleTransmissionBroken, vehicleTracksBroken, vehicleWheelsBroken,
  vehicleTurretHorDriveBroken, vehicleTurretVerDriveBroken, vehiclePartDamaged
} = require("%ui/hud/state/vehicle_damage_state.nut")
let {inVehicle, isVehicleAlive,
  isHighSpeedWarningEnabled, isFlapsCritical, isOverloadCritical} = require("%ui/hud/state/vehicle_state.nut")
  let { isAlive } = require("%ui/hud/state/health_state.nut")
let {implode} = require("%sqstd/string.nut")
let { isTutorial } = require("%ui/hud/tutorial/state/tutorial_state.nut")

let vehicleCantMoveWarnings = [
  {state = vehicleEngineBroken, text = @() loc("hud/engine_broken", "engine broken")}
  {state = vehicleTransmissionBroken, text = @() loc("hud/transmission_broken", "transmission broken")}
  {state = vehicleTracksBroken, text = @() loc("hud/tracks_broken", "tracks broken")}
  {state = vehicleWheelsBroken, text = @() loc("hud/wheels_broken", "wheels broken")}
]

let vehicleTurretDriveWarnings = [
  {state = vehicleTurretHorDriveBroken, text = @() loc("hud/turret_hor_drive_broken", "horizontal drive broken")}
  {state = vehicleTurretVerDriveBroken, text = @() loc("hud/turret_ver_drive_broken", "vertical drive broken")}
]

let showVehicleWarnings = Computed(@() inVehicle.value && isVehicleAlive.value && isAlive.value)

let watch = [ showVehicleWarnings, vehiclePartDamaged, isHighSpeedWarningEnabled, isFlapsCritical, isOverloadCritical, isTutorial ]
  .extend(vehicleCantMoveWarnings.map(@(w) w.state), vehicleTurretDriveWarnings.map(@(w) w.state))

let function mkTip(warnings, msgKey, msgDefVal) {
  let reasons = warnings.filter(@(w) w.state.value).map(@(w) w.text())
  let text = reasons.len() > 0 ? loc(msgKey, msgDefVal, {reason = implode(reasons, ", ")}) : null
  return tipCmp({
    text
    textColor = DEFAULT_TEXT_COLOR
  })
}

return function () {
  let children = []

  if (showVehicleWarnings.value) {
    children.append(mkTip(vehicleCantMoveWarnings, "hud/vehicle_cant_move", "Vehicle can't move: {reason}")) //warning disable: -forgot-subst
    children.append(mkTip(vehicleTurretDriveWarnings, "hud/vehicle_turret_cant_move", "Vehicle turret can't move: {reason}")) //warning disable: -forgot-subst
    children.append(tipCmp({
      text = (isTutorial.value ? vehicleTracksBroken.value : vehiclePartDamaged.value)
        ? loc("hud/vehicle_part_damaged_warning", "A part of the vehicle is damaged, go out to fix it")
        : null
      textColor = DEFAULT_TEXT_COLOR
    }))
    children.append(tipCmp({
      text = isHighSpeedWarningEnabled.value ? loc("hud/vehicle_high_speed_warning") : null
      textColor = FAIL_TEXT_COLOR
    }))
    if (isFlapsCritical.value)
      children.append(tipCmp({
        text = loc("hud/plane_flaps_critical_warning")
        textColor = FAIL_TEXT_COLOR
      }))
    if (isOverloadCritical.value)
      children.append(tipCmp({
        text = loc("hud/plane_overload_critical_warning")
        textColor = FAIL_TEXT_COLOR
      }))
  }

  return {
    watch
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    gap = hdpx(5)

    children
  }
}
