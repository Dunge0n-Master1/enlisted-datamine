from "%enlSqGlob/ui_library.nut" import *

let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let { colPart, commonBorderRadius, defVertGradientImg
} = require("%enlSqGlob/ui/designConst.nut")

let armyIconSize = colPart(0.45)

let markerTarget = MoveToAreaTarget()

let function requestMoveToElem(elem) {
  let x = elem.getScreenPosX()
  let y = elem.getScreenPosY()
  let w = elem.getWidth()
  let h = elem.getHeight()
  markerTarget.set(x, y, x + w, y + h)
}

let mkIcon = @(image, size, override) {
  rendObj = ROBJ_IMAGE
  image = Picture("!ui/skin#{0}:{1}:{1}:K".subst(image, size))
  size = [size, size]
}.__update(override)

let mkArmyIcon = @(armyId, size = armyIconSize, override = {})
  mkIcon(armiesPresentation?[armyId].icon ?? armyId, size, override)

let armyMarker = {
  rendObj = ROBJ_BOX
  size = flex()
  viscosity = 0.1
  target = markerTarget
  behavior = Behaviors.MoveToArea
  subPixel = true
  borderRadius = commonBorderRadius
  children = {
    size = flex()
    rendObj = ROBJ_IMAGE
    image = defVertGradientImg
  }
}


return {
  mkArmyIcon
  armyMarker
  requestMoveToElem
  armyIconSize
}
