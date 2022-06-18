from "%enlSqGlob/ui_library.nut" import *

let mortarMarkers = require("%ui/_packages/common_shooter/hud/state/mortar_markers.nut")

let mortarMarkerMapIconSize = [sh(2.25), sh(2.25)]

let mortarImages = {
  mortarKill = Picture("!ui/skin#skull.svg:{0}:{1}:K".subst(mortarMarkerMapIconSize[0], mortarMarkerMapIconSize[1]))
  mortarShellExplode = Picture("!ui/skin#launcher.svg:{0}:{1}:K".subst(mortarMarkerMapIconSize[0], mortarMarkerMapIconSize[1]))
}

let function mkMortarMarker(marker){
  return {
    image = mortarImages?[marker.type]
    size = mortarMarkerMapIconSize
    valign = ALIGN_CENTER
    transform = {
      pivot=[0.5, 0.5]
      rotate = -90
    }
    rendObj = ROBJ_IMAGE
    data = {
      worldPos = marker.pos
    }
  }
}

return {
  watch = mortarMarkers
  ctor = @(_) mortarMarkers.value.reduce(@(res, marker) res.append(mkMortarMarker(marker)), [])
}