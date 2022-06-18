from "%enlSqGlob/ui_library.nut" import *

let { makeArrow } = require("components/hud_markers_components.nut")

let colorWhite   = Color(255,  255,  255, 220)
let colorRedBlink =Color(255, 141, 29, 220)
let colorRed     = Color(255,  40,  30, 220)

let grenadeAnim = [{
  prop = AnimProp.color, from = colorRed, to = colorRedBlink,
  duration = 0.3, play = true, loop = true, easing = CosineFull
}]

let defTransform = {}
let grenadePic = Picture("!ui/skin#grenade")

let function grenadeMarker(eid, info) {
  let willDamageHero = info?.willDamageHero ?? true
  let color = willDamageHero ? colorRed : colorWhite

  return {
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
    transform = defTransform
    key = eid
    sortOrder = eid
    children = [
      {
        size = [fsh(2.5), fsh(2.5)]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        color = color
        image = grenadePic
        animations = willDamageHero ? grenadeAnim : null
      },
      makeArrow({color=colorRed, anim = grenadeAnim, yOffs=0, pos=[0,-fsh(1.8)]})
    ]
  }
}

let grenadeArrow = @(eid, info) (info?.willDamageHero ?? true)
  ? {
    key = eid
    sortOrder = eid
    transform = defTransform
    data = {
      eid = eid
      maxDistance = info.maxDistance
      yOffs = 0
      clampToBorder = true
    }
    children = makeArrow({color=colorRed, anim = grenadeAnim, yOffs=0, pos=[0,0]})
  } : null

return {
  grenade_marker = grenadeMarker
  grenadeArrow = grenadeArrow
}