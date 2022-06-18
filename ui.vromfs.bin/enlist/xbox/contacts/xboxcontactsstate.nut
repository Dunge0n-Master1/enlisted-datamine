from "%enlSqGlob/ui_library.nut" import *

let sharedWatched = require("%dngscripts/sharedWatched.nut")

let xboxUids = sharedWatched("xboxUids", @() {
  uid2xbox = {}
  xbox2uid = {}
})

let uid2xbox = Computed(@() xboxUids.value.uid2xbox)
let xbox2uid = Computed(@() xboxUids.value.xbox2uid)

return {
  friends = sharedWatched("xboxFriends", @() [])
  blocked = sharedWatched("xboxBlockedUsers", @() [])
  muted   = sharedWatched("xboxMuted", @() [])
  xboxUids
  uid2xbox
  xbox2uid
}