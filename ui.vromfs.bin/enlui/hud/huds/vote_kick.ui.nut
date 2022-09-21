from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { voteToKickAccusedName, voteToKickAccused, voteToKickYes, voteToKickNo, lastKickedPlayerInfo } = require("%ui/hud/state/vote_kick_state.nut")
let { pushSystemMsg } = require("%ui/hud/state/chat.nut")
let { mkHeaderFlag, casualFlagStyle }= require("%enlSqGlob/ui/mkHeaderFlag.nut")
let { blurBgColor } = require("%enlSqGlob/ui/viewConst.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { voteToKick, canVoteToKick } = require("vote_kick_common.nut")
let { controlHudHint } = require("%ui/components/controlHudHint.nut")

let minWidth = hdpx(200)
let voteToKickPadding = hdpx(8)

lastKickedPlayerInfo.subscribe(function(info) {
  if (info.name == null)
    return

  let text = info.kicked ? "voteKick/accussedKicked" : "voteKick/notEnoughVotes"
  pushSystemMsg(loc(text, { name = info.name }))
})

let voteToKickHeader = @(){
  watch = isGamepad
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  gap = voteToKickPadding
  children = [
    isGamepad.value ? controlHudHint("HUD.GameMenu") : null
    mkHeaderFlag(
      {
        rendObj = ROBJ_TEXT
        minWidth
        text = loc("voteKick/header")
        padding = voteToKickPadding
      }.__update(body_txt),
      casualFlagStyle.__update({ offset = 0 })
    )
  ]
}

let voteToKickButtonBody = {
  size = flex()
  flow = FLOW_HORIZONTAL
  valign = ALIGN_BOTTOM
  eventHandlers = {
    ["VoteKick.Yes"] = @(...) voteToKick(voteToKickAccused.value, true),
    ["VoteKick.No"] = @(...) voteToKick(voteToKickAccused.value, false)
  }
  behavior = Behaviors.ActivateActionSet
  actionSet = "VoteKick"
  children = [
    tipCmp({
      text = loc("hint/VoteKick.Yes")
      inputId = "VoteKick.Yes"
      style = {
        rendObj = null
      }
    }.__update(body_txt))
    tipCmp({
      text = loc("hint/VoteKick.No")
      inputId = "VoteKick.No"
      style = {
        rendObj = null
      }
    }.__update(body_txt))
  ]
}

let voteToKickCountBody = @(yesCount, noCount) {
  size = flex()
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("voteKick/countYes", {count=yesCount} )
    }.__update(sub_txt)

    {
      rendObj = ROBJ_TEXT
      text = loc("voteKick/countNo", {count=noCount} )
    }.__update(sub_txt)
  ]
}

let voteToKickBody = @(name) @(){
  rendObj = ROBJ_WORLD_BLUR_PANEL
  watch = [isGamepad, canVoteToKick, voteToKickYes, voteToKickNo]
  size = [SIZE_TO_CONTENT, flex()]
  minWidth
  flow = FLOW_VERTICAL
  color = blurBgColor
  padding = voteToKickPadding
  gap = hdpx(4)
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("voteKick/desc")
    }.__update(sub_txt)
    {
      rendObj = ROBJ_TEXT
      text = loc("voteKick/accussedName", {name} )
    }.__update(body_txt)
    !canVoteToKick.value
        ? voteToKickCountBody(voteToKickYes.value.len(), voteToKickNo.value.len())
      : isGamepad.value ? null : voteToKickButtonBody
  ]
}

return function() {
  let res = {
    watch = voteToKickAccusedName
  }

  if (voteToKickAccusedName.value == null)
     return res

  return res.__update({
    size = [SIZE_TO_CONTENT, hdpx(184)]
    flow = FLOW_VERTICAL
    minWidth
    margin = [0, 0, hdpx(50), 0]
    children = [
      voteToKickHeader
      voteToKickBody(voteToKickAccusedName.value)
    ]
  })
}
