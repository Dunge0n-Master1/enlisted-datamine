from "%enlSqGlob/ui_library.nut" import *

let { unseenSoldiersWeaponry } = require("unseenWeaponry.nut")
let { curUnseenUpgradesBySoldier, isUpgradeUsed } = require("unseenUpgrades.nut")
let { notChoosenPerkSoldiers } = require("soldierPerks.nut")
let {
  mkAlertIcon, PERK_ALERT_SIGN, ITEM_ALERT_SIGN
} = require("%enlSqGlob/ui/soldiersUiComps.nut")


const DEF_KIND = "rifle"


let mkAlertInfo = @(soldierInfo, _isSelected) {
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  children = [
    mkAlertIcon(ITEM_ALERT_SIGN, Computed(function() {
      let weapCount = unseenSoldiersWeaponry.value?[soldierInfo?.guid].len() ?? 0
      let upgrCount = (isUpgradeUsed.value ?? false) ? 0
        : (curUnseenUpgradesBySoldier.value?[soldierInfo?.guid] ?? 0)
      return weapCount + upgrCount > 0
    }))
    mkAlertIcon(PERK_ALERT_SIGN, Computed(@()
      (notChoosenPerkSoldiers.value?[soldierInfo?.guid] ?? 0) > 0
    ))
  ]
}


let curSoldierKind = Watched(DEF_KIND)


return {
  mkAlertInfo
  curSoldierKind
  DEF_KIND
}