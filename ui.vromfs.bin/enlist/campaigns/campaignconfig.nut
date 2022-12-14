from "%enlSqGlob/ui_library.nut" import *

let { shopItems } = require("%enlist/shop/shopItems.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { purchasesCount } = require("%enlist/meta/profile.nut")
let { get_shop_item, apply_freemium } = require("%enlist/meta/clientApi.nut")
let { bonusesList } = require("%enlist/currency/bonuses.nut")
let armyEffects = require("%enlist/soldiers/model/armyEffects.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { getConfig } = require("%enlSqGlob/ui/campaignPromoPresentation.nut")

const CAMPAIGN_NONE = 0

let showCampaignGroup = Watched(null)
let campaignConfigGroup = Computed(@()
  gameProfile.value?.campaigns[curCampaign.value].campaignGroup ?? CAMPAIGN_NONE)

let campPresentation = Computed(@() getConfig(showCampaignGroup.value ?? campaignConfigGroup.value))

let campaignConfig = Computed(@()
  configs.value?.campaignConfig[$"{campaignConfigGroup.value}"] ?? {})

let curShopCampaignItems = Computed(function() {
  let res = []
  let curGroup = campaignConfigGroup.value
  foreach (shopItem in shopItems.value) {
    let { unlockCampaign = CAMPAIGN_NONE } = shopItem
    if (unlockCampaign != CAMPAIGN_NONE && unlockCampaign == curGroup)
      res.append(shopItem)
  }
  return res
})

let isPurchaseableCampaign = Computed(@() curShopCampaignItems.value.len() > 0)

let isCampaignBought = Computed(function() {
  if (!isPurchaseableCampaign.value)
    return false

  return curShopCampaignItems.value
    .findindex(@(item) (purchasesCount.value?[item.guid].amount ?? 0) > 0) != null
})

let needFreemiumStatus = Computed(@() isPurchaseableCampaign.value && !isCampaignBought.value)

let curCampaignAccessItem = Computed(function() {
  if (!isPurchaseableCampaign.value)
    return null

  return curShopCampaignItems.value.reduce(@(res, item)
    (item?.isPrimaryBuy ?? false) > (res?.isPrimaryBuy ?? false) ? item : res)
})

let curUpgradeDiscount = Computed(@()
  armyEffects.value?[curArmy.value].freemiumUpgradeDiscount ?? 0.0)

let curFreemiumBonuses = Computed(@() bonusesList.value?[curCampaignAccessItem.value?.bonusId])

console_register_command(function() {
  let { id = "" } = curCampaignAccessItem.value
  if (id == "")
    return
  get_shop_item(id, console_print)
}, "freemium.buy")

console_register_command(@()
  console_print($"item: {curCampaignAccessItem.value?.id}",
    $"camp: {isPurchaseableCampaign.value}",
    $"bought: {isCampaignBought.value}",
    campaignConfig.value),
  "freemium.info")

console_register_command(@() apply_freemium(curCampaign.value), "freemium.apply")

let configFields = {
  disableArmyExp = false
  disableSquadExp = false
  disableSoldierExp = false
  disablePerkReroll = false
  disableChangeResearch = false
  disableBuySquadSlot = false
  enableExtendedOufit = false
}.map(@(def, key) Computed(@() campaignConfig.value?[key] ?? def))

let armyEffectsFields = {
  freemiumExpBoost = 0.0
  freemiumUpgradeDiscount = 0.0
  maxSquadsInBattle = 0,
  maxInfantrySquads = 0,
  maxVehicleSquads = 0,
  maxBikeSquads = 0,
  upgradeSoldiers = 0
  upgradeVehicles = 0
  upgradeItems = 0
}.map(@(def, key) Computed(@() curFreemiumBonuses.value?.armyEffects[key] ?? def))

return {
  CAMPAIGN_NONE

  campaignConfigGroup
  isPurchaseableCampaign
  isCampaignBought
  curCampaignAccessItem
  curUpgradeDiscount
  needFreemiumStatus
  showCampaignGroup
  campPresentation
}.__update(configFields, armyEffectsFields)
