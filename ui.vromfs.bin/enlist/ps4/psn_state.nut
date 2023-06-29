from "%enlSqGlob/ui_library.nut" import *

let {nestWatched} = require("%dngscripts/globalState.nut")

let psnUids = nestWatched("psnUids", {
  uid2psn = {}
  psn2uid = {}
})
let psnUidsUpdate = @(v) psnUids.update(v)
let uid2psn = Computed(@() psnUids.value.uid2psn)
let psn2uid = Computed(@() psnUids.value.psn2uid)
let psn_friends = nestWatched("psn_friends", [])
let psn_friendsUpdate = @(v) psn_friends.update(v)
let psn_blocked_users = nestWatched("psn_blocked_users", [])
let psn_blocked_usersUpdate = @(v) psn_blocked_users.update(v)
let psn_invitation_data = nestWatched("psn_invitation_data",  null)
let psn_invitation_dataUpdate = @(v) psn_invitation_data(v)
let psn_was_logged_out = nestWatched("psn_was_logged_out", false)
let psn_was_logged_outUpdate = @(v) psn_was_logged_out(v)
let psn_game_intent = nestWatched("psn_game_intent", null)
let psn_game_intentUpdate = @(v) psn_game_intent(v)

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
