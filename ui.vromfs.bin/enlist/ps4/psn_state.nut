from "%enlSqGlob/ui_library.nut" import *

let {globalWatched} = require("%dngscripts/globalState.nut")

let {psnUids, psnUidsUpdate} = globalWatched("psnUids", @() {
  uid2psn = {}
  psn2uid = {}
})

let uid2psn = Computed(@() psnUids.value.uid2psn)
let psn2uid = Computed(@() psnUids.value.psn2uid)
let {psn_friends, psn_friendsUpdate} = globalWatched("psn_friends", @() [])
let {psn_blocked_users, psn_blocked_usersUpdate} = globalWatched("psn_blocked_users", @() [])
let {psn_invitation_data, psn_invitation_dataUpdate} = globalWatched("psn_invitation_data", @() null)
let {psn_was_logged_out, psn_was_logged_outUpdate} = globalWatched("psn_was_logged_out", @() false)
let {psn_game_intent, psn_game_intentUpdate} = globalWatched("psn_game_intent", @() null)

return {
  psn_friends
  psn_friendsUpdate
  psn_blocked_users
  psn_blocked_usersUpdate
  psnUids
  psnUidsUpdate
  uid2psn
  psn2uid
  psn_invitation_data
  psn_invitation_dataUpdate
  psn_was_logged_out
  psn_was_logged_outUpdate
  psn_game_intent
  psn_game_intentUpdate
}
