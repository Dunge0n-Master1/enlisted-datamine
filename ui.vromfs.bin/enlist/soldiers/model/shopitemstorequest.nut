from "%enlSqGlob/ui_library.nut" import *
let { SHOP_SECTION, curArmyShopItems } = require("%enlist/shop/armyShopState.nut")
let { curSection } = require("%enlist/mainMenu/sectionsState.nut")
let { getShopItemsIds, requestCratesContent } = require("%enlist/soldiers/model/cratesContent.nut")
let { metaGen } = require("%enlist/meta/metaConfigUpdater.nut")

let shopItemsToRequest = keepref(Computed(function() {
  return curSection.value == SHOP_SECTION ? getShopItemsIds(curArmyShopItems.value) : {}
}))

shopItemsToRequest.subscribe(@(v) v.each(@(items, army) requestCratesContent(army, items)))
metaGen.subscribe(@(v) v == 0 ? null // meta is default, no need to update
  : shopItemsToRequest.value.each(@(items, army) requestCratesContent(army, items)))