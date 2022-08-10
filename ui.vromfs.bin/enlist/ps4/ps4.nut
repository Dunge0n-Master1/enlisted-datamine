from "%enlSqGlob/ui_library.nut" import *

let loginState = require("%enlSqGlob/login_state.nut")
let ps4state = require("%enlist/ps4/state.nut")
let ps4 = require("ps4")
let session = require("%enlist/ps4/session.nut")
let { acceptSquadInvite, leaveSquadSilent } = require("%enlist/squad/squadManager.nut")
let { requestMembership } = require("%enlist/squad/squadAPI.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let loginChain = require("%enlist/login/login_chain.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let eventbus = require("eventbus")
let {leaveQueue} = require("%enlist/quickMatchQueue.nut")
let roomState = require("%enlist/state/roomState.nut")
let {exit_to_enlist} = require("app")
let { uid2console } = require("%enlist/contacts/consoleUidsRemap.nut")
let { requestsToMeUids } = require("%enlist/contacts/contactsWatchLists.nut")
let logP = require("%enlSqGlob/library_logs.nut").with_prefix("[PSNENV] ")

let { open_player_profile = @(...) null, PlayerAction = null
} = require("sony.social")

let JOIN_SESSION_ID = "join_session_after_ps4_login"

let function join_session(data) {
  let { session_id, invitation_id } = data
  session.join(session_id, invitation_id, function(squadId) {
    logP($"Trying to join squad {squadId}")
    if (squadId in requestsToMeUids.value) {
      logP("Invitation was found, accepting")
      acceptSquadInvite(squadId.tointeger())
    }
    else {
      logP("Invitation wasn't found, requesting squad membership")
      requestMembership(squadId.tointeger())
    }
  })
}
let persistActions = persist("persistActions",@() {})
persistActions[JOIN_SESSION_ID] <- join_session


let function onSessionInvitation(data) {
  logP($"got invitation to {data?.session_id}: uinfo {userInfo?.value}, lstage {loginChain?.currentStage.value}")
  if (userInfo.value != null) {
    if (isInBattleState.value) {
      ps4state.invitation_data(data)
      eventbus.send("ipc.onInviteAccepted", null)
    } else {
      join_session(data)
    }
  } else if (loginChain.currentStage.value != null) {
    ps4state.invitation_data(data)
  } else {
    loginChain.doAfterLoginOnce(@() persistActions[JOIN_SESSION_ID](data))
    loginChain.startLogin({})
  }
}

let function onGameIntent(data) {
  logP($"got game intent {data?.action}, session {data?.sessionId}, activity {data?.activityId}")
  if (data.sessionId != "") {
    onSessionInvitation({session_id = data.sessionId, invitation_id = null})
    return
  }
  ps4state.game_intent(data)
  if (loginState.isLoggedIn.value == null)
    loginChain.startLogin({})
}

let function onResume() {
  if (loginChain.currentStage.value != null) {
    loginChain.interrupt()
    return
  }
  loginState.logOut()
}

let function process_logout(skip_checks) {
  let function do_logout() {
    loginState.logOut()
    msgbox.show({ text = loc("yn1/disconnection/psn", { game = loc("title/name") }) })
  }

  if (!skip_checks) {
    if (ps4state.psn_was_logged_out.value) {
      ps4state.psn_was_logged_out(false)
      ps4.check_psn_logged_in(function(result) {
        if (!result) {
          do_logout()
        }
      })
    }
  } else {
    do_logout()
  }
}

let function onPsnLogout() {
  if (loginChain.currentStage.value != null) {
    ps4state.psn_was_logged_out(true)
    return
  }
  if (userInfo.value != null)
    process_logout(true)
}

loginState.isLoggedIn.subscribe(function(v) {
  if (!v) {
    if (isInBattleState.value)
      exit_to_enlist()
  }
})

let function on_ps4_callback(data) {
  if (!data?.type) {
    logP("Invalid data received:", data)
    return
  } else if (data.type == "invitation") {
    onSessionInvitation(data)
  } else if (data.type == "resuming") {
    onResume()
  } else if (data.type == "logged-out") {
    onPsnLogout()
  } else if (data.type == "gameIntent") {
    onGameIntent(data)
  }
}

ps4.set_events_callback(on_ps4_callback)

loginState.isLoggedIn.subscribe(function(v) {
  if (v)
    process_logout(false)
  else
    leaveQueue()
})

eventbus.subscribe("ipc.onBattleExitAccept", function(_) {
  defer(exit_to_enlist)
  leaveSquadSilent(function(...) {
    if (ps4state.invitation_data.value != null) {
      join_session(ps4state.invitation_data.value)
      ps4state.invitation_data(null)
    }
  })
})

eventbus.subscribe("matching.logged_out", function(_notify) {
  leaveQueue()
  roomState.leaveRoom(function(...){})
})

eventbus.subscribe("showPsnUserInfo", @(msg) open_player_profile(
  (uid2console.value?[msg.userId.tostring()] ?? "-1").tointeger(),
  PlayerAction?.DISPLAY,
  "",
  {}
))

eventbus.subscribe("PSNAuthContactsRecieved", function(_) {
  if (ps4state.invitation_data.value) {
    join_session(ps4state.invitation_data.value)
    ps4state.invitation_data(null)
  }
})