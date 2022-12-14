from "%enlSqGlob/ui_library.nut" import *

let logPSN = require("%enlSqGlob/library_logs.nut").with_prefix("[PSN STORE]")
let { is_ps4 } = require("%dngscripts/platform.nut")
let { get_auth_data_async } = require("ps4")
let psnStore = require("sony.store")
let auth = require("auth")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { check_purchases } = require("%enlist/meta/clientApi.nut")
let { subscribe, subscribe_onehit } = require("eventbus")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")


let ENLISTED_SERVICE_LABEL = is_ps4 ? 0 : 1
let AUTH_DATA_SUB_ID = "ps4.auth_data_store"

let updateCb = @(_status) check_purchases()
subscribe("psn_update_purchases_on_store_return", updateCb)

let function updatePurchases() {
  logPSN($"updatePurchases: is in battle: {isInBattleState.value}, is logged in: {userInfo.value != null}")
  if (userInfo.value == null || isInBattleState.value)
    return

  subscribe_onehit(AUTH_DATA_SUB_ID, function(auth_data) {
    if (!auth_data.error && userInfo.value != null) {
      logPSN("Update purchases after request")
      auth.login_psn(auth_data, "psn_update_purchases_on_store_return")
    }
  })

  get_auth_data_async(AUTH_DATA_SUB_ID)
}

subscribe("psnStoreClosed", @(_) updatePurchases())

return {
  show_category = @(cat) psnStore.open_category(
    cat,
    ENLISTED_SERVICE_LABEL,
    "psnStoreClosed",
    {}
  )
  show_pack_by_id = @(id) psnStore.open_product(
    id,
    ENLISTED_SERVICE_LABEL,
    "psnStoreClosed",
    {}
  )
}