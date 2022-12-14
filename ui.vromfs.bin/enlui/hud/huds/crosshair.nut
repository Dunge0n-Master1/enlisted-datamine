from "%enlSqGlob/ui_library.nut" import *

let {mkCountdownTimer} = require("%ui/helpers/timers.nut")
let circleProgressImage = Picture("ui/skin#scanner_range.png")
let hairColor = Color(160, 160, 160, 120 )
let overheatFg = Color(160, 0, 0, 180)
let overheatBg = Color(0, 0, 0, 0)
let reloadColor = Color(200, 200, 200, 150)

let {
  overheat, teammateAim, isAiming, debugForceCrosshair, crosshairType, crosshairColor,
  reloadEndTime, reloadTotalTime, crossHairEid, showCustomCrosshair, crosshairCustomType
} = require("%ui/hud/huds/crosshair_state_es.nut")

let hitHair = require("%ui/hud/huds/hit_marks.nut").hitMarks

let reloadTimer = mkCountdownTimer(reloadEndTime)
let reloadProgress = Computed(@()
  (reloadTotalTime.value ?? -1) > 0 ? max(0, (1 - (reloadTimer.value / reloadTotalTime.value)))
  : 0.0
)
let crosshairs = {}

let forbid = freeze({
  rendObj = ROBJ_VECTOR_CANVAS
  size = [fsh(1.5), fsh(1.5)]
  commands = [
    [VECTOR_WIDTH, hdpx(1.8)],
    [VECTOR_LINE, 0, 0, 100, 100],
    [VECTOR_LINE, 0, 100, 100, 0],
  ]
  color = Color(20, 80, 220, 80)

  animations = [
    { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic }
    { prop=AnimProp.opacity, from=1, to=0, duration=0.1, playFadeOut=true, easing=OutCubic }
  ]
})

crosshairs.chevron <- @() {
  rendObj = ROBJ_VECTOR_CANVAS
  size = [fsh(1.5), fsh(1.5)]
  commands = [
    [VECTOR_WIDTH, hdpx(1.8)],
    [VECTOR_LINE, 0, 100, 50, 50, 100, 100],
  ]
  color = hairColor

  animations = [
    { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic }
    { prop=AnimProp.opacity, from=1, to=0, duration=0.1, playFadeOut=true, easing=OutCubic }
  ]
}
let ct = freeze([
  [VECTOR_WIDTH, hdpx(2)],
  [VECTOR_LINE, 0, 50, 30, 50],
  [VECTOR_LINE, 70, 50, 100, 50],
  [VECTOR_LINE, 50, 70, 50, 100],
])

crosshairs.t_post <- @() {
  size = flex()
  watch = crosshairColor
  rendObj = ROBJ_VECTOR_CANVAS
  color = crosshairColor.value.u
  commands = ct
}


let function hitMarkBlock() {
  return {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = hitHair
  }
}

let forbidBlock = {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = forbid
}

let function reloadBlock(){
  return {
    watch = reloadProgress
  }.__update(reloadProgress.value <= 0 ? {} : {
    color = reloadColor
    fillColor = Color(0, 0, 0, 0)
    rendObj = ROBJ_VECTOR_CANVAS
    size = [fsh(4.0), fsh(4.0)]
    commands = [
      [VECTOR_WIDTH, hdpx(1)],
      [VECTOR_SECTOR, 50, 50, 50, 50, -90.0, -90.0 + (reloadProgress.value ?? 0.0) * 360.0],
    ]
  })
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


let w = sw(0.2*100)
let h = sh(0.2*100)

let function mkCrosshair(childrenCtor, watch, size=[2*w, 2*h]){
  return @() {
    watch
    size
    lineWidth = hdpx(2)
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Crosshair
    transform = {}
    eid = crossHairEid.value
    children = childrenCtor()
  }
}
let overlayTransparencyBlock = {
  size =  [fsh(3), fsh(3)]
  behavior = isAiming.value? Behaviors.OverlayTransparency : null
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
}
let mkCrosshairElement = @(children) {size = [sw(100), sh(100)], children = children}
let canShowForbidden = Computed(@() teammateAim.value && !isAiming.value)
let crossHairTypeToShow = Computed(@() debugForceCrosshair.value ? crosshairType?.value : showCustomCrosshair.value ? crosshairCustomType?.value : null)

let forbiddenBlock = @(){
  watch = canShowForbidden
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = canShowForbidden.value ? forbid : null
}

let crosshair = mkCrosshair(@() [
    forbiddenBlock,
    crosshairs?[crossHairTypeToShow?.value],
    hitMarkBlock,
    overheatBlock,
    overlayTransparencyBlock
  ],
  crossHairTypeToShow
)

let crosshairForbidden = mkCrosshair(@() teammateAim.value ? forbidBlock : null, teammateAim)
let crosshairOverheat = mkCrosshair(@() overheatBlock, null)
let crosshairReload = mkCrosshair(@() reloadBlock, null)
let crosshairHitmarks = mkCrosshair(@() hitMarkBlock, null)

return {
  mkCrosshair
  mkCrosshairElement
  crosshair = mkCrosshairElement(crosshair)
  crosshairForbidden = mkCrosshairElement(crosshairForbidden)
  crosshairOverheat = mkCrosshairElement(crosshairOverheat)
  crosshairReload = mkCrosshairElement(crosshairReload)
  crosshairHitmarks = mkCrosshairElement(crosshairHitmarks)
  crosshairOverlayTransparency = mkCrosshairElement(overlayTransparencyBlock)
}
