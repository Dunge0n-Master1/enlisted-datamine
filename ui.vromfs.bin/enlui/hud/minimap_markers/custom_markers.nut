from "%enlSqGlob/ui_library.nut" import *

let markers = require("%ui/hud/state/custom_markers.nut")

let mkMarker = memoize(@(icon, size, color) {
  rendObj = ROBJ_IMAGE
  size = [hdpxi(size.x), hdpxi(size.y)]
  color
  image = Picture($"{icon}:{hdpxi(size.x)}:{hdpxi(size.y)}:K")
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
})

let transform = {pivot = [0.5, 0.35]} // make arrow more visible when clamped to border
let mkMapMarker = function(eid) {
  let markerInfo = markers.value[eid]
  return {
    key = eid
    data = {
      eid
      dirRotate = true
      clampToBorder = true
    }
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    transform
    children = mkMarker(markerInfo.icon, markerInfo.size, markerInfo.color)
  }
}


return {
  watch = markers
  ctor = @(_) markers.value.keys().map(mkMapMarker)
}
