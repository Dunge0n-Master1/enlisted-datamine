from "%enlSqGlob/ui_library.nut" import *

let markers = require("%ui/hud/state/enemy_attack_markers.nut")
let iconSz = hdpx(35).tointeger()
let { MAP_COLOR_ENEMY } = require("%enlSqGlob/ui/style/unit_colors.nut")
let markerColor = MAP_COLOR_ENEMY
let markerImg = Picture("!ui/skin#enemy_attack_arrow.svg:{0}:{1}:K".subst(iconSz, iconSz))

let mkMapMarker = @(eid, _marker, _options = null) {
  key = eid
  data = {
    eid = eid
    dirRotate = true
    clampToBorder = true
  }
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  transform = {pivot = [0.5, 0.35]} // make arrow more visible when clamped to border
  children = {
    rendObj = ROBJ_IMAGE
    size = [iconSz, iconSz]
    color = markerColor
    image = markerImg
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
  }
}

return {
  watch = markers
  ctor = @(p) markers.value.reduce(@(res, info, eid) res.append(mkMapMarker(eid, info, p)), [])
}