from "%enlSqGlob/ui_library.nut" import *

let sharedWatched = require("%dngscripts/sharedWatched.nut")

let psnUids = sharedWatched("psnUids", @() {
  uid2psn = {}
  psn2uid = {}
})

let uid2psn = Computed(@() psnUids.value.uid2psn)
let psn2uid = Computed(@() psnUids.value.psn2uid)

return {
  friends = sharedWatched("ps4friends", @() [])
  blocked = sharedWatched("blocked_users", @() [])
  psnUids
  uid2psn
  psn2uid
  invitation_data = sharedWatched("invitation_data", @() null)
  psn_was_logged_out = sharedWatched("psn_was_logged_out", @() false)
  game_intent = sharedWatched("game_intent", @() null)
}
