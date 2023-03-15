from "%enlSqGlob/ui_library.nut" import *

let { soldierKinds } = require("%enlSqGlob/ui/soldierClasses.nut")
let { titleTxtColor, colPart, blockedBgColor } = require("%enlSqGlob/ui/designConst.nut")

let squadIconSize = [colPart(1.2), colPart(1.2)]
let squadTypeIconCircle = colPart(0.55)
let squadTypeIconSize = colPart(0.43)

let squadTypeSvg = soldierKinds.map(@(c) c.icon)
  .__update({
      tank = "tank_icon.svg"
      aircraft = "aircraft_icon.svg"
      bike = "bike_icon.svg"
    })
  .map(@(key) $"ui/skin#{key}")

let getSquadTypeIcon = @(squadType) squadTypeSvg?[squadType] ?? "ui/skin#rifle.svg"

local function mkSquadIcon(img, override = {}) {
  if ((img ?? "") == "")
    return {
      rendObj = ROBJ_BOX
      borderWidth = hdpx(1)
      size = squadIconSize
    }
  let size = override?.size ?? squadIconSize
  if (type(size) == "array")
    img = $"{img}:{size[0].tointeger()}:{size[1].tointeger()}:K"
  return {
    rendObj = ROBJ_IMAGE
    size = squadIconSize
    keepAspect = KEEP_ASPECT_FIT
    image = Picture(img)
  }.__update(override)
}

let blockSign = {
  rendObj = ROBJ_IMAGE
  image = Picture($"!ui/uiskin/block_sign.svg:{squadTypeIconSize}:{squadTypeIconSize}:K")
  color = blockedBgColor
  size = [squadTypeIconCircle, squadTypeIconCircle]
}


let function mkSquadTypeIcon(squadType, isLocked) {
  let isTank = squadType == "tank"
  let iconSize = isTank ? (squadTypeIconSize * 0.9).tointeger() : squadTypeIconSize
  return {
    rendObj = ROBJ_VECTOR_CANVAS
    commands = [ [ VECTOR_ELLIPSE, 50, 50, 50, 50 ] ]
    fillColor = 0xFF000000
    color = 0xFF000000
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = [squadTypeIconCircle, squadTypeIconCircle]
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [iconSize, iconSize]
        keepAspect = KEEP_ASPECT_FIT
        color = titleTxtColor
        pos = isTank ? [iconSize * 0.1, 0] : [0, 0]
        image = Picture("{0}:{1}:{1}:K".subst(getSquadTypeIcon(squadType), iconSize))
      }
      isLocked ? blockSign : null
  ]
  }
}

return {
  mkSquadIcon
  mkSquadTypeIcon
}