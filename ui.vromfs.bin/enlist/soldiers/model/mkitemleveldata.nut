from "%enlSqGlob/ui_library.nut" import *

let upgrades = require("%enlist/soldiers/model/config/upgradesConfig.nut")
let { mkItemUpgradeData } = require("%enlist/soldiers/model/mkItemModifyData.nut")

return function(item) {
  let upgradeData = mkItemUpgradeData(item)
  return Computed(function() {
    let { tier = 0, upgradesId = null, upgradeIdx = 0 } = item
    return {
      tierMax = max(tier, tier + (upgrades.value?[upgradesId] ?? []).len() - 1 - upgradeIdx)
      canUpgrade = upgradeData.value.isUpgradable
    }
  })
}
