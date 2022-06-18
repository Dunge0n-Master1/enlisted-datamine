from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  strokeStyle, bigGap, armyIconHeight, hoverTitleTxtColor, activeTitleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")

let mkPicture = @(sIcon, size)
  Picture("!ui/skin#{0}:{1}:{1}:K".subst(sIcon, size.tointeger()))

let mkIcon = @(image, size, override) image == null ? null : {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = image
  margin = bigGap
}.__update(override)

let mkArmyIcon = @(armyId, size = armyIconHeight, override = {})
  mkIcon(mkPicture(armiesPresentation?[armyId].icon ?? armyId, size), size, override)

let mkArmySimpleIcon = @(armyId, size = armyIconHeight, override = {})
  mkIcon(mkPicture(armiesPresentation?[armyId].smallIcon ?? armyId, size), size, override)

let getArmyColor = @(selected, sf)
  (selected || (sf & S_HOVER)) ? hoverTitleTxtColor : activeTitleTxtColor

let mkArmyName = @(armyId, isSelected = false, sf = 0) {
  rendObj = ROBJ_TEXT
  text = loc(armyId)
  color = getArmyColor(isSelected, sf)
  vplace = ALIGN_CENTER
}.__update(h2_txt, strokeStyle)

let mkArmyBack = @(armyId) {
  rendObj = ROBJ_SOLID
  size = [pw(100), pw(75)]
  padding = hdpx(2)
  color = Color(0,0,0)
  children = {
    rendObj = ROBJ_IMAGE
    size = flex()
    keepAspect = true
    imageValign = ALIGN_TOP
    image = Picture(armiesPresentation?[armyId].promoImage ?? $"ui/soldiers/{armyId}.jpg")
    fallbackImage = Picture("ui/soldiers/army_default.jpg")
  }
}

return {
  mkArmySimpleIcon
  mkArmyIcon
  mkArmyName
  mkArmyBack
}
