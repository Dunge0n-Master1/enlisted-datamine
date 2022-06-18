from "%enlSqGlob/ui_library.nut" import *

let {controlledVehicleEid} = require("%ui/hud/state/vehicle_state.nut")
let {mainTurretAmmo, mainTurretEid, turretsReload} = require("%ui/hud/state/vehicle_turret_state.nut")
let {mkCountdownTimer} = require("%ui/helpers/timers.nut")

let circleProgressImage = Picture("ui/skin#scanner_range")
let aim_color = Color(200, 200, 200, 150)
let aim_bgcolor = Color(0, 0, 0, 25)
let overheatFg = Color(160, 0, 0, 180)
let overheatBg = Color(0, 0, 0, 0)
let overheat = require("%ui/hud/state/vehicle_turret_overheat_state.nut")

let hasAmmo = Computed(@() (mainTurretAmmo.value?.curAmmo ?? 0) + (mainTurretAmmo.value?.totalAmmo ?? 0) > 0)
let mainTurretReload = Computed(@() turretsReload.value?[mainTurretEid.value] ?? {})
let reloadEndTime = Computed(@() mainTurretReload.value?.endTime ?? -1)

let reloadTimer = mkCountdownTimer(reloadEndTime)
let vehicleReloadProgress = Computed(@()
  !hasAmmo.value ? 0
    : (mainTurretReload.value?.progressStopped ?? -1) >= 0 ? mainTurretReload.value.progressStopped
    : (mainTurretReload.value?.totalTime ?? -1) > 0 ? max(0, (1 - (reloadTimer.value / mainTurretReload.value.totalTime)))
    : 1.0
)

let function bgAim(){
  return {
    color = aim_bgcolor
    fillColor = Color(0, 0, 0, 0)
    rendObj = ROBJ_VECTOR_CANVAS
    size = [fsh(4.0), fsh(4.0)]
    commands = [
      [VECTOR_WIDTH, hdpx(4)],
      [VECTOR_ELLIPSE, 50, 50, 50, 50],
    ]
  }
}

let function aim(){
  return {
    color = aim_color
    fillColor = Color(0, 0, 0, 0)
    rendObj = ROBJ_VECTOR_CANVAS
    size = [fsh(4.0), fsh(4.0)]
    watch = vehicleReloadProgress
    commands = [
      [VECTOR_WIDTH, hdpx(1)],
      [VECTOR_SECTOR, 50, 50, 50, 50, -90.0, -90.0 + (vehicleReloadProgress.value ?? 1.0) * 360.0],
    ]
  }
}

let function overheatBlock() {
  return {
    watch = overheat
    opacity = min(1.0, overheat.value*2.0)
    fValue = overheat.value
    rendObj = ROBJ_PROGRESS_CIRCULAR
    image = circleProgressImage
    size = [fsh(4), fsh(4)]
    fgColor = overheatFg
    bgColor = overheatBg
  }
}

let crosshair = @() {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  behavior = Behaviors.VehicleCrosshair
  transform = {}

  watch = [controlledVehicleEid]
  eid = controlledVehicleEid.value

  children = [ bgAim aim overheatBlock]
}

let function root() {
  return {
    size = flex()
    children = crosshair
  }
}


return root
