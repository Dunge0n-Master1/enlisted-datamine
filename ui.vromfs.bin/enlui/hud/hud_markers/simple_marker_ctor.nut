from "%enlSqGlob/ui_library.nut" import *

let {Point2} = require("dagor.math")
let mkSize =  @(x,y) [fsh(x), fsh(y)].map(@(v) v.tointeger())
let defaultIconSize = mkSize(3.5, 3.5)
let mkSvg = @(img, size) $"!ui/uiskin/{img}.svg:{size[0]}:{size[1]}:K"

let function ctor(eid, info) {
  let iconSize = info?.size ? mkSize(info.size.x, info.size.y) : defaultIconSize
  return {
    data = {
      eid = eid
      minDistance = info?.minDistance ?? 0.1
      maxDistance = info?.maxDistance ?? 10.0
      yOffs = info?.offsetY ?? 0.0
      distScaleFactor = 0.5
      clampToBorder = info?.clampToBorder ?? false
      opacityRangeX = info?.opacityRangeX ?? Point2(0.2, 0.2)
      opacityRangeY = info?.opacityRangeY ?? Point2(0.2, 0.2)
      opacityCenterRelativeDist = info?.opacityCenterRelativeDist ?? 0.05
      opacityCenterMinMult = info?.opacityCenterMinMult ?? 0.5
    }
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    transform = {}
    key = eid
    behavior = [Behaviors.OverlayTransparency]
    sortOrder = eid
    children = [
      {
        size = iconSize
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        image = Picture(mkSvg(info?.image ?? "", iconSize))
      }
    ]
  }
}

return ctor
