from "%enlSqGlob/ui_library.nut" import *

/*
Should be rewritten mostly
*/

let {startsWith, toIntegerSafe, split} = require("%sqstd/string.nut")
let {logerr} = require("dagor.debug")
let {throttle} = require("%sqstd/timers.nut")
let netUtils = require("%enlist/netUtils.nut")
let loginState = require("%enlSqGlob/login_state.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let inventory = require("inventory")
let inventoryValidator = require("inventoryValidator.nut")
let {get_time_msec} = require("dagor.time")
let userInfo = require("%enlSqGlob/userInfo.nut")
let chardToken = keepref(Computed(@() userInfo.value?.token))
let { appId, gameLanguage } = require("%enlSqGlob/clientState.nut")

//when shouldRequestAllItemdefs - request full itemdefs list
//when !shouldRequestAllItemdefs - request all known itemdefs list
let shouldRequestAllItemdefs = mkWatched(persist, "shouldRequestAllItemdefs", true)
let onErrorRepeatRequesDelaySec = 15
let errorLogMaxLen = 10
let errorLog = mkWatched(persist, "errorLog", [])
let lastRequestSuccesTime = mkWatched(persist, "lastRequestSuccesTime", 0)
let importantActions = ["CheckPurchases", "GetInventory", "GetItemDefsClient"]

let function checkError(action, result) {
  let isImportant = importantActions.indexof(action) != null
  if (result?.error == null) {
    if (isImportant)
      lastRequestSuccesTime(get_time_msec())
    return
  }
  errorLog.mutate(function(l) {
    l.append({ action, result, time = get_time_msec(), isImportant })
    if (l.len() > errorLogMaxLen)
      l.remove(0)
  })
}

let dbgInventoryFailed = Watched(false)
console_register_command(@() dbgInventoryFailed(!dbgInventoryFailed.value), "inventory.fail")

let isInventoryFailedGetData = Computed(function() {
  let importantLogs = errorLog.value.filter(@(l) l.isImportant)
  return dbgInventoryFailed.value || (importantLogs.len() > 0
    && (lastRequestSuccesTime.value <= 0 || importantLogs.top().time > lastRequestSuccesTime.value))
})

let function request(action, headers, data, callback) {
  if (chardToken.value==null || appId.value <= 0) {
    logerr("inventoryClient callback with chardToken = {0} and appId = {1}".subst(chardToken.value, appId.value))
    callback({})
    return
  }

  let requestData = {
    headers = headers.__merge({
      appid = appId.value
      token = chardToken.value
    })
    action = action
  }

  if (data)
    requestData["data"] <- data

  inventory.request(requestData,
    @(result) netUtils.error_response_converter(
      function(res) {
        checkError(action, res)
        callback(res)
      },
      result)
  )
}

let timers = {}
let function stopRepeatUpdateTimer(name) {
  if (name in timers)
    gui_scene.clearTimer(delete timers[name])
}

let function startRepeatUpdateTimer(name, cb) {
  stopRepeatUpdateTimer(name)
  let function callback() {
    stopRepeatUpdateTimer(name)
    if (chardToken.value && appId.value >= 0)
      cb()
  }
  timers[name] <- callback
  gui_scene.setTimeout(onErrorRepeatRequesDelaySec, callback)
}

loginState.isLoggedIn.subscribe(function(logged) {
  if (logged == false) {
    foreach (v in timers)
      gui_scene.clearTimer(v)
    timers.clear()
  }
})

let itemsInternal = mkWatched(persist, "itemsInternal", {allItems={}, inventoryItemsAmounts={}, shouldUpdateItemsDefs = false, areItemsReceived=false, areItemsItemdefsReceived=false})
let itemdefs = mkWatched(persist, "itemdefs", {})
let allItems = Computed(@() itemsInternal.value.allItems) //all items, even items without known itemdefs
let inventoryItemsAmounts = Computed(function(_prev) { //inventory items amount by itemdefs - todo, optimize when no changes
  return itemsInternal.value.inventoryItemsAmounts
})
let areItemsReceived = Computed(@() itemsInternal.value.areItemsReceived)
let areItemsItemdefsReceived = Computed(@() itemsInternal.value.areItemsItemdefsReceived)
let itemShopConfig = mkWatched(persist, "itemShopConfig", {}) //item shop confi
let premiumTimestamp = mkWatched(persist, "premiumTimestamp", -1)
let isExchangeInProgress = Watched(false)
let isPurchaseInProgress = Watched(false)

const REQUEST_TIMEOUT_MSEC = 15000

let function addItemDefIdToRequest(itemdefid) {
  if (itemdefid in itemdefs.value)
    return false
  itemdefs.value[itemdefid] <- {}
  return true
}

local lastUpdateTime = -1
local lastRequestTime = -1
local refreshCbList = []
local needRefreshItemsAgain = false //to refresh items right after refresh complete. Need to force refresh on notification

local lastItemdefsRequestTime = -1
let itemdefidsRequested = {} // Failed ids stays here, to avoid repeated requests.
local pendingItemDefRequest = null

let function requestItemPurchaseOffers() {
  let self = callee()
  request("GetItemPurchaseOffers", {}, null, function(result){
    let isError = result?.error != null
    if (isError) {
      startRepeatUpdateTimer("GetItemPurchaseOffers", self)
      return
    }
    stopRepeatUpdateTimer("GetItemPurchaseOffers")
    itemShopConfig(result?.response?.offers ?? {})
  })
}

let function getResultData(result, name) {
  let data = result?.response?[name]
  return inventoryValidator.validate(data, name)
}

let isItemsRequestInProgress = @() lastRequestTime >= 0
  && lastRequestTime >= lastUpdateTime
  && lastRequestTime + REQUEST_TIMEOUT_MSEC > get_time_msec()

local refreshItems
local refreshAllItemDefs
local requestItemDefsImpl

let function fireRefreshCb() {
  if (needRefreshItemsAgain) {
    refreshItems()
    return
  }

  let cbs = refreshCbList
  refreshCbList = []
  foreach (cb in cbs)
    cb()
}


let function onRefreshItemsResult(result, _cb) {
  lastUpdateTime = get_time_msec()
  let isError = result?.error != null
  let premium = result?.response?.premium ?? (isError ? premiumTimestamp.value : -1)
  premiumTimestamp(toIntegerSafe(premium, -1))
  log("Received items")
  let itemJson = getResultData(result, "item_json")
  if (itemJson==null) { //empty inventory
    log("Emtpty items")
    itemsInternal.update({
      areItemsReceived = true
      areItemsItemdefsReceived = true
      shouldUpdateItemsDefs = true
      inventoryItemsAmounts = {}
      allItems = {}
    })
    fireRefreshCb()
    return
  }

  local shouldUpdateItemsDefs = false
  let allItemsRes = {}
  let inventoryItemsAmountsRes = {}
  foreach (item in itemJson) {
    if (item.quantity > 0) {
      let itemdefid = item.itemdef
      let shouldUpdateItemDef = addItemDefIdToRequest(itemdefid)
      item.itemdef = itemdefs.value[item.itemdef]
      allItemsRes[item.itemid] <- item
      inventoryItemsAmountsRes[itemdefid] <- item.quantity + (inventoryItemsAmountsRes?[itemdefid] ?? 0)
      shouldUpdateItemsDefs = shouldUpdateItemDef || shouldUpdateItemsDefs
    }
  }
  itemsInternal.update({
    allItems = allItemsRes
    inventoryItemsAmounts = inventoryItemsAmountsRes
    shouldUpdateItemsDefs = shouldUpdateItemsDefs
    areItemsItemdefsReceived = !shouldUpdateItemsDefs
    areItemsReceived = true
  })
  fireRefreshCb()
}

let lastItemsAmount = {}

inventoryItemsAmounts.subscribe(function(items) {
  log("inventoryItemsAmounts")
  let diff = {}
  foreach (id, count in items)
    if (lastItemsAmount?[id] != count)
      diff[id] <- count
  if (diff.len() == 0) {
    log("no changes")
    return
  }

  let diffList = diff.reduce(function(list, count, id) {
    if (id not in lastItemsAmount)
      list.append($"{id}:{count}")
    else {
      let diffCount = count - lastItemsAmount[id]
      list.append("{0}:{1}({2})".subst(id, count, diffCount > 0 ? $"+{diffCount}" : diffCount))
    }
    return list
  }, [])
  log($"update: {", ".join(diffList)}")
  lastItemsAmount.__update(diff)
})

refreshItems = function _refreshItems(cb = null) {
  log("refreshItems called")
  if (cb)
    refreshCbList.append(cb)
  if (isItemsRequestInProgress())
    return

  needRefreshItemsAgain = false
  lastRequestTime = get_time_msec()
  request("CheckPurchases", {}, null,
    function(result) {
      lastUpdateTime = get_time_msec()
      let isError = result?.error != null
      if (!isError)
        stopRepeatUpdateTimer("CheckPurchases")
      else {
        startRepeatUpdateTimer("CheckPurchases", refreshItems)
        if (startsWith(result.error, "INVENTORY_PURCH_REQUEST_FAILED") && !getResultData(result, "item_json")) {
          //when we got purch error, we can get items list from basic inventory request
          request("GetInventory", {}, null, (@(result2) onRefreshItemsResult(result2, cb)))
          return
        }
      }

      onRefreshItemsResult(result, cb)
    }
  )
}

let function forceRefreshItems() {
  needRefreshItemsAgain = true
  refreshItems()
}

let isItemdefRequestInProgress = @() lastItemdefsRequestTime >= 0
  && lastItemdefsRequestTime + REQUEST_TIMEOUT_MSEC > get_time_msec()

let function updatePendingItemDefRequest(cb, shouldRefreshAll) {
  if (!pendingItemDefRequest)
    pendingItemDefRequest = {
      cbList = [],
      shouldRefreshAll = false,
      fireCb = function() {
        foreach (cbFunc in this.cbList)
          cbFunc()
      }
    }

  pendingItemDefRequest.shouldRefreshAll = shouldRefreshAll || pendingItemDefRequest.shouldRefreshAll
  if (cb)
    pendingItemDefRequest.cbList.append(cb)
}

let function addItemDef(itemdef) {
  let originalItemDef = itemdefs.value?[itemdef.itemdefid] || {}
  originalItemDef.clear()
  originalItemDef.__update(itemdef)
  itemdefs.value[itemdef.itemdefid] <- originalItemDef
}

requestItemDefsImpl = function() {
  if (isItemdefRequestInProgress() || !pendingItemDefRequest)
    return
  let requestData = pendingItemDefRequest
  pendingItemDefRequest = null

  if (requestData.shouldRefreshAll)
    itemdefidsRequested.clear()

  let params = {}
  if (!shouldRequestAllItemdefs.value || !requestData.shouldRefreshAll) {
    let itemdefidsRequest = []
    foreach (itemdefid, value in itemdefs.value) {
      if (!requestData.shouldRefreshAll && (!value.len() || itemdefidsRequested?[itemdefid]))
        continue

      itemdefidsRequest.append(itemdefid)
      itemdefidsRequested[itemdefid] <- true
    }

    if (!itemdefidsRequest.len())
      return requestData.fireCb()

    let itemdefidsString = ",".join(itemdefidsRequest, true)
    print($"Request itemdefs {itemdefidsString}")
    params.itemdefids <- itemdefidsString
  }

  lastItemdefsRequestTime = get_time_msec()
  params.internalLanguage <- gameLanguage
  params.language <- loc("steam/languageName", params.internalLanguage).tolower()
  request("GetItemDefsClient", params, null,
    function(result) {
      lastItemdefsRequestTime = -1
      let isError = result?.error != null
      if (isError)
        startRepeatUpdateTimer("GetItemDefsClient", refreshAllItemDefs)
      else
        stopRepeatUpdateTimer("GetItemDefsClient")

      let itemdef_json = getResultData(result, "itemdef_json");
      if (!itemdef_json || params.internalLanguage != gameLanguage) {
        requestData.fireCb()
        requestItemDefsImpl()
        return
      }

      foreach (itemdef in itemdef_json) {
        let itemdefid = itemdef.itemdefid
        if (itemdefid in itemdefidsRequested)
          delete itemdefidsRequested[itemdefid]
        addItemDef(itemdef)
      }

      itemdefs.trigger()
      requestData.fireCb()
      requestItemDefsImpl()
    })
}

let function requestItemDefs(cb = null, shouldRefreshAll = false) {
  log("requestItemDefs called")
  updatePendingItemDefRequest(cb, shouldRefreshAll)
  requestItemDefsImpl()
}

let function requestItemDefsCb(){
  itemsInternal.mutate(function(v) {
    v.shouldUpdateItemsDefs = false
    v.areItemsItemdefsReceived = true
  })
}
let shouldUpdateItemsDefs = Computed(@() itemsInternal.value.shouldUpdateItemsDefs)
let function checkShouldUpdateItemsDefs(...){
  if (!shouldUpdateItemsDefs.value)
    return
  requestItemDefs(requestItemDefsCb)
}

shouldUpdateItemsDefs.subscribe(checkShouldUpdateItemsDefs)
checkShouldUpdateItemsDefs()

let function requestItemdefsByIds(itemdefIdsList, cb = null) {
  foreach (itemdefid in itemdefIdsList)
    addItemDefIdToRequest(itemdefid)
  requestItemDefs(cb)
}

refreshAllItemDefs = @() requestItemDefs(null, true)

shouldRequestAllItemdefs.subscribe(function(should){
  if (should)
    refreshAllItemDefs()
})

let function refreshAll() {
  log("refresh All Inventory")
  refreshAllItemDefs()
  refreshItems()
  requestItemPurchaseOffers()
}

let function reset() {
  log("reset Inventory called")
  itemsInternal({allItems={}, inventoryItemsAmounts={}, shouldUpdateItemsDefs = false, areItemsReceived=false, areItemsItemdefsReceived=false})
  itemShopConfig({})
  itemdefs({})
  premiumTimestamp(-1)

  lastUpdateTime = -1
  lastRequestTime = -1
  lastItemdefsRequestTime = -1
  itemdefidsRequested.clear()
  pendingItemDefRequest = null
}

local function exchangeRequest(requestStr, materials, outputitemdefid, cb = null, shouldRefreshInventory = true) {
  if (isExchangeInProgress.value) {
    cb?({ error = "exchange in progress" })
    return
  }
  materials = materials.filter(@(v) v?[1] !=0)
  let req = {
    outputitemdefid
    materials
  }
  isExchangeInProgress(true)
  let callback = function(result) {
    isExchangeInProgress(false)
    cb?(result)
  }
  request(requestStr, {}, req,
    function(result) {
      if (!result?.error && shouldRefreshInventory)
        refreshItems(@() callback(result))
      else
        callback(result)
    }
  )
}
//exchange list of items by ther itemdefids, target defined by defined. materials are = [[itemdid, quantity_to_spend]]
//callback have a result argument (table)
let function exchangeItems(materials, outputitemdefid, cb = null, shouldRefreshInventory = true) {
  exchangeRequest("ExchangeItems", materials, outputitemdefid, cb, shouldRefreshInventory)
}

//exchange list of items by ther itemdefids, target defined by defined. materials are = [[itemdefid, quantity_to_spend]]
//callback have a result argument (table)
let function exchangeItemsByItemdefs(materials, outputitemdefid, cb = null, shouldRefreshInventory = true) {
  exchangeRequest("ExchangeItemsByItemdefs", materials, outputitemdefid, cb, shouldRefreshInventory)
}


let function signItems(itemsList, cb) {
  let params = {
    items = itemsList.map(@(it) it.itemid)
  }
  request("SignItems", {}, params, cb)
}

let function markSeen(itemIdsList, cb = null) {
  local hasChanges = false
  let newAllItems = clone itemsInternal.value.allItems
  foreach (id in itemIdsList)
    if (id in newAllItems && !(newAllItems[id]?.seenByPlayer ?? false)) {
      hasChanges = true
      newAllItems[id] <- newAllItems[id].__merge({ seenByPlayer = true }) //we no need to wait answer to mark them local
    }
  if (!hasChanges)
    return

  itemsInternal(itemsInternal.value.__merge({ allItems = newAllItems }))
  request("SetSeenByPlayer", {}, { items = itemIdsList }, cb ?? @(_) null)
}

let function purchaseItemByOffer(offer, cb = null) {
  if (isPurchaseInProgress.value) {
    cb?({ error = "putchase in progress" })
    return
  }
  let params = {
    itemdefid = offer.itemdefid
    quantity = 1
    currency = offer.shop_price_curr
    price = offer.shop_price
    offer = offer.inventory_offer_name
  }
  isPurchaseInProgress(true)
  let callback = function(result) {
    isPurchaseInProgress(false)
    cb?(result)
  }
  request("PurchaseItemByOffer", params, null,
    function(result) {
      if (!result?.error)
        refreshItems(@() callback(result))
      else
        callback(result)
    }
  )
}

//if specific itemdefids requested - request is not throttled
let function requestPricesRaw(params, cb) {
  let {currencyId, itemdefids = null} = params
  assert (itemdefids == null || (type(itemdefids)=="array" && itemdefids.len()>0), "itemdefids should be non empty array or null")
  local data = null
  if (itemdefids!=null)
    data = {itemdefids}
  request("GetItemPrices", {currency = currencyId}, data, cb)
}

let requestPrices = throttle(requestPricesRaw, 10, {leading=true, trailing=false})

let function purchaseItem(description, cb = null) {
  if (isPurchaseInProgress.value) {
    cb?({ error = "putchase in progress" })
    return
  }
  let {itemdefid, quantity=1, currencyId=null, price=null} = description
  if (price == null || currencyId==null ) {
    log("purchaseItem: price and currencyId should be specified", itemdefid)
    cb?({error = "price and currencyId should be specified"})
    return
  }
  isPurchaseInProgress(true)
  let callback = function(result) {
    isPurchaseInProgress(false)
    cb?(result)
  }
  request("ClnPurchaseItem", {itemdefid, quantity, currency=currencyId, price}, null,
    function(result) {
      if (!result?.error)
        refreshItems(@() callback(result))
      else
        callback(result)
    }
  )
}

let splitstr = @(str, sep) split(str, sep, true)
let function parseItemStr(itemStr) {
  let pair = splitstr(itemStr, "x")
  if (pair.len()==0)
    return null
  return {
    itemdefid = toIntegerSafe(pair[0], -1)
    quantity  = (1 in pair) ? toIntegerSafe(pair[1]) : 1
  }
}
let cacheBundles = persist("cacheBundles", @() {})
let parseBundle = memoize(@(bundleStr)
  split(bundleStr, ";").map(parseItemStr).filter(@(v) v != null), null, cacheBundles)

let function onAppIdOrTokenChanged() {
  if (chardToken.value && appId.value >= 0)
    refreshAll()
  else
    reset()
}

appId.subscribe(@(_) onAppIdOrTokenChanged())
chardToken.subscribe(@(_) onAppIdOrTokenChanged())

if (!areItemsReceived.value || !areItemsItemdefsReceived.value)
  onAppIdOrTokenChanged()

let inventoryItemdefs = Computed(function(prev) {
  //do not update anything in battle, as it can be time consuming and not needed in battle anyway
  if (prev != FRP_INITIAL && isInBattleState.value)
    return prev
  else if (prev == FRP_INITIAL && isInBattleState.value)
    return {}
  return itemdefs.value.filter(@(itemdef) itemdef.len() > 0)
})

let inventoryItems = Computed(function(prev) {
  //do not update anything in battle, as it can be time consuming and not needed in battle anyway
  if (prev != FRP_INITIAL && isInBattleState.value)
    return prev
  else if (prev == FRP_INITIAL && isInBattleState.value)
    return {}
  return allItems.value.filter(@(item) item.itemdef.len() > 0)
})

let function dbgRequestAllPrices(cbOnPrices, currencyId){
  let itemdefids = inventoryItemdefs.value.keys()
  requestPrices({currencyId, itemdefids},
    function cb(result){
      let itemPrices = result?.response?.itemPrices ?? []
      let prices = {}
      foreach (data in itemPrices) {
        let itemdefid = data?.itemdefid
        if (itemdefid == null)
          continue
        prices[itemdefid] <- data?.price
      }
      cbOnPrices(prices)
    }
  )
}

return {
  exchangeItems
  allItems
  exchangeItemsByItemdefs
  inventoryItemsAmounts
  inventoryItemdefs
  inventoryItems
  onRefreshItemsResult
  isExchangeInProgress
  isPurchaseInProgress
  areItemsAndItemdefsReceived = Computed(@() areItemsReceived.value && areItemsItemdefsReceived.value)
  areItemsItemdefsReceived
  areItemsReceived
  //request itemdefs by idsList.
  requestItemdefsByIds
  refreshAllItemDefs
  shouldRequestAllItemdefs
  refreshItems
  forceRefreshItems
  requestItemPurchaseOffers
  purchaseItemByOffer
  purchaseItem
  signItems
  parseItemStr
  parseBundle
  itemShopConfig
  requestPrices
  requestPricesRaw
  markSeenItems = markSeen
  isInventoryFailedGetData
  inventoryClientReset = reset
  inventoryErrorLog = errorLog
  inventoryPremiumTimestamp = premiumTimestamp
  dbgRequestAllPrices
  chardToken
  appId
  //item.origin constants from inventory server
  IO_purchase      = "purchase"
  IO_trade         = "trade"
  IO_promo         = "promo"
  IO_gametime      = "gametime"
  IO_exchange      = "exchange"
  IO_support       = "support"
  IO_external      = "external"
  IO_market        = "market"
}
