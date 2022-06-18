from "%enlSqGlob/ui_library.nut" import *

let {makeArrow} = require("%ui/hud/huds/hud_markers/components/hud_markers_components.nut")

let colorRedBlink = Color(255, 141, 29, 220)
let colorRed      = Color(255,  40, 30, 220)

let activatorAnim = [{
  prop = AnimProp.color, from = colorRed, to = colorRedBlink,
  duration = 0.3, play = true, loop = true, easing = CosineFull
}]

let activatorMarker = @(eid, info) {
  data = {
    eid = eid
    minDistance = 0.7
    maxDistance = info.maxDistance
    yOffs = 0.1
    distScaleFactor = 0.5
    clampToBorder = true
  }
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  transform = {}
  key = eid
  sortOrder = eid
  children = [
    {
      size = [fsh(4.), fsh(4.)]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      color = colorRed
      image = Picture($"!ui/skin#{info.icon}")
      animations = activatorAnim
    },
    makeArrow({color = colorRed, anim = activatorAnim, yOffs = 0, pos = [0, -fsh(1.8)]})
  ]
}

return {
  activator_marker = activatorMarker
}