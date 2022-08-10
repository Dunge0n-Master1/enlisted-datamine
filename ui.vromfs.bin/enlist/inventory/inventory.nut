from "%enlSqGlob/ui_library.nut" import *

let {parse_unix_time} = require("dagor.iso8601")
let {toIntegerSafe} = require("%sqstd/string.nut")

let {get_circuit_conf, encode_uri_component} = require("app")
let inventoryClient = require("%enlist/inventory/inventoryClient.nut")
let {inventoryItems, inventoryItemsAmounts, inventoryItemdefs, refreshItems, refreshAllItemDefs} = inventoryClient
let { appId } = require("%enlSqGlob/clientState.nut")
let openUrl = require("%ui/components/openUrl.nut")
let { getShopUrl, getUrlByGuid } = require("%enlist/shop/shopUrls.nut")
let extAutoRefreshTimer = require("%enlist/state/extAutoRefreshTimer.nut")

let showHiddenItems = mkWatched(persist, "showHiddenItems", false)
console_register_command( @() showHiddenItems(!showHiddenItems.value), "feature.toggle.showHiddenItems")

let allowMarket = mkWatched(persist, "allowMarket", false)
console_register_command( @() allowMarket(!allowMarket.value), "feature.toggle.allowMarket")

let MARKETPLACE_URL = get_circuit_conf()?.marketplaceURL

let AUTO_REFRESH_ITEMS_DELAY = 30.0 //sec between several window inactivates without mve to shop link
let CHECK_PURCHASED_PERIOD = 10.0 //sec to check purchases after return back to game after shop link
let MAX_PURCHASES_CHECK = 6 //amount of purchases check after back from shopLink

let getItemPurchaseUrl = @(itemdef) getUrlByGuid(itemdef.tags?.guid ?? itemdef.granted_by_purch ?? "")

let function getMarketplaceUrl(itemdef)  {
  local url = MARKETPLACE_URL
  if ( url == null )
    return null

  if (appId.value > 0)  {
    url = $"{url}?a={appId.value}"

    let market_hash = itemdef && itemdef?.market_hash_name
    if ( market_hash )
      url = $"{url}&viewitem&n={encode_uri_component(market_hash)}"
  }

  return url
}

let canBuyOnMarket = @(itemdef) (MARKETPLACE_URL != null) && (itemdef?.marketable ?? false) && allowMarket.value

let function canBuyInIngameShop(itemdef) {
  if (!itemdef.tags?.guid && itemdef.granted_by_purch == "")
    return false

  if (!itemdef.tags?.unique_item || !inventoryItemsAmounts.value?[itemdef.itemdefid])
    return true

  return false
}

let { refreshOnWindowActivate } = extAutoRefreshTimer({
  refresh = refreshItems
  refreshDelaySec = AUTO_REFRESH_ITEMS_DELAY
})
let inventoryRefreshOnWindowActivate =
  @() refreshOnWindowActivate(MAX_PURCHASES_CHECK, CHECK_PURCHASED_PERIOD)

let function openItemUrl(itemdef) {
  if (canBuyOnMarket(itemdef)) {
    let url = getMarketplaceUrl(itemdef)
    if (url != null)
      openUrl(url)
    return url != null
  }

  let url = getItemPurchaseUrl(itemdef)
  if (url == null)
    return false
  openUrl(url)
  inventoryRefreshOnWindowActivate()
  return true
}

let function openShopByGuid(guid) {
  let url = getUrlByGuid(guid)
  if (url == null)
    return false
  openUrl(url)
  inventoryRefreshOnWindowActivate()
  return true
}

let makeShopItem = @(itemdef) {
  itemid = ""
  isShopItem = true
  quantity = 1
  itemdef
}

let function makeShopItemsList(itemdefList, needHidden) {
  let res = {}
  foreach (key, itemdef in itemdefList)
    if (itemdef.len()>0 && (needHidden || !itemdef?.hidden))
      res[key] <- makeShopItem(itemdef)
  return res
}

