from "%enlSqGlob/ui_library.nut" import *

let { shopItems } = require("%enlist/shop/shopItems.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { purchasesCount } = require("%enlist/meta/profile.nut")
let { get_shop_item, apply_freemium } = require("%enlist/meta/clientApi.nut")
let { bonusesList } = require("%enlist/currency/bonuses.nut")
let armyEffects = require("%enlist/soldiers/model/armyEffects.nut")

let freemiumItems = Computed(@() shopItems.value
  .filter(@(i) i?.freemiumCampId == curCampaign.value))

let isFreemiumCampaign = Computed(@()
  gameProfile.value?.campaigns[curCampaign.value].isFreemium ?? false)

let isFreemiumBought = Computed(@() freemiumItems.value
  .keys()
  .findindex(@(id) (purchasesCount.value?[id].amount ?? 0) > 0) != null)

let needFreemiumStatus = Computed(@() isFreemiumCampaign.value && !isFreemiumBought.value)

let curFreemiumShopItem = Computed(function() {
  if (!isFreemiumCampaign.value)
    return null

  return freemiumItems.value.reduce(@(res, item)
    res == null || (item?.isPrimaryBuy ?? false) > (res?.isPrimaryBuy ?? false) ? item : res, null)
})

let curUpgradeDiscount = Computed(@()
  armyEffects.value?[curArmy.value].freemiumUpgradeDiscount ?? 0.0)

let curFreemiumBonuses = Computed(@() bonusesList.value?[curFreemiumShopItem.value?.bonusId])

let freemiumUpgradeDiscount = Computed(@()
  curFreemiumBonuses.value?.armyEffects.freemiumUpgradeDiscount ?? 0.0)

let freemiumExpBoost = Computed(@()
  (curFreemiumBonuses.value?.armyEffects.freemiumExpBoost.tointeger() ?? 0) + 1)

console_register_command(function() {
  let { id = "" } = curFreemiumShopItem.value
  if (id == "")
    return
  get_shop_item(id, console_print)
}, "freemium.buy")

console_register_command(@()
  console_print($"item: {curFreemiumShopItem.value?.id}",
    $"camp: {isFreemiumCampaign.value}",
    $"bought: {isFreemiumBought.value}"),
  "freemium.info")

console_register_command(@() apply_freemium(curCampaign.value), "freemium.apply")

return {
  isFreemiumCampaign
  isFreemiumBought
  curFreemiumShopItem
  curUpgradeDiscount
  freemiumUpgradeDiscount
  freemiumExpBoost
  needFreemiumStatus
}
