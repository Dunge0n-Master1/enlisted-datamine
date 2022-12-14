from "%enlSqGlob/ui_library.nut" import *

let {controlledVehicleEid} = require("%ui/hud/state/vehicle_state.nut")
let {vehicleTurrets} = require("%ui/hud/state/vehicle_turret_state.nut")

let lineWidth = max(1.1, hdpx(1.2))
let forbid = {
  rendObj = ROBJ_VECTOR_CANVAS
  size = [fsh(1.5), fsh(1.5)]
  commands = [
    [VECTOR_WIDTH, lineWidth],
    [VECTOR_LINE, 0, 0, 100, 100],
    [VECTOR_LINE, 0, 100, 100, 0],
  ]
  color = Color(20, 80, 220, 80)

  animations = [
    { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic }
    { prop=AnimProp.opacity, from=1, to=0, duration=0.1, playFadeOut=true, easing=OutCubic }
  ]
}

let function circle(color, width=null){
  return {
    color
    fillColor = Color(0, 0, 0, 0)
    rendObj = ROBJ_VECTOR_CANVAS
    size = flex()
    commands = [
      [VECTOR_WIDTH, width ?? lineWidth],
      [VECTOR_ELLIPSE, 50, 50, 50, 50],
    ]
  }
}

let crossHairSize = [fsh(2.0), fsh(2.0)]

let colorNotPenetrated = Color(245, 30, 30)
let colorInEffective = Color(150, 150, 140)
let colorEffective = Color(30, 255, 30)
let colorPossibleEffective = Color(230, 230, 20)
let colorShadow = Color(0,0,0,100)
let mkCircle = @(color, pos = null, width = null) {size = crossHairSize, children = [circle(color, width)], pos}
let mkBlock = @(xhairMode, color) {size = crossHairSize, xhairMode = xhairMode, children = [mkCircle(color), mkCircle(colorShadow, [0, hdpx(1)], lineWidth*2)]}

let aimNotPenetratedBlock = mkBlock("aimNotPenetrated", colorNotPenetrated)
let aimIneffectiveBlock = mkBlock("aimIneffective", colorInEffective)
let aimEffectiveBlock = mkBlock("aimEffective", colorEffective)
let aimPossibleEffectiveBlock = mkBlock("aimPossibleEffective", colorPossibleEffective)


let forbidBlock = {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  xhairMode = "teammate"
  children = [
    forbid
  ]
}

let mkCrosshair = @(turretEid, vehicleEid) {
    size = crossHairSize
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.TurretCrosshair
    transform = {}

    eid = vehicleEid
    turretEid = turretEid

    children = [
      forbidBlock
      aimNotPenetratedBlock
      aimIneffectiveBlock
      aimEffectiveBlock
      aimPossibleEffectiveBlock
    ]
}

let function calculate_crosshairs(turrets, vehicleEid) {
  let children = []
  foreach (turret in turrets) {
    if (turret.isControlled && !turret.isLocalControlLocked && turret.showCrosshair)
      children.append(mkCrosshair(turret.gunEid, vehicleEid))
  }

  return children
}

let crosshair = @() {
  watch = [controlledVehicleEid, vehicleTurrets]
  size = [sw(100), sh(100)]
  children = calculate_crosshairs(vehicleTurrets.value ?? [], controlledVehicleEid.value)
}

return crosshair