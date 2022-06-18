from "%enlSqGlob/ui_library.nut" import *

let {show_profile_card} = require("%xboxLib/impl/user.nut")
let {request_known_xuid} = require("%enlist/xbox/userIds.nut")
let { uid2console } = require("%enlist/contacts/consoleUidsRemap.nut")
let eventbus = require("eventbus")


let function showProfileCard(live_xuid) {
  if (live_xuid)
    show_profile_card(live_xuid.tointeger(), null)
}


let function showUserInfo(userId) {
  let uid = userId.tostring()
  if (uid in uid2console.value) {
    showProfileCard(uid2console.value[uid])
  } else {
    request_known_xuid(uid, function(_, xuid) {
      showProfileCard(xuid)
    })
  }
}

eventbus.subscribe("showXboxUserInfo", @(msg) showUserInfo(msg.userId.tointeger()))
