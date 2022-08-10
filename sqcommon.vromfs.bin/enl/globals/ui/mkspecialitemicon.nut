from "%enlSqGlob/ui_library.nut" import *

let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")

let defIconSize = hdpxi(22)

let premiumIcon = @(armyId) armiesPresentation?[armyId].premIcon
let eventIcon = @(_armyId) "!ui/squads/event_squad_icon.svg"

let mkIcon = @(icon, iconSize, override = null) icon == null ? null : {
  rendObj = ROBJ_IMAGE
  size = [iconSize, iconSize]
  keepAspect = true
  image = Picture($"{icon}:{iconSize}:{iconSize}:K")
}.__update(override ?? {})

let function mkSpecialItemIcon(item, size = defIconSize){
  let armyId = item?.links ? getLinkedArmyName(item) : item?.armyId
  return !armyId ? null
    : item?.isPremium ? mkIcon(premiumIcon(armyId), size)
    : item?.isEvent ? mkIcon(eventIcon(armyId), size)
    : null
}

return mkSpecialItemIcon