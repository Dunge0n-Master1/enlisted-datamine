from "%enlSqGlob/ui_library.nut" import *

let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")


const SIGN_PREMIUM = 1
const SIGN_EVENT = 2
const SIGN_BP = 3

let defIconSize  = hdpxi(22)
let defIconPath  = "!ui/icons/bp_weapon_icon.svg"
let defIconStyle = { margin = hdpx(5) }

let mkIcon = @(icon, iconSize = defIconSize, override = {})
  icon == null ? null
    : {
        rendObj = ROBJ_IMAGE
        size = [iconSize, iconSize]
        keepAspect = KEEP_ASPECT_FIT
        image = Picture($"{icon}:{iconSize}:{iconSize}:K")
        fallbackImage = Picture($"{defIconPath}:{iconSize}:{iconSize}:K")
      }.__update(override)


let function mkSpecialItemIcon(item, size = defIconSize, isNewDesign = false) {
  let armyId = item?.links ? getLinkedArmyName(item) : item?.armyId
  let { sign = 0 } = item
  return !armyId ? null
    : sign == SIGN_PREMIUM
        ? mkIcon(armiesPresentation?[armyId].premIcon, size, isNewDesign ? {} : defIconStyle)
    : sign == SIGN_EVENT
        ? mkIcon("!ui/squads/event_squad_icon.svg", size, defIconStyle)
    : sign == SIGN_BP
        ? mkIcon($"!ui/icons/bp_weapon_icon.svg", size, defIconStyle)
    : null
}

let mkBpIcon = @(iconSize = defIconSize)
  mkIcon($"!ui/icons/bp_weapon_icon.svg", iconSize)


return {
  mkSpecialItemIcon
  mkBpIcon
}
