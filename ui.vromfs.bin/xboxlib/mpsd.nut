let mpsd = require("%xboxLib/impl/mpsd.nut")
let logX = require("%sqstd/log.nut")().with_prefix("[MPSD] ")

let mpsdState = persist("mpsdState", @() { eventHandlers = {}, isLocalUserAdded = false })


let function set_event_handler(name, handler) {
  logX($"set_event_handler: {name}")
  mpsdState.eventHandlers[name] <- handler
}


let function set_user_joined_handler(handler) {
  set_event_handler("member_joined", handler)
}


let function set_user_left_handler(handler) {
  set_event_handler("member_left", handler)
}


let function set_user_prop_changed_handler(handler) {
  set_event_handler("member_property_changed", handler)
}


let function set_client_disconnected_handler(handler) {
  set_event_handler("client_disconnected_from_multiplayer_service", handler)
}


let function mpsd_event_handler(eventId, xuid, props) {
  logX($"event_handler: {eventId} -> {xuid}")
  mpsdState.eventHandlers[eventId]?(xuid, props)
}

mpsd.subscribe_to_events(mpsd_event_handler)


let function add_local_user(callback) {
  mpsd.add_local_user(function(success) {
    logX($"add_local_user succeeded: {success}")
    mpsdState.isLocalUserAdded = success
    callback?(success)
  })
}


let function remove_local_user(callback) {
  if (!mpsdState.isLocalUserAdded) {
    logX("Local user wasn't added, skipping removal")
    callback?(true) // behave like user was removed
    return
  }
  mpsd.remove_local_user(function(success) {
    logX($"remove_local_user succeeded: {success}")
    mpsdState.isLocalUserAdded = false
    callback?(success)
  })
}


let function recreate_lobby(callback) {
  logX($"Recreading lobby. IsLocalUserAdded: {mpsdState.isLocalUserAdded}")
  if (mpsdState.isLocalUserAdded) {
    remove_local_user(function(_status) {
      add_local_user(callback)
    })
  } else {
    add_local_user(callback)
  }
}


let function join_lobby(callback) {
  let function join_impl() {
    mpsd.join_lobby(function(success) {
      logX($"join_lobby succeeded: {success}")
      mpsdState.isLocalUserAdded = success
      callback?(success)
    })
  }
  logX($"Joining lobby. IsLocalUserAdded: {mpsdState.isLocalUserAdded}")
  if (mpsdState.isLocalUserAdded) {
    remove_local_user(function(_status) {
      join_impl()
    })
  } else {
    join_impl()
  }
}


let function invite_friends(context, callback) {
  logX($"Inviting friends with context: {context}")
  mpsd.invite_friends(context, function(success) {
    logX($"invite_friends succeeded: {success}")
    callback?(success)
  })
}


let function invite_user(xboxUid, context, callback) {
  logX($"Inviting user {xboxUid} with context {context}")
  mpsd.invite_user(xboxUid, context, function(success) {
    logX($"User {xboxUid} invitation success: {success}")
    callback?(success)
  })
}


let function on_session_join(session_id, callback) {
  logX($"on_session_join: {session_id}")
  mpsd.on_session_join(session_id, function(xuids) {
    let xuidsCount = xuids?.len() ?? 0
    logX($"joined session with {xuidsCount} players")
    callback?(xuids)
  })
}


let function on_session_leave() {
  logX($"on_session_leave")
  mpsd.on_session_leave()
}


let function set_joinability(joinability) {
  logX($"set_joinability: {joinability}")
  mpsd.set_joinability(joinability)
}


let function set_joinability_closed() {
  set_joinability(mpsd.Joinability.Closed)
}


let function set_joinability_friends() {
  set_joinability(mpsd.Joinability.Friends)
}


let function set_joinability_invite_only() {
  set_joinability(mpsd.Joinability.InviteOnly)
}


return {
  add_local_user
  remove_local_user
  recreate_lobby
  join_lobby
  invite_friends
  invite_user
  on_session_join
  on_session_leave

  subscribe_to_events = mpsd.subscribe_to_events

  set_joinability_closed
  set_joinability_friends
  set_joinability_invite_only

  set_user_joined_handler
  set_user_left_handler
  set_user_prop_changed_handler
  set_client_disconnected_handler
}
