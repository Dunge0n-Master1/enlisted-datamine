from "%enlSqGlob/ui_library.nut" import *

let { mortarMarkersSet, mortarMarkersGetWatched } = require("%ui/hud/state/mortar_markers.nut")

let mortarMarkerMapIconSize = [sh(2.25), sh(2.25)].map(@(v) v.tointeger())

let mortarImages = {
  mortarKill = Picture("!ui/skin#skull.svg:{0}:{1}:K".subst(mortarMarkerMapIconSize[0], mortarMarkerMapIconSize[1]))
  mortarShellExplode = Picture("!ui/skin#launcher.svg:{0}:{1}:K".subst(mortarMarkerMapIconSize[0], mortarMarkerMapIconSize[1]))
}
let transform = {
  pivot=[0.5, 0.5]
  rotate = -90
}

let function mkMortarMarker(eid){
  let marker = mortarMarkersGetWatched(eid).value
  return {
    image = mortarImages?[marker.type]
    size = mortarMarkerMapIconSize
    valign = ALIGN_CENTER
    transform
    rendObj = ROBJ_IMAGE
    data = {
      worldPos = marker.pos
    }
  }
}

let memoizedMap = mkMemoizedMapSet(mkMortarMarker)
return {
  watch = mortarMarkersSet
  ctor = @(_) memoizedMap(mortarMarkersSet.value).values()
}