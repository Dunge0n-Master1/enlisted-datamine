from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { goodsInfo } = require("%enlist/shop/goodsAndPurchases_pc.nut")
let { purchasesCount, squadsByArmies } = require("%enlist/meta/profile.nut")
let { isPlatformRelevant } = require("%dngscripts/platform.nut")


let shopItemsBase = Computed(function() {
  let ownedSquads = squadsByArmies.value
  let shopItems = configs.value?.shop_items ?? {}
  shopItems.each(function(shopItem) {
    let { squads = [], shopItemPrice = null } = shopItem
    let { price = 0 } = shopItemPrice
    let additionalPrice = squads.reduce(function(sum, squadData) {
      let { armyId, id, priceLink = "" } = squadData
      if (priceLink == "")
        return sum

      let hasSquad = (ownedSquads?[armyId] ?? {}).findvalue(@(s) s.squadId == id) != null
      return hasSquad ? sum : sum + (shopItems?[priceLink].shopItemPrice.price ?? 0)
    }, 0)
    if (additionalPrice > 0) {
      if ("basePrice" not in shopItem.shopItemPrice)
        shopItem.shopItemPrice.basePrice <- price
      shopItem.shopItemPrice.price = shopItem.shopItemPrice.basePrice + additionalPrice
    }
  })
  return shopItems
})
let shopDiscountGen = Watched(0)

let function calcPriceWithDiscount(priceData, priceIncrement, discountInPercent) {
  let price = (priceData?.price ?? 0) + priceIncrement
  let res = priceData.__merge({ price, fullPrice = price })
  if (discountInPercent <= 0)
    return res

  res.price = price - price * discountInPercent / 100
  return res
}

let shopTreeRoute = Computed(function() {
  let res = {}
  let items = shopItemsBase.value
  foreach (item in items){
    let { offerContainer = "" } = item
    if (offerContainer == "")
      continue
    foreach (army in item.armies){
      if (army not in res)
        res[army] <- {}
      res[army][offerContainer] <- item.id
    }
  }
  return res
})

let function isInInterval(ts, interval = []){
  if (interval.len() == 0)
    return true
  let [from, to = 0] = interval
  return ts >= from && (to == 0 || ts < to)
}

let priorityDiscounts = Watched({})

let function updateItemCost(sItem, purchases) {
  local { shopItemPrice, discountInPercent = 0, discountIntervalTs = [] } = sItem
  local curItem = sItem
  let allItems = shopItemsBase.value
  let itemArmy = sItem?.armies[0] ?? ""
  let sTime = serverTime.value
  if (!isInInterval(sTime, discountIntervalTs))
    discountInPercent = 0
  while (curItem && (curItem?.offerGroup ?? "") != ""){
    curItem = allItems?[shopTreeRoute.value?[itemArmy][curItem.offerGroup]]
    if ((curItem?.discountInPercent ?? 0) > discountInPercent
      && isInInterval(sTime, curItem?.discountIntervalTs)){
      discountInPercent = curItem.discountInPercent
      discountIntervalTs = curItem?.discountIntervalTs ?? []
    }
  }
  sItem.discountInPercent <- discountInPercent
  sItem.discountIntervalTs <- discountIntervalTs

  let amount = purchases?[sItem?.id].amount ?? 0
  let priceIncrement = amount * (sItem?.shopItemPriceInc ?? 0)
  sItem.curShopItemPrice <- calcPriceWithDiscount(shopItemPrice, priceIncrement, discountInPercent)

  return sItem
}

let function updateStoreItemCost(sItem, gItem) {
  let item = {}.__update(sItem, gItem)
  let showCountdown = (gItem?.discount_countdown ?? "0") != "0" //original param name is show_countdown, string
  let discountInPercent = gItem?.discount_mul ? ((100 * (1.0 - gItem.discount_mul)) + 0.5).tointeger() : 0
  local discountIntervalTs = []
  if (showCountdown && gItem?.discount_till && serverTime.value < gItem.discount_till)
    discountIntervalTs = [ serverTime.value, gItem.discount_till ]

  let resItem = item.__update({ discountInPercent, discountIntervalTs,
    curShopItemPrice = { price = 0, fullPrice = 0 } })
  return resItem
}

let shopItems = Computed(function() {
  // simple increment, we don't actually need its value, just an update trigger
  let needsUpdate = shopDiscountGen.value //warning disable: -declared-never-used
  let discounts = priorityDiscounts.value
  let items = shopItemsBase.value
  let goods = goodsInfo.value
  return items
    .filter(function(item) {
      let { offerContainer = "" } = item
      if (offerContainer == "")
        return isPlatformRelevant(item?.platforms ?? [])

      return items.findvalue(@(i) i?.offerGroup == offerContainer
        && isPlatformRelevant(i?.platforms ?? [])) != null
    })
    .map(function(item, guid) {
      local newItem = item.__merge({ guid, curItemCost = item?.itemCost ?? {} })

      let offerDiscount = guid not in discounts ? {}
        : {
            discountInPercent = discounts[guid]
            discountIntervalTs = []
          }
      newItem.__update(offerDiscount, goodsInfo.value?[item?.purchaseGuid] ?? {})
      newItem = updateItemCost(newItem, purchasesCount.value)

      if (goods?[newItem?.pcLinkGuid] && (newItem?.curShopItemPrice.fullPrice ?? 0) == 0)
        //Item from web store
        newItem = updateStoreItemCost(newItem, goods[newItem.pcLinkGuid])

      return newItem
    })
})

return {
  shopItemsBase
  shopItems
  shopDiscountGen
  priorityDiscounts
}
