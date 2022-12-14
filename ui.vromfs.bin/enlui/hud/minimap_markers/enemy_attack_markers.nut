from "%enlSqGlob/ui_library.nut" import *

let markers = require("%ui/hud/state/enemy_attack_markers.nut")
let iconSz = hdpxi(35)
let { MAP_COLOR_ENEMY } = require("%enlSqGlob/ui/style/unit_colors.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")


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

let marksList = Computed(@() isReplay.value ? [] : markers.value.keys())

return {
  watch = marksList
  ctor = @(_) marksList.value.map(mkMapMarker)
}