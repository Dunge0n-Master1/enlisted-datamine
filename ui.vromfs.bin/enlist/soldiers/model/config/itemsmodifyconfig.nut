from "%enlSqGlob/ui_library.nut" import *

let { configs } = require("%enlist/meta/configs.nut")

let itemsUpgradeConfig = Computed(@() configs.value?.items_upgrade_config ?? [])
let itemsDisposeConfig = Computed(@() configs.value?.items_dispose_config ?? [])

let function rebuildConfig(modifyConfigList) {
    let res = {}
    foreach (modifyConfig in modifyConfigList) {
      // configs[itemtype][tier][pricetmpl] -> pricecfg
      let { tier = 0, prices = {} } = modifyConfig
      foreach (itemType, modifyPrice in prices) {
        let tiersList = res?[itemType] ?? []
        let pricesTbl = tiersList?[tier] ?? {}
        pricesTbl[modifyPrice.itemTpl] <- modifyPrice
        if (tiersList.len() <= tier)
          tiersList.resize(tier + 1)
        tiersList[tier] = pricesTbl
        res[itemType] <- tiersList
      }
    }
    return res
  }

let itemUpgrades = Computed(@() rebuildConfig(itemsUpgradeConfig.value))
let itemDisposes = Computed(@() rebuildConfig(itemsDisposeConfig.value))

let getModifyConfig = @(modifyConfig, tier, itemType)
  (modifyConfig?[itemType] ?? modifyConfig?["default"])?[tier]

return {
  itemUpgrades
  itemDisposes
  getModifyConfig
}
