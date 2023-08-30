from "%enlSqGlob/ui_library.nut" import *
let { fontHeading1, fontSub, fontHeading2 } = require("%enlSqGlob/ui/fontsStyle.nut")
let textButton = require("%ui/components/textButton.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { mkHeaderFlag, casualFlagStyle }= require("%enlSqGlob/ui/mkHeaderFlag.nut")
let { voteToKickAccusedName, voteToKickYes, voteToKickNo, voteToKickAccused } = require("%ui/hud/state/vote_kick_state.nut")
let { blurBgFillColor, commonBtnHeight, titleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { voteToKick, canVoteToKick } = require("vote_kick_common.nut")

let voteToKickPadding = hdpx(8)

let VoteToKickButtonStyleDisable = {
  size = [flex(), SIZE_TO_CONTENT]
  isEnabled = false
  margin = 0
  textParams = {
    color = titleTxtColor
  }
}

let voteKickButtonsBody = [
  textButton(loc("hint/VoteKick.Yes"), @() voteToKick(voteToKickAccused.value, true), {
    size = [flex(), commonBtnHeight]
    hotkeys = [ ["^J:Y", {description={skip=true} sound="click"}] ]
    margin = 0
  })
  textButton(loc("hint/VoteKick.No"), @() voteToKick(voteToKickAccused.value, false), {
    size = [flex(), commonBtnHeight]
    hotkeys = [ ["^J:X", {description={skip=true} sound="click"}] ]
    margin = 0
  })
]

let voteKickVotesBody = @(yesCount, noCount) [
  textButton(loc("voteKick/countYes", {count=yesCount} ), null, VoteToKickButtonStyleDisable )
  textButton(loc("voteKick/countNo", {count=noCount} ), null, VoteToKickButtonStyleDisable )
]

let voteToKickHeader = mkHeaderFlag(
  {
    rendObj = ROBJ_TEXT
    text = loc("voteKick/header")
    padding = [voteToKickPadding, hdpx(24)]
  }.__update(fontHeading1),
  casualFlagStyle.__update({ offset = voteToKickPadding * 2})
)

let voteToKickBody = @(name) {
  size = [sh(35), sh(12)]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = blurBgFillColor
  flow = FLOW_VERTICAL
  padding = voteToKickPadding
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = [flex(), SIZE_TO_CONTENT]
      text = loc("voteKick/desc")
    }.__update(fontSub)
    {
      rendObj = ROBJ_TEXT
      size = flex()
      valign = ALIGN_CENTER
      text = loc("voteKick/accussedName", {name} )
    }.__update(fontHeading2)
  ]
}

return function() {
  let res = {
    watch = [voteToKickAccusedName, canVoteToKick, voteToKickYes, voteToKickNo]
  }

  if (voteToKickAccusedName.value == null)
    return res

  return res.__update({
    size = [sh(35), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    pos = [sh(90), sh(34)]
    children = [
      voteToKickHeader
      voteToKickBody(voteToKickAccusedName.value)
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        padding = [voteToKickPadding, 0]
        gap = voteToKickPadding
        children = canVoteToKick.value
          ? voteKickButtonsBody
          : voteKickVotesBody(voteToKickYes.value.len(), voteToKickNo.value.len())
      }
    ]
    eventHandlers = {
      [JB.A] = @(_event) @() voteToKick(voteToKickAccused.value, true),
      [JB.B] = @(_event) @() voteToKick(voteToKickAccused.value, false),
    }
  })
}