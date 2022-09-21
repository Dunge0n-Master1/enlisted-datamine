from "%enlSqGlob/ui_library.nut" import *

let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")

const SIGN_PREMIUM = 1
const SIGN_EVENT = 2

let defIconSize = hdpxi(22)

let mkIcon = @(icon, iconSize) icon == null ? null : {
  rendObj = ROBJ_IMAGE
  size = [iconSize, iconSize]
  keepAspect = true
  image = Picture($"{icon}:{iconSize}:{iconSize}:K")
}

let function mkSpecialItemIcon(item, size = defIconSize) {
  let armyId = item?.links ? getLinkedArmyName(item) : item?.armyId
  let { sign = 0 } = item
  return !armyId ? null
    : sign == SIGN_PREMIUM ? mkIcon(armiesPresentation?[armyId].premIcon, size)
    : sign == SIGN_EVENT ? mkIcon("!ui/squads/event_squad_icon.svg", size)
    : null
}

return mkSpecialItemIcon