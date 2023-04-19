from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let isChineseVersion = require("%enlSqGlob/isChineseVersion.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { curArmy, armySquadsById, armyItemCountByTpl
} = require("%enlist/soldiers/model/state.nut")
let { shopItems } = require("shopItems.nut")
let { purchasesCount } = require("%enlist/meta/profile.nut")
let { hasClientPermission } = require("%enlSqGlob/client_user_rights.nut")
let { curUnseenAvailShopGuids, notOpenedShopItems } = require("armyShopState.nut")


let isDebugShowPermission = hasClientPermission("debug_shop_show")

let shopConfig = Computed(@() configs.value?.shop_config ?? {})

let curSwitchTime = Watched(0)

let function updateSwitchTime(...) {
  let currentTs = serverTime.value
  let nextTime = shopItems.value.reduce(function(firstTs, item) {
    let { showIntervalTs = null } = item
    if ((showIntervalTs?.len() ?? 0) == 0)
      return firstTs

    let [from, to = 0] = showIntervalTs
    return (currentTs < from && (from < firstTs || firstTs == 0)) ? from
      : (currentTs < to && (to < firstTs || firstTs == 0)) ? to
      : firstTs
  }, 0) - currentTs
  if (nextTime > 0)
    gui_scene.resetTimeout(nextTime, updateSwitchTime)
  curSwitchTime(currentTs)
}

serverTime.subscribe(function(t) {
  if (t <= 0)
    return
  serverTime.unsubscribe(callee())
  updateSwitchTime()
})
shopItems.subscribe(updateSwitchTime)

let shownByTimestamp = Computed(function() {
  let res = {}
  let ts = curSwitchTime.value
  foreach (id, item in shopItems.value) {
    let { showIntervalTs = null } = item
    if ((showIntervalTs?.len() ?? 0) == 0)
      continue

    let [from, to = 0] = showIntervalTs
    if (from <= ts && (ts < to || to == 0))
      res[id] <- true
  }
  return res
})


let function canBarterItem(item, armyItemCount) {
  foreach (payItemTpl, cost in item.curItemCost)
    if ((armyItemCount?[payItemTpl] ?? 0) < cost)
      return false
  return true
}

let isTemporaryVisible = @(itemId, shopItem, itemCount, itemsByTime)
  ((shopItem?.isVisibleIfCanBarter ?? false) && canBarterItem(shopItem, itemCount))
    || itemId in itemsByTime

let isAvailableBySquads = function(shopItem, squadsByArmyV) {
  foreach (squadData in shopItem?.squads ?? []) {
    let { id, squadId = null, armyId = null } = squadData
    let squad = squadsByArmyV?[armyId][squadId ?? id]
    if (squad != null && (squad?.expireTime ?? 0) == 0)
      return false
  }
  return true
}

let isAvailableByLimit = @(sItem, purchases)
  (sItem?.limit ?? 0) <= 0 || sItem.limit > (purchases?[sItem?.id].amount ?? 0)

let isAvailableByPermission = @(sItem, isDebugShow)
  !(sItem?.isShowDebugOnly ?? false) || isDebugShow

let curArmyItemsPrefiltered = Computed(function() {
  let armyId = curArmy.value
  let itemCount = armyItemCountByTpl.value ?? {}
  let itemsByTime = shownByTimestamp.value
  let squadsById = armySquadsById.value
  let purchases = purchasesCount.value
  let debugPermission = isDebugShowPermission.value
  let shopItemsList = shopItems.value.filter(function(item, id) {
    let { armies = [], offerContainer = "", isHidden = false, isHiddenOnChinese = false } = item
    return (armies.contains(armyId) || armies.len() == 0)
      && offerContainer == ""
      && (!isHidden || isTemporaryVisible(id, item, itemCount, itemsByTime))
      && !(isChineseVersion && isHiddenOnChinese)
      && isAvailableBySquads(item, squadsById)
      && isAvailableByLimit(item, purchases)
      && isAvailableByPermission(item, debugPermission)
  })
  return shopItemsList
})


let baseOrders = {
  weapon_order = true
  soldier_order = true
  weapon_order_silver = true
  soldier_order_silver = true
}

let function hasBaseOrderInPrice(shopItem) {
  foreach (orderId, price in shopItem?.itemCost ?? {})
    if (orderId in baseOrders && price > 0)
      return true

  return false
}

let function hasPriceContainsGold(shopItem) {
  let { price = 0, currencyId = "" } = shopItem?.shopItemPrice
  return currencyId == "EnlistedGold" && price > 0
}

let function hasPriceContainsOrders(shopItem) {
  let { itemCost = {} } = shopItem
  return itemCost.len() > 0
}

let function isExternalPurchase(shopItem) {
  let { shop_price = 0, shop_price_curr = "", storeId = "", devStoreId = "" } = shopItem
  return (shop_price_curr != "" && shop_price > 0) //PC type
    || storeId != "" || devStoreId != ""//Consoles type
}


let armyGroups = [
  {
    id = "premium"
    reqFeatured = true
    filterFunc = @(shopItem) !hasPriceContainsOrders(shopItem)
      && (hasPriceContainsGold(shopItem) || isExternalPurchase(shopItem))
  }
  {
    id = "battlepass"
    filterFunc = @(shopItem)
      hasPriceContainsOrders(shopItem) && !hasBaseOrderInPrice(shopItem)
  }
]


let sortItemsFunc = @(a, b)
  (a?.requirements.armyLevel ?? 0) <=> (b?.requirements.armyLevel ?? 0)

let sortFeaturedFunc = @(a, b)
  (a?.featuredWeight ?? 0) <=> (b?.featuredWeight ?? 0)
    || (a?.requirements.armyLevel ?? 0) <=> (b?.requirements.armyLevel ?? 0)


let curGroupIdx = Watched(0)
let curFeaturedIdx = Watched(0)


let curItemsByGroup = Computed(function() {
  let prefilteredItems = curArmyItemsPrefiltered.value
  let res = {}
  foreach (group in armyGroups)
    res[group.id] <- prefilteredItems.filter(group.filterFunc).values().sort(sortItemsFunc)

  return res
})


let curShopItemsByGroup = Computed(function() {
  let items = curItemsByGroup.value
  return armyGroups.map(@(group) {
    id = group.id
    goods = (items?[group.id] ?? []).filter(@(item) (item?.featuredWeight ?? 0) == 0)
  })
})


let maxDiscountByGroup = Computed(@() curItemsByGroup.value
  .map(@(group) group.reduce(@(r, v) max(r, v?.hideDiscount ? 0 : v?.discountInPercent ?? 0), 0)))

let specialOfferByGroup = Computed(@() curItemsByGroup.value
  .map(@(group) group
    .findvalue(@(v) (v?.discountInPercent ?? 0) > 0 && v?.showSpecialOfferText) != null))

let curFeaturedByGroup = Computed(@() curItemsByGroup.value
  .map(@(group) group
    .filter(@(item) (item?.featuredWeight ?? 0) > 0)
    .sort(sortFeaturedFunc)
  ))


let curShopDataByGroup = Computed(function() {
  let curUnseen = curUnseenAvailShopGuids.value
  let curUnopened = {}
  foreach (guid in notOpenedShopItems.value)
    curUnopened[guid] <- true

  let maxDiscounts = maxDiscountByGroup.value
  let specialOffer = specialOfferByGroup.value
  let res = {}
  foreach (id, group in curItemsByGroup.value)
    res[id] <- {
      hasUnseen = group.findvalue(@(v) v.guid in curUnseen) != null
      unopened = group.filter(@(v) v.guid in curUnopened).map(@(v) v.guid)
      discount = maxDiscounts?[id] ?? 0
      showSpecialOffer = specialOffer?[id] ?? false
    }

  return res
})


return {
  curShopItemsByGroup
  curShopDataByGroup
  curFeaturedByGroup
  curGroupIdx
  curFeaturedIdx
  shopConfig
}
