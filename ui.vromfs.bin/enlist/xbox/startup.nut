from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")
let logX = require("%enlSqGlob/library_logs.nut").with_prefix("[STARTUP] ")
let {login, logout, subscribe_to_logout} = require("%xboxLib/loginState.nut")

let {get_activation_data, get_invited_xuid, register_activation_callback} = require("%xboxLib/activation.nut")
let {isDimAllowed} = require("%xboxLib/display.nut")

let userInfo = require("%enlSqGlob/userInfo.nut")

let {switch_to_menu_scene} = require("app")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let {logOut, isLoggedIn} = require("%enlSqGlob/login_state.nut")
let {currentStage, doAfterLoginOnce, startLogin, interrupt} = require("%enlist/login/login_chain.nut")

let { isInSquad, leaveSquadSilent, acceptSquadInvite, requestJoinSquad
} = require("%enlist/squad/squadManager.nut")

let { requestsToMeUids } = require("%enlist/contacts/contactsWatchLists.nut")

let {nestWatched} = require("%dngscripts/globalState.nut")
let needLogin = nestWatched("needLogin", false)

isLoggedIn.subscribe(function(v) {
  isDimAllowed.update(!v)
  if (!v) {
    if (isInBattleState.value)
      switch_to_menu_scene()
    logout()
  } else {
    login()
  }
})


let function try_leave_squad(cb = null) {
  logX($"try_leave_squad, isInSquad.value {isInSquad.value}")
  if (isInSquad.value) {
    leaveSquadSilent(cb)
  }
  else
    cb?()
}


let function join_internal(squadId) {
  logX($"Trying to join squad {squadId}")
  if (squadId in requestsToMeUids.value) {
    logX("Invitation was found, accepting")
    acceptSquadInvite(squadId.tointeger())
  }
  else {
    logX("Invitation wasn't found, requesting squad join")
    requestJoinSquad(squadId.tointeger())
  }
}


let function complete_activation() {
  let squadId = get_activation_data()

  if (needLogin.value) {
    logX("Login by activation")
    needLogin(false)
    doAfterLoginOnce(@() try_leave_squad(@() join_internal(squadId)))
    startLogin({xuid = get_invited_xuid()})
  } else {
    logX("Regular activation")
    try_leave_squad(@() join_internal(squadId))
  }
}


let function activation_handler() {
  if (currentStage.value) {
    logX("Skipping activation due to active login process")
    return
  }

  let needLogout = userInfo.value != null && userInfo.value?.xuid != get_invited_xuid()
  needLogin(needLogout || userInfo.value == null)

  if (needLogout)
    logOut()

  if (isInBattleState.value) {
    eventbus.send("ipc.onInviteAccepted", null)
  } else {
    complete_activation()
  }
}


register_activation_callback(activation_handler)

eventbus.subscribe("ipc.onBattleExitAccept",  function(_) {
  defer(switch_to_menu_scene)
  complete_activation()
})


subscribe_to_logout(function(_updated) {
  if (currentStage.value) {
    logX("Seems like user was logged out from system during login parocess. Interrupting...")
    interrupt()
    return
  }
  logOut()
})
