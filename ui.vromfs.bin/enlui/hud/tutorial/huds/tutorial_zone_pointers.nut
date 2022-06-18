from "%enlSqGlob/ui_library.nut" import *

let {safeAreaHorPadding, safeAreaVerPadding} = require("%enlSqGlob/safeArea.nut")
let { tutorialZones } = require("%ui/hud/tutorial/state/tutorial_zones_state.nut")

let iconSz = [hdpx(32), hdpx(32)].map(@(v) v.tointeger())

let arrowColor = Color(230, 230, 230, 250)

let arrowIconInside = {
  rendObj = ROBJ_IMAGE
  size = iconSz
  image = Picture("!ui/skin#waypoint_tutorial.svg")
  color = arrowColor
  markerFlags = MARKER_SHOW_ONLY_IN_VIEWPORT
  transform = {}
  animations = [
    { prop = AnimProp.translate, from = [0,fsh(2)], to = [0,0], duration = 1, play = true, loop = true, easing = CosineFull }
  ]
}

let arrowIconOutside = {
  markerFlags = MARKER_SHOW_ONLY_WHEN_CLAMPED | MARKER_ARROW
  transform = {}
  children = arrowIconInside.__merge({
    transform = { rotate = 180 }
  })
}

let mkArrow = @(eid) {
  size = [0, 0]
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  data = { eid, clampToBorder = true }
  transform = {}
  children = [
    arrowIconInside
    arrowIconOutside
  ]
}

let function tutorialZonePointers() {
  let children = tutorialZones.value.keys().map(mkArrow)
  return {
    watch = [tutorialZones, safeAreaHorPadding, safeAreaVerPadding]
    size = [sw(100)-safeAreaHorPadding.value*2 - fsh(40), sh(100) - safeAreaVerPadding.value*2-fsh(40)]
    behavior = Behaviors.Projection
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = children
  }
}

return tutorialZonePointers
