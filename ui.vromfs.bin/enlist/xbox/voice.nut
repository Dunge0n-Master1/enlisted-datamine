let voiceApi = require_optional("voiceApi")
let {subscribe} = require("eventbus")
let {subscribe_to_state_update, add_voice_chat_member, remove_voice_chat_member,
  update_voice_chat_member_friendship, voiceChatMembers} = require("%xboxLib/voice.nut")
let {request_xuid_for_user} = require("%enlist/xbox/userIds.nut")
let {friendsUids} = require("%enlist/contacts/contactsWatchLists.nut")
let {hexStringToInt} =  require("%sqstd/string.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let {isLoggedIn} = require("%enlSqGlob/login_state.nut")
let {debugTableData, with_prefix} = require("%enlSqGlob/library_logs.nut")
let logX = with_prefix("[XBOX_VOICE] ")

let delayedChatMembers = persist("delayedChatMembers", @() {})


let function set_mute_status(uid, is_muted) {
  let func = is_muted ? voiceApi.mute_player_by_uid : voiceApi.unmute_player_by_uid
  func(uid.tointeger())
}


let function on_state_update(results) {
  foreach (state in results) {
    set_mute_status(state?.uid, state?.is_muted)
  }
}


let function add_user_to_chat(uid) {
  logX($"Adding user to voice chat: {uid}")
  if (userInfo.value.userId == uid) {
    logX("Skip tracking self")
    return
  }

  request_xuid_for_user(uid, function(u, xuid) {
    let ustr = u.tostring()
    let isFriend = (ustr in friendsUids.value)
    add_voice_chat_member(ustr, xuid, isFriend)
  })
}


subscribe("voice.on_peer_joined", function(data) {
  if (!data?.uid)
    return

  let uid = hexStringToInt(data.uid) // uid is passed as hex string
  logX($"voice.on_peer_joined: data.uid -> {data.uid}, uid -> {uid}, name -> {data.name}")

  if (isLoggedIn.value) {
    add_user_to_chat(uid)
  } else {
    logX($"Delaying chat join for <{uid}>")
    delayedChatMembers[uid] <- true
  }

})


subscribe("voice.on_peer_left", function(data) {
  if (!data?.uid)
    return

  let uid = hexStringToInt(data.uid) // uid is passed as hex string
  logX($"voice.on_peer_left: data.uid -> {data.uid}, uid -> {uid}, name -> {data.name}")
  remove_voice_chat_member(uid)
})


friendsUids.subscribe(function(v) {
  foreach (uid, _ in voiceChatMembers) {
    let isFriend = (uid.tostring() in v)
    update_voice_chat_member_friendship(uid, isFriend)
  }
})


isLoggedIn.subscribe(function(v) {
  if (v) {
    logX("Adding delayed chat users")
    debugTableData(delayedChatMembers)
    foreach (uid, _ in delayedChatMembers) {
      add_user_to_chat(uid)
    }
    delayedChatMembers.clear()
  }
})


subscribe_to_state_update(on_state_update)
