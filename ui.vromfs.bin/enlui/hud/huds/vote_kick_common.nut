from "%enlSqGlob/ui_library.nut" import *
let { sendNetEvent, CmdVoteToKick } = require("dasevents")
let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let { voteToKickYes, voteToKickNo } = require("%ui/hud/state/vote_kick_state.nut")

let voteToKick = @(accused, voteYes)
  sendNetEvent(localPlayerEid.value, CmdVoteToKick({ voteYes accused }))

let canVoteToKick = Computed(@()
  (voteToKickYes.value.findindex(@(v) v == localPlayerEid.value) == null
    && voteToKickNo.value.findindex(@(v) v == localPlayerEid.value) == null))

return {
  voteToKick
  canVoteToKick
}