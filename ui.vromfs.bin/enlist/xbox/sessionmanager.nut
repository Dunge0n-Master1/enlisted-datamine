let mpa = require("%xboxLib/mpa.nut")
let logX = require("%enlSqGlob/library_logs.nut").with_prefix("[SESSION_MANAGER] ")
let { uid2console } = require("%enlist/contacts/consoleUidsRemap.nut")
let { isInSquad, isSquadLeader, squadId, squadMembers, subsMemberAddedEvent, subsMemberRemovedEvent
} = require("%enlist/squad/squadState.nut")
let { availableSquadMaxMembers } = require("%enlist/state/queueState.nut")
let { currentGameMode } = require("%enlist/gameModes/gameModeState.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")


let function update_current_activity(callback = null) {
  let maxMembers = availableSquadMaxMembers.value
  let currentMembers = isInSquad.value ? squadMembers.value.len() : 1
  let sessionId = isInSquad.value ? squadId.value.tostring() : (userInfo.value?.userIdStr ?? "")
  // Don't set activity if user is not a squad(or fake squad) leader or when game mode is for one player
  let shouldSetActivity = (isSquadLeader.value || !isInSquad.value) && (currentGameMode.value.maxGroupSize > 1)
  if (shouldSetActivity) {
    mpa.set_activity(sessionId, mpa.JoinRestriction.InviteOnly, maxMembers, currentMembers, sessionId, function(success) {
      logX($"Activity updated: {success}")
      callback?(success)
    })
  } else {
    logX("Skip setting activity because user is not a squad leader");
    callback?(true) // behave like activity was set
  }
}


let function invite(uid, callback) {
  let xboxUid = uid2console.value?[uid.tostring()]
  if (xboxUid == null) {
    logX($"Try invite user {uid} with unknown xbox uid")
    return
  }

  mpa.send_invitations(squadId.value.tostring(), [xboxUid.tointeger()], function(_) {
    callback?()
  })
}


let function join(session_id, invitation_id, on_success) {
  logX($"join to session {session_id} recieved from {invitation_id}")
  update_current_activity(function(success) {
    if (success)
      on_success?()
  })
}


let function update_data(leaderUid) {
  logX($"change leader on xbox system, notify about new leader id {leaderUid}")
  mpa.clear_activity(null) // if user was a leader, we need to clear his activity
  update_current_activity()
}


let function create(_, callback) {
  update_current_activity(function(_) {
    callback?()
  })
}


let function leave() {
  mpa.clear_activity(null)
}


subsMemberAddedEvent(function(user_id) {
  logX($"update activity ? {isInSquad.value} on subsMemberAddedEvent {user_id}")
  if (isInSquad.value)
    update_current_activity()
})


subsMemberRemovedEvent(function(user_id) {
  logX($"update activity ? {isInSquad.value} on subsMemberRemovedEvent {user_id}")
  if (isInSquad.value)
    update_current_activity()
  else
    mpa.clear_activity(null)
})


userInfo.subscribe(function(v) {
  logX($"update activity on login ? {v}")
  if (v)
    update_current_activity()
  else
    mpa.clear_activity(null)
})


currentGameMode.subscribe(function(_) {
  mpa.clear_activity(null)
  update_current_activity()
})


return {
  update_data = update_data
  leave = leave
  invite = invite
  create = create
  join = join
}