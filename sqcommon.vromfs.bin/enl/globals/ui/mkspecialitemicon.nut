from "%enlSqGlob/ui_library.nut" import *

let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")


const SIGN_PREMIUM = 1
const SIGN_EVENT = 2
const SIGN_BP = 3

let defIconSize  = hdpxi(22)
let defIconPath  = "!ui/icons/bp_weapon_icon.svg"
let defIconStyle = { margin = hdpx(5) }

let function mkIcon(icon, iconSize = defIconSize, override = {}) {
  if (icon == null)
    return null
  let size = iconSize
  return {
    rendObj = ROBJ_IMAGE
    size = [size, size]
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"{icon}:{size}:{size}:K")
    fallbackImage = Picture($"{defIconPath}:{size}:{size}:K")
  }.__update(override)
}


let function mkSpecialItemIcon(item, size = defIconSize, override = {}) {
  let armyId = item?.links ? getLinkedArmyName(item) : item?.armyId
  let { sign = 0 } = item
  let style = defIconStyle.__update(override)
  return !armyId ? null
    : sign == SIGN_PREMIUM
      ? mkIcon(armiesPresentation?[armyId].premIcon, size, style)
    : sign == SIGN_EVENT
      ? mkIcon("!ui/squads/event_squad_icon.svg", size, style)
    : sign == SIGN_BP
      ? mkIcon($"!ui/icons/bp_weapon_icon.svg", size, style)
    : null
}

let mkBpIcon = @() mkIcon($"!ui/icons/bp_weapon_icon.svg", defIconSize)


return {
  mkSpecialItemIcon
  mkBpIcon
}