let iso8601Cache = persist("iso8601Cache", @() { [""] = 0 })
let function getExpireTimeStamp(itemOrItemdef) {
  local timestampStr = itemOrItemdef?.expireAt
  if (!timestampStr || timestampStr == "")
    timestampStr = itemOrItemdef?.itemdef?.expireAt ?? ""
  if (timestampStr in iso8601Cache)
    return iso8601Cache?[timestampStr]
  local timestamp = toIntegerSafe(timestampStr, 0, false)
  if (!timestamp) { //support of old format of expireAt
    timestamp = parse_unix_time(timestampStr)
    iso8601Cache[timestampStr] <- timestamp
  }
  return timestamp
}

let lifetimeSuffixToSecMul = {
  s = 1
  m = 60
  h = 3600
  d = 86400
  w = 604800
}

let lifetimeCache = persist("lifetimeCache", @() { [""] = 0 })
let function getLifetimeSec(lifetimeStr) {
  if (lifetimeStr in lifetimeCache)
    return lifetimeCache[lifetimeStr]
  let count = toIntegerSafe(lifetimeStr.slice(0, -1), 0, true)
  let suffix = lifetimeStr.slice(-1)
  assert(suffix in lifetimeSuffixToSecMul, "Unknown suffix in itemdef lifetime")
  let res = count * (lifetimeSuffixToSecMul?[suffix] ?? 0)
  lifetimeCache[lifetimeStr] <- res
  return res
}

let function inventoryRefresh(){
  refreshAllItemDefs()
  refreshItems()
}

console_register_command(@() refreshItems(), "inventory.refresh_items")
console_register_command(
  @() console_print(inventoryItems.value.map(@(item) item.itemdef.name ?? "unknown")),
  "inventory.show_items")
console_register_command(
  @() console_print(inventoryItemdefs.value.map(@(itemdef) itemdef.name ?? "unknown")),
  "inventory.show_itemdefs")
console_register_command(@()
  log(inventoryItems.value.map(@(item) item.__merge({ itemdef = item.itemdef.itemdefid }))) ?? log("Done."),
  "inventory.debug_items")
console_register_command(@() log(inventoryItemdefs.value) ?? log("Done."),
  "inventory.debug_itemdefs")

//return 1 when expireAtStr1 happen early, and -1 when later. 0 when simultaneously
let function compareExpireAtStr(item1, item2) {
  let expireTs1 = getExpireTimeStamp(item1)
  let expireTs2 = getExpireTimeStamp(item2)
  return expireTs1 == expireTs2 ? 0
    : expireTs1 <= 0 ? -1
    : expireTs2 <= 0 ? 1
    : expireTs1 < expireTs2 ? 1
    : -1
}

let bunches_int = Computed(function() {
  let bunchCollection = {}
  let bunches = []
  foreach (item in inventoryItems.value) {
    if (!bunchCollection?[item.itemdef.itemdefid]) {
      bunchCollection[item.itemdef.itemdefid] <- {
        itemdef = item.itemdef
        itemid = item.itemid
        quantity = item.quantity
        expireAt = item?.expireAt ?? ""
        items = [item]
      }
      bunches.append(bunchCollection[item.itemdef.itemdefid])
      continue
    }

    let bunch = bunchCollection[item.itemdef.itemdefid]
    bunch.quantity += item.quantity

    let compareRes = compareExpireAtStr(item, bunch)
    let firstCmp = (bunch.itemdef.tags?.unique_item ?? false) ? -1 : 1 //for uniq item longer time, for other shorter.
    if (compareRes == firstCmp) {
      bunch.expireAt = item.expireAt
      bunch.items.insert(0, item)
      bunch.itemid = item.itemid
    }
    else
      bunch.items.append(item)
  }
  bunches.sort(@(a, b) a.itemdef.itemdefid <=> b.itemdef.itemdefid)
  return {bunches, bunchCollection}
})

let bunches = Computed(@() bunches_int.value.bunches)
let bunchByItemdefid = Computed(@() bunches_int.value.bunchCollection)
let shopItems = Computed(@() makeShopItemsList(inventoryItemdefs.value, showHiddenItems.value))
let function openShopUrl(){
    openUrl(getShopUrl())
    inventoryRefreshOnWindowActivate()
}

return inventoryClient.__merge({
  openShopUrl
  shopItems
  bunchByItemdefid
  allowMarket
  inventoryRefresh
  inventoryBunches = bunches
  getItemPurchaseUrl
  openItemUrl
  openShopByGuid
  canBuyInIngameShop
  canBuyOnMarket
  getExpireTimeStamp
  getLifetimeSec
})
