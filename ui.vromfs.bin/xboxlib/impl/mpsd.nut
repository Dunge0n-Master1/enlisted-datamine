let mp = require("xbox.multiplayer")
let {subscribe, subscribe_onehit} = require("eventbus")


let function add_local_user(callback) {
  let eventName = "xbox_mpsd_add_local_user"
  subscribe_onehit(eventName, function(result) {
    let success = result?.success
    callback?(success)
  })
  mp.add_local_user(eventName)
}


let function remove_local_user(callback) {
  let eventName = "xbox_mpsd_remove_local_user"
  subscribe_onehit(eventName, function(result) {
    let success = result?.success
    callback?(success)
  })
  mp.remove_local_user(eventName)
}


let function join_lobby(callback) {
  let eventName = "xbox_mpsd_join_lobby"
  subscribe_onehit(eventName, function(result) {
    let success = result?.success
    callback?(success)
  })
  mp.join_lobby(eventName)
}


let function invite_friends(context, callback) {
  let eventName = "xbox_mpsd_invite_friends"
  subscribe_onehit(eventName, function(result) {
    let success = result?.success
    callback?(success)
  })
  mp.invite_friends(context, eventName)
}


let function invite_user(xboxUid, context, callback) {
  let eventName = "xbox_mpsd_invite_user"
  subscribe_onehit(eventName, function(result) {
    let success = result?.success
    callback?(success)
  })
  mp.invite_user(xboxUid.tointeger(), context, eventName)
}


let function subscribe_to_events(callback) {
  subscribe(mp.multiplayer_handler_event_name, function(result) {
    let eventId = result?.event_name
    let xuid = result?.xuid
    let props = result?.params
    callback?(eventId, xuid, props)
  })
}


let function on_session_join(session_id, callback) {
  let eventName = "xbox_mpsd_on_session_join"
  subscribe_onehit(eventName, function(result) {
    let xuids = result?.xuids
    callback?(xuids)
  })
  mp.on_session_join(eventName, session_id)
}


return {
  Joinability = mp.Joinability

  subscribe_to_events
  add_local_user
  remove_local_user
  join_lobby
  invite_friends
  invite_user
  on_session_join
  on_session_leave = mp.on_session_leave
  set_joinability = mp.set_joinability
}