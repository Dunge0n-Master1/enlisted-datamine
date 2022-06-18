from "%enlSqGlob/ui_library.nut" import *

let loginCb = require("%enlist/login/login_cb.nut")
let auth = require("auth")
let nswitchAccount = require("nswitch.account")
let auth_helper = require("%enlist/login/stages/auth_helpers.nut")
let {shaderCacheUpdateFromNetwork} = require("%enlist/nswitch/shader_cache.nut")
let goodsAndPurchases = require("%enlist/shop/goodsAndPurchases_nswitch.nut")
let eventbus = require("eventbus")
let { get_setting_by_blk_path } = require("settings")

let function login_nso_cb(result, cb) {
  local nsa_error = null
  switch (result.status) {
    case nswitchAccount.OK: break //no errors
    case nswitchAccount.COMMUNICATION_ERROR:
      nsa_error = "nswitch/nso_communication_error"
    break
    case nswitchAccount.TOKEN_CACHE_UNAVAILABLE:
    case nswitchAccount.NSO_SUBSRIPTION_FAILED: {  //possible player have no NSO/NSA
                         //it not a error, but mp session will be
                         //disabled
      log("nswitch: active user have no nso permissions")
    }
    break
    case nswitchAccount.TIMEOUT:
      nsa_error = "nswitch/nso_timeout_error"
    break
    default:
      nsa_error = "nswitch/nso_common_error"
    break
  }

  log("nswitch: login nsa status result is {0}".subst(nsa_error?nsa_error:"no_error"))
  if (nsa_error) {
    cb({error = nsa_error})
    return
  }

  log("nswitch: AppMakingConnectionId {0}".subst(nswitchAccount.getAppMakingConnectionId()) )

  // all ok, prepare login to auth
  let tok = nswitchAccount.getNsaToken()
  let nickname = nswitchAccount.getNickname()

  eventbus.subscribe_onehit("login_nswitch", auth_helper.status_cb(cb))
  auth.login_nswitch({nintendo_jwt=tok, user=nickname}, "login_nswitch")
}

let function login_nswitch_online(state, cb) {
  let user_id = nswitchAccount.getUserId()
  log("nswitch: login NSO for user {0}".subst(user_id))
  state.userInfo.nswitchUserId <- user_id
  state.userInfo.name <- nswitchAccount.getNickname()
  state.userInfo.iconTexture <- "nx_profile_image"

  nswitchAccount.createProfileImageTex(state.userInfo.iconTexture)
  //update & load shader cache while user logging in
  shaderCacheUpdateFromNetwork()

  // application blocked while NSA applet display, we cant drive game here
  local nsa_error = nswitchAccount.loadNsaToken()
  local login_nintnendo_state = null

  if (nsa_error == nswitchAccount.NSA_UNAVAILABLE) {
    login_nintnendo_state = null;
    let result = nswitchAccount.loginToNsaWithShowingError();
    log("nswitch: loginToNsaWithShowingError return {0}".subst(result))
    if (result == nswitchAccount.OK) {
      nsa_error = nswitchAccount.OK
    }
  } else if (nsa_error == nswitchAccount.COMMUNICATION_ERROR
            || nsa_error == nswitchAccount.TERM_AGREEMENT_REQUIRED) {
    login_nintnendo_state = "nswitch/nso_communication_error"
  } else if (nsa_error != nswitchAccount.OK) {
    login_nintnendo_state = "nswitch/nso_common_error"
  }

  if (nsa_error != nswitchAccount.OK) {
    cb({ error = login_nintnendo_state })
    return
  }

  log("nswitch: login_nintnendo_state:{0}".subst(login_nintnendo_state?login_nintnendo_state:"no_error"))
  if (nsa_error == nswitchAccount.OK) {// all ok, no errors
    log("nswitch: Waiting for console process user authorize with nintendo servers")
    nswitchAccount.requestNsoStatusAsync(get_setting_by_blk_path("nswitch/systemConnectTestTimeout") ?? 50000, function(status) {
      log("nswitch: Received answer for remote authorize status: {0}".subst(status))
      if (status == nswitchAccount.OK) {
        login_nso_cb({ status = status }, cb)
      } else { //possible player havenot network, rule 0134 need to notify player about this
        log("nswitch: login_nswitch_online - network issue: {0}".subst(status))
        cb({error = "nswitch/network_error"})
      }
    })
  } else {
    log("nswitch: login_nswitch_online check nsa:{0}".subst(nsa_error))
    cb({error = "nswitch/nso_communication_error"})
  }
}

let function permissions_check(_state, cb) {
  cb({})
  //NSO_account.active_user_check_permissions(NSO_account.MultiplayerSessions, true, error_cb(cb))
}

let function eshop_init(_state, cb) {
  goodsAndPurchases.initAndRequestReqionData(
    {},
    function(_state) {
      //nintendo EC guideline 0132 - show that eshop is not accesible on login
      if (!goodsAndPurchases.canOpenEshop())
        goodsAndPurchases.showErrorWithSystemDialog()
    }
  )
  cb({})
}

return {
  stages = [
    { id = "auth_nso", action = login_nswitch_online, actionOnReload = function(_state, _cb) {} },
    require("%enlist/login/stages/auth_result.nut"),
    { id = "permissions", action = permissions_check, actionOnReload = function(_state, _cb) {} },
    { id = "eshop_init", action = eshop_init, actionOnReload = function(_state, _cb) {} },
    require("%enlist/login/stages/char.nut"),
    require("%enlist/login/stages/online_settings.nut"),
    require("%enlist/login/stages/eula.nut"),
    require("%enlist/login/stages/matching.nut")
  ]
  onSuccess = loginCb.onSuccess
  onInterrupt = loginCb.onInterrupt
}
