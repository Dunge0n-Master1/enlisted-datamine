from "%enlSqGlob/ui_library.nut" import *

let iconSize = hdpx(18).tointeger()
let mkSvg = @(img) $"!ui/uiskin/{img}.svg:{iconSize}:{iconSize}:K"

let mkBuildingIcon = @(eid, marker, options = null) {
  data = {
    eid = eid
    minDistance = 0.7
    maxDistance = marker?.visible_distance ?? 500
    distScaleFactor = 0.5
    clampToBorder = true
  }
  rendObj = ROBJ_IMAGE
  color = Color(255, 255, 255)
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  transform = options?.transform
  key = eid
  sortOrder = eid
  size = [iconSize, iconSize]
  image = marker?.image ? Picture(mkSvg(marker?.image)) : null
}

return mkBuildingIcon