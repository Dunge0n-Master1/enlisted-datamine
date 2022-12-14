from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let isChineseVersion = require("%enlSqGlob/isChineseVersion.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { curArmy, armySquadsById, armyItemCountByTpl
} = require("%enlist/soldiers/model/state.nut")
let { shopItems } = require("shopItems.nut")
let { purchasesCount } = require("%enlist/meta/profile.nut")
let { hasClientPermission } = require("%enlSqGlob/client_user_rights.nut")


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


let hasSquadsInShopItem = @(shopItem) (shopItem?.squads ?? []).len() > 0

let armyGroups = [
  {
    id = "squads"
    filterFunc = @(shopItem) hasSquadsInShopItem(shopItem)
  }
  {
    id = "other"
    filterFunc = @(shopItem) !hasSquadsInShopItem(shopItem) && !hasBaseOrderInPrice(shopItem)
  }
]

let sortFunc = @(a,b)
  (a?.requirements.armyLevel ?? 0) <=> (b?.requirements.armyLevel ?? 0)

let curGroupIdx = mkWatched(persist, "curGroupIdx", 0)


let curArmyItemsByGroup = Computed(function() {
  let prefilteredItems = curArmyItemsPrefiltered.value
  let res = armyGroups.map(@(group) {
    id = group.id
    goods = prefilteredItems.filter(group.filterFunc).values().sort(sortFunc)
  })
  return res
})


return {
  curArmyItemsByGroup
  curGroupIdx
  shopConfig
}