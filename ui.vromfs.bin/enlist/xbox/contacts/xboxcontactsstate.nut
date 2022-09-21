from "%enlSqGlob/ui_library.nut" import *

let {globalWatched} = require("%dngscripts/globalState.nut")

let {xboxUids, xboxUidsUpdate} = globalWatched("xboxUids", @() {
  uid2xbox = {}
  xbox2uid = {}
})

let uid2xbox = Computed(@() xboxUids.value.uid2xbox)
let xbox2uid = Computed(@() xboxUids.value.xbox2uid)
let {xboxFriends, xboxFriendsUpdate} = globalWatched("xboxFriends", @() [])
let {xboxBlockedUsers, xboxBlockedUsersUpdate} = globalWatched("xboxBlockedUsers", @() [])
let {xboxMuted, xboxMutedUpdate} = globalWatched("xboxMuted", @() [])

return {
  xboxFriends, xboxFriendsUpdate,
  xboxBlockedUsers, xboxBlockedUsersUpdate,
  xboxMuted, xboxMutedUpdate,
  xboxUids, xboxUidsUpdate
  uid2xbox,
  xbox2uid
}