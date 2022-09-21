from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")
let logX = require("%enlSqGlob/library_logs.nut").with_prefix("[STARTUP] ")
let {login, logout, subscribe_to_logout} = require("%xboxLib/loginState.nut")

let {get_activation_data, get_invited_xuid, register_activation_callback} = require("%xboxLib/activation.nut")

let userInfo = require("%enlSqGlob/userInfo.nut")

let {switch_to_menu_scene} = require("app")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let {logOut, isLoggedIn} = require("%enlSqGlob/login_state.nut")
let {currentStage, doAfterLoginOnce, startLogin, interrupt} = require("%enlist/login/login_chain.nut")

let { isInSquad, leaveSquadSilent, acceptSquadInvite, isLeavingWillDisbandSquad,
  leaveSquad, createSquadAndDo, subsMemberRemovedEvent, isManuallyLeavedSquadOnFullSquad
} = require("%enlist/squad/squadManager.nut")
let { requestMembership } = require("%enlist/squad/squadAPI.nut")

let { requestsToMeUids } = require("%enlist/contacts/contactsWatchLists.nut")
let { currentGameMode, isGameModeChangedManually } = require("%enlist/gameModes/gameModeState.nut")

let needLogin = mkWatched(persist, "needLogin", false)
let needCheckInvite = mkWatched(persist, "needCheckInvite", false)

let function updateSquadState(curGameMode = null) {
  if (!curGameMode)
    return

  if (curGameMode.maxGroupSize == 1 && isInSquad.value) {
    if (isLeavingWillDisbandSquad.value)
      leaveSquad()
    else
      leaveSquadSilent()
  }
  else if (curGameMode.maxGroupSize > 1 && !isInSquad.value)
    createSquadAndDo()
}


isLoggedIn.subscribe(function(v) {
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
  needCheckInvite(false)
  logX($"Trying to join squad {squadId}")
  if (squadId in requestsToMeUids.value) {
    logX("Invitation was found, accepting")
    acceptSquadInvite(squadId.tointeger())
  }
  else {
    logX("Invitation wasn't found, requesting squad membership")
    requestMembership(squadId.tointeger())
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
  needCheckInvite(true)

  if (needLogout)
    logOut()

  if (isInBattleState.value) {
    eventbus.send("ipc.onInviteAccepted", null)
  } else {
    complete_activation()
  }
}


register_activation_callback(activation_handler)


subsMemberRemovedEvent(function(user_id) {
  logX($"On removed member event: {user_id}, {currentGameMode.value?.id}, {currentGameMode.value?.maxGroupSize}, {isGameModeChangedManually.value}")
  if (isGameModeChangedManually.value || needCheckInvite.value)
    return

  if (currentGameMode.value && currentGameMode.value.maxGroupSize > 1 && user_id == userInfo.value?.userId)
    createSquadAndDo()
})


isManuallyLeavedSquadOnFullSquad.subscribe(function(v) {
  if (!v || isInSquad.value || needCheckInvite.value)
    return

  createSquadAndDo()
})


isInSquad.subscribe(@(v) v? isManuallyLeavedSquadOnFullSquad(false) : null)


currentGameMode.subscribe(function(v) {
  logX($"Update squad state on currentGameMode subscription {v?.id}, {needCheckInvite.value}")
  if (!needCheckInvite.value)
    updateSquadState(v)
})


eventbus.subscribe("ipc.onBattleExitAccept",  function(_) {
  defer(switch_to_menu_scene)
  complete_activation()
})


subscribe_to_logout(function() {
  if (currentStage.value) {
    logX("Seems like user was logged out from system during login parocess. Interrupting...")
    interrupt()
    return
  }
  logOut()
})
