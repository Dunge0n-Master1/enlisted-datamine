from "%enlSqGlob/ui_library.nut" import *

let { currenciesPurchases } = require("%enlist/currency/currencies.nut") //!!FIX ME: Why it included here?
let { sound_play } = require("sound")
let msgbox = require("%enlist/components/msgbox.nut")
let {deep_clone} = require("%sqstd/underscore.nut")
let nswitchAccount = require("nswitch.account")
let itemGroupNsUid = mkWatched(persist, "itemGroupNsUid", {})
let {inventoryRefresh} = require("%enlist/inventory/inventory.nut")
let eventbus = require("eventbus")
let {logerr} = require("dagor.debug")

let nswitchShop = require("nswitch.eshop")
let auth = require("auth")

let isGoodsRequested = Watched(false)
let nsItemsReady = Watched(false)
let marketIds = Watched([])
let vatMsg = Watched(nswitchShop.getIncTaxMessage())
let max_request_number = 5; //TODO: move to the settings.blk or smth else
local request_number = 0;
local reRequestFunc;

let goodsInfo = Computed(function() {
  if (!nsItemsReady.value)
    return {}

  let list = {}

  foreach (val in marketIds.value) {
    let itemId = val?.product_id
    let guid = val?.guid
    if (itemId == "" || guid == "") {
      continue
    }
    let nsuid = nswitchShop.getItemNsUid(itemId)
    if (nsuid == 0) {
      continue
    }

    let price = nswitchShop.getItemPrice(itemId)
    if (price == "NoSale")
      continue;

    local discount_price = nswitchShop.getItemDiscount(itemId)
    let raw_price = nswitchShop.getItemRawPrice(itemId)
    let raw_discount_price = nswitchShop.getItemRawDiscount(itemId)

    local discount_multiplier = 1.0
    if (discount_price != "NoDiscount")
      discount_multiplier = raw_discount_price.tofloat() / raw_price.tofloat()
    else
      discount_price = price

    list[guid] <- {
      price,
      shop_price = discount_price,
      shop_price_full = price,
      discount_mul = discount_multiplier
      product_id = itemId
    }
  }

  return list
})

let function extractEshopError() {
  let r = {}
  let result = auth.get_user_info()
  r.eshop_error <- result?.eshop_error
  r.eshop_msg <- result?.eshop_msg
  return r
}

let function asyncRequestEshopState(callback) {
  let tok = nswitchAccount.getNsaToken()
  let nickname = nswitchAccount.getNickname()
  eventbus.subscribe_onehit("goodsAndPurchases_asyncRequestEshopState", callback)
  auth.login_nswitch({nintendo_jwt=tok, user=nickname}, "goodsAndPurchases_asyncRequestEshopState")
}

let function canOpenEshop() {
  let r = extractEshopError()
  return ((r?.eshop_error ?? 0) == 0)
}

let function showErrorWithSystemDialog() {
  let r = extractEshopError()
  let eshop_error = r?.eshop_error ?? 0

  if (eshop_error != 0)
    nswitchShop.showErrorWithCode(eshop_error)
}

let function checkPurchasesState() {
  asyncRequestEshopState(function(_result) {
    if (!canOpenEshop()) {
        showErrorWithSystemDialog()
    }
    inventoryRefresh()
  })
}

// try open system applet for eShop
let function handlePurchase(product_id) {
    let nintendoId = nswitchShop.getItemNsUid(product_id)
    let groupId = nswitchShop.getItemGroupNsUid(product_id)

    if (groupId.len() == 0) {
      log("nswitch: cant groupId for product_id", product_id, nintendoId)
      return
    }
    nswitchShop.showShopConsumableItemDetail(groupId, nintendoId)
    checkPurchasesState()
}

let function log_items(_status) {
  let count = nswitchShop.getItemsCount()
  let items = {}
  for (local i=0; i < count; i++) {
    let itemId = nswitchShop.getItemId(i)
    let nsUid = nswitchShop.getItemNsUid(itemId)
    let groupNsUid = nswitchShop.getItemGroupNsUid(itemId)
    let price = nswitchShop.getItemPrice(itemId)
    let name = nswitchShop.getItemName(itemId)

    items[itemId] <- {
      name = name,
      nsUid = nsUid,
      groupNsUid = groupNsUid,
      price = price }

    log("nswitch: show_eshop_items:", i, itemId, nsUid, groupNsUid)
  }
  itemGroupNsUid.mutate(@(r) r.__update(items))
}

let regionalPurchases = Computed(function() {
    let res = {}
    foreach (guid, v in currenciesPurchases.value) {
      let purchInfo = deep_clone(v)
      purchInfo.meta.showInGame <- ((itemGroupNsUid.value?[purchInfo?.meta.nintendoId].nsUid ?? "") != "")

      if (purchInfo.meta.showInGame) {
        let display_price = nswitchShop.getItemPrice(purchInfo.meta.nintendoId)
        purchInfo.shop_price <- display_price
        purchInfo.shop_price_full <- display_price
      }

      res[guid] <- purchInfo
    }
    return res
  }
)

let function onNswitchEshopInitialized(status) {
  if (status == 0) {
    log_items(status)
    nsItemsReady(true)
    let message = nswitchShop.getIncTaxMessage()
    vatMsg(message)

    isGoodsRequested(false)
  }
  else if (status == nswitchShop.REQUEST_TIMEOUT && request_number < max_request_number) {
    request_number = request_number + 1
    log("nswitch: Eshop: item request failed. Retry.")
    eventbus.subscribe_onehit("nswitch.eshop.onItemsRequested", @(val) reRequestFunc(val.status))
    nswitchShop.updateGroupAndItemsAsync()
  }
  else {
    let err = nswitchShop.getRequestConsumableGroupErrorCode()
    if (err.group == 2308 && err.code == 2006) {
      sound_play("ui/enlist/login_fail")
      msgbox.show({
        text = loc("nswitch/restricted_eshop_in_region"),
        onClose = @() null
      })
    }
    else if (status != nswitchShop.REQUEST_TIMEOUT && status != nswitchShop.REQUEST_NETWORK_ERROR)
      logerr($"nswitch: Eshop: error occur: group={err.group}, code={err.code}, status={status}")
    isGoodsRequested(false)
  }
}

let function initAndRequestReqionData(_state, _cb) {
  if (isGoodsRequested.value) {
    log("nswitch: eshop: already initialized")
    return
  }
  log("nswitch: eshop start initialize async")
  isGoodsRequested(true)

  reRequestFunc = @(status) onNswitchEshopInitialized(status)
  eventbus.subscribe_onehit("nswitch.eshop.onItemsRequested", @(val) onNswitchEshopInitialized(val.status))
  nswitchShop.initialize()
}

return {
  purchased = Watched({}) //not implemented yet
  regionalPurchases
  addGuids = @(_guids) null
  refreshPurchased = @(...) null //not implemented yet
  goodsInfo
  marketIds
  isGoodsRequested
  initAndRequestReqionData
  originalData = itemGroupNsUid
  canOpenEshop
  showErrorWithSystemDialog = showErrorWithSystemDialog
  extractEshopError
  asyncRequestEshopState
  handlePurchase
  vatMsg
}