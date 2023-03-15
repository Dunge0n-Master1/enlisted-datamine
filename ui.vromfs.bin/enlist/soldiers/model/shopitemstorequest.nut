from "%enlSqGlob/ui_library.nut" import *
let { SHOP_SECTION, curArmyShopItems } = require("%enlist/shop/armyShopState.nut")
let { curSection } = require("%enlist/mainMenu/sectionsState.nut")
let { getShopItemsIds, requestCratesContent } = require("%enlist/soldiers/model/cratesContent.nut")

let shopItemsToRequest = keepref(Computed(function() {
  return curSection.value == SHOP_SECTION ? getShopItemsIds(curArmyShopItems.value) : {}
}))

shopItemsToRequest.subscribe(@(v) v.each(@(items, army) requestCratesContent(army, items)))