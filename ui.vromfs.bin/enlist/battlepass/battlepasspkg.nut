from "%enlSqGlob/ui_library.nut" import *

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor, bigPadding, titleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { timeLeft, seasonIndex } = require("bpState.nut")
let { mkSeasonTime } = require("%enlist/battlepass/rewardPkg.nut")

let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let hoverTxtStyle = { color = titleTxtColor }.__update(fontSmall)

let imagePath = "!ui/uiskin/battlepass/bp_seasons/bp_season_{0}.svg:{1}:{1}:K"

let staticSeasonBPIcon = @(seasonBPIndex, size) {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  fallbackImage = Picture($"!ui/uiskin/battlepass/bp_logo.svg:{size}:{size}:K")
  image = Picture(imagePath.subst(seasonBPIndex, size))
}

let dynamicSeasonBPIcon = @(size) @()
  staticSeasonBPIcon(seasonIndex.value, size).__update({ watch = seasonIndex })

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
  dynamicSeasonBPIcon
  staticSeasonBPIcon
}
