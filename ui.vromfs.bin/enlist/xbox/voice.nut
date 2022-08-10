let voiceApi = require_optional("voiceApi")
let voice = require("%xboxLib/voice.nut")
let { subscribe } = require("eventbus")
let {hexStringToInt} =  require("%sqstd/string.nut")
let { xboxCrossVoiceWithFriendsAllowed, xboxCrossVoiceWithAllAllowed } = require("%enlSqGlob/crossnetwork_state.nut")
let { subsMemberAddedEvent, subsMemberRemovedEvent, squadMembers } = require("%enlist/squad/squadManager.nut")
let { console2uid, uid2console } = require("%enlist/contacts/consoleUidsRemap.nut")
let { friendsUids } = require("%enlist/contacts/contactsWatchLists.nut")
let logX = require("%enlSqGlob/library_logs.nut").with_prefix("[XVOICE] ")


let function voice_mute(uid) {
  voiceApi.mute_player_by_uid(uid.tointeger())
  logX($"Mute player {uid}")
}


let function voice_unmute(uid) {
  voiceApi.unmute_player_by_uid(uid.tointeger())
  logX($"Unmute player {uid}")
}


let function voice_change_state(uid, mute) {
  if (mute) {
    voice_mute(uid)
  } else {
    voice_unmute(uid)
  }
}


let function voice_change_state_by_xuid(xuid, mute) {
  let uid = console2uid.value?[xuid.tostring()]
  if (uid == null) {
    logX($"Can't find uid by xuid: {xuid}")
    return
  }
  voice_change_state(uid, mute)
}


let function mute_by_xuids(xuids) {
  foreach (xuid in xuids)
    voice_change_state_by_xuid(xuid, true)
}

let function unmute_by_xuids(xuids) {
  foreach (xuid in xuids)
    voice_change_state_by_xuid(xuid, false)
}


voice.subscribe_to_user_voice_state_change(voice_change_state_by_xuid)


subsMemberAddedEvent(function(user_id) {
  let xuid = uid2console.value?[user_id.tostring()]
  if (xuid == null) {
    logX($"Can't find xuid by uid: {user_id}")
    return
  }
  voice.track_user_permissions(xuid.tointeger())
})


subsMemberRemovedEvent(function(user_id) {
  let xuid = uid2console.value?[user_id.tostring()]
  if (xuid == null) {
    logX($"Can't find xuid by uid: {user_id}")
    return
  }
  voice.stop_tracking_user_permissions(xuid.tointeger())
})


let function is_friend(uid) {
  let user = friendsUids.value?[uid.tostring()]
  return user != null
}


let function is_foreign_user_should_be_muted(uid) {
  if (xboxCrossVoiceWithAllAllowed.value) {
    logX($"User {uid} shouldn't be muted because voice chat is allowed with all crossnetwork users")
    return false
  } else {
    if (xboxCrossVoiceWithFriendsAllowed.value) {
      let isFriend = is_friend(uid)
      if (isFriend) {
        logX($"User {uid} shouldn't be muted because of friendship status")
        return false
      }
    }
  }
  return true
}

let function is_foreign_user(uid) {
  return uid2console.value?[uid.tostring()] == null || !is_friend(uid)
}

let function update_foreign_user_state(uid) {
  let isForeign = is_foreign_user(uid)
  logX($"Check on foreign status {uid} -> {isForeign}")
  if (!isForeign)
    return

  let mute = is_foreign_user_should_be_muted(uid)
  voice_change_state(uid, mute)
}


let function update_crossnet_chat() {
  foreach (userId, _ in squadMembers.value)
    update_foreign_user_state(userId)
}


subscribe("voice.on_peer_joined",
  function(data) {
    if (!data?.uid)
      return

    let uid = hexStringToInt(data.uid) // uid is passed as hex string
    logX($"voice.on_peer_joined: data.uid -> {data.uid}, uid -> {uid}, name -> {data.name}")
    update_foreign_user_state(uid)
  }
)


xboxCrossVoiceWithFriendsAllowed.subscribe(function(_) {
  update_crossnet_chat()
})


xboxCrossVoiceWithAllAllowed.subscribe(function(_) {
  update_crossnet_chat()
})


return {
  mute_by_xuids
  unmute_by_xuids
}