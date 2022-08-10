from "%enlSqGlob/ui_library.nut" import *

let markers = require("%ui/hud/state/enemy_attack_markers.nut")
let iconSz = hdpxi(35)
let { MAP_COLOR_ENEMY } = require("%enlSqGlob/ui/style/unit_colors.nut")
let marker = freeze({
  rendObj = ROBJ_IMAGE
  size = [iconSz, iconSz]
  color = MAP_COLOR_ENEMY
  image = Picture("!ui/skin#enemy_attack_arrow.svg:{0}:{1}:K".subst(iconSz, iconSz))
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
})
let transform = {pivot = [0.5, 0.35]} // make arrow more visible when clamped to border
let mkMapMarker = memoize(@(eid) {
  key = eid
  data = {
    eid
    dirRotate = true
    clampToBorder = true
  }
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  transform
  children = marker
})

return {
  watch = markers
  ctor = @(_) markers.value.keys().map(mkMapMarker)
}