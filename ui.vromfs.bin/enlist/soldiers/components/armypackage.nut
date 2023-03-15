from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  strokeStyle, bigGap, armyIconHeight, hoverTitleTxtColor, activeTitleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")

let mkIcon = @(sIcon, size, override) sIcon == null ? null : {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = Picture("!ui/skin#{0}:{1}:{1}:K".subst(sIcon, size.tointeger()))
  margin = bigGap
}.__update(override)

let mkArmyIcon = @(armyId, size = armyIconHeight, override = {})
  mkIcon(armiesPresentation?[armyId].icon ?? armyId, size, override)

let mkArmySimpleIcon = @(armyId, size = armyIconHeight, override = {})
  mkIcon(armiesPresentation?[armyId].smallIcon ?? armyId, size, override)

let getArmyColor = @(selected, sf)
  (selected || (sf & S_HOVER)) ? hoverTitleTxtColor : activeTitleTxtColor

let mkArmyName = @(armyId, isSelected = false, sf = 0) {
  rendObj = ROBJ_TEXT
  text = loc(armyId)
  color = getArmyColor(isSelected, sf)
  vplace = ALIGN_CENTER
}.__update(h2_txt, strokeStyle)

return {
  mkArmySimpleIcon
  mkArmyIcon
  mkArmyName
}
