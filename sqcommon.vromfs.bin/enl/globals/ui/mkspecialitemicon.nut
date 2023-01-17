from "%enlSqGlob/ui_library.nut" import *

let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")

const SIGN_PREMIUM = 1
const SIGN_EVENT = 2
const SIGN_BP = 3

let defIconSize = hdpxi(22)

let mkIcon = @(icon, iconSize = defIconSize, iconDef = "!ui/icons/bp_weapon_icon.svg") icon == null ? null : {
  rendObj = ROBJ_IMAGE
  size = [iconSize, iconSize]
  keepAspect = true
  image = Picture($"{icon}:{iconSize}:{iconSize}:K")
  fallbackImage = Picture($"{iconDef}:{iconSize}:{iconSize}:K")
  margin = hdpx(5)
}

let function mkSpecialItemIcon(item, size = defIconSize) {
  let armyId = item?.links ? getLinkedArmyName(item) : item?.armyId
  let { sign = 0 } = item
  return !armyId ? null
    : sign == SIGN_PREMIUM ? mkIcon(armiesPresentation?[armyId].premIcon, size)
    : sign == SIGN_EVENT ? mkIcon("!ui/squads/event_squad_icon.svg", size)
    : sign == SIGN_BP ? mkIcon($"!ui/icons/bp_weapon_icon.svg", size)
    : null
}

let mkBpIcon = @(iconSize = defIconSize)
  mkIcon($"!ui/icons/bp_weapon_icon.svg", iconSize)

return {
  mkSpecialItemIcon
  mkBpIcon
}