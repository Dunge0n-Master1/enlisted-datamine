from "%enlSqGlob/ui_library.nut" import *

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor, bigPadding, titleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { timeLeft } = require("%enlist/battlePass/bpState.nut")
let { mkSeasonTime } = require("%enlist/battlePass/rewardPkg.nut")

let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let hoverTxtStyle = { color = titleTxtColor }.__update(fontSmall)

let timeTracker = @(sf) @() {
  watch = timeLeft
  gap = bigPadding
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = timeLeft.value > 0
    ? [
        {
          rendObj = ROBJ_TEXT
          text = loc("bp/timeLeft")
        }.__update(sf & S_HOVER ? hoverTxtStyle : defTxtStyle)
        mkSeasonTime(timeLeft.value)
      ]
    : {
        rendObj = ROBJ_TEXT
        text = loc("bp/timeExpired")
      }.__update(sf & S_HOVER ? hoverTxtStyle : defTxtStyle)
}


return {
  timeTracker
}
