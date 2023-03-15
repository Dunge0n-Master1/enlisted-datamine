from "%enlSqGlob/ui_library.nut" import *

let logXbox = require("%enlSqGlob/library_logs.nut").with_prefix("[XBOX STORE]")
let app = require("%xboxLib/impl/app.nut")
let store = require("%xboxLib/impl/store.nut")
let { xbox_login } = require("%enlist/xbox/login.nut")

let auth = require("auth")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { check_purchases } = require("%enlist/meta/clientApi.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")


app.register_constrain_callback(function(active) {
  if (active) {
    logXbox($"updatePurchases: is logged in: {userInfo.value != null}, isInBattleState: {isInBattleState.value}")
    if (userInfo.value == null || isInBattleState.value)
      return

    xbox_login(function(status, _) {
      let isSuccess = status == auth.YU2_OK
      logXbox($"Update purchases: is success: {isSuccess}, is logged in {userInfo.value != null}")
      if (!isSuccess || userInfo.value == null)
        return

      logXbox("Update purchases after request")
      check_purchases()
    })
  }
})


let function show_marketplace(productKind) {
  logXbox($"show_marketplace({productKind})")
  store.show_marketplace(productKind, function(success) {
    logXbox($"show_marketplace succeeded: {success}")
  })
}

let function show_details(productId) {
  logXbox($"show_details({productId})")
  store.show_details(productId, function(success) {
    logXbox($"show_details succeeded: {success}")
  })
}

let function show_purchase(productId) {
  logXbox($"show_purchase({productId})")
  store.show_purchase(productId, function(success) {
    logXbox($"show_purchase succeeded: {success}")
  })
}

return {
  PKNone = store.ProductKind.None
  PKConsumable = store.ProductKind.Consumable
  PKDurable = store.ProductKind.Durable
  PKGame = store.ProductKind.Game
  PKPass = store.ProductKind.Pass
  PKUnmanagedConsumable = store.ProductKind.UnmanagedConsumable

  show_marketplace
  show_details
  show_purchase
}