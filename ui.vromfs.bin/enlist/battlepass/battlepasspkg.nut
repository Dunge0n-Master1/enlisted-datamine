from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { titleTxtColor } = require("%enlSqGlob/ui/designConst.nut")
let { timeLeft, seasonIndex } = require("bpState.nut")
let { mkSeasonTime } = require("%enlist/battlepass/rewardPkg.nut")

let defTxtStyle = { color = titleTxtColor }.__update(fontSub)

let imagePath = "!ui/uiskin/battlepass/bp_seasons/bp_season_{0}.svg:{1}:{1}:K"
let bpBgPath = "!ui/uiskin/battlepass/bp_seasons/bp_bg_{0}.avif"

let bpColors =  freeze([0xFFD04B2C, 0xFF31DDED, 0xFFC5EA2D, 0xFFF57E32])

let function staticSeasonBPIcon(seasonBPIndex, size) {
  let fallbackImage = $"!ui/uiskin/battlepass/bp_logo.svg:{size}:{size}:K"
  let bpImagePath = (seasonBPIndex ?? 0) > 0 ? imagePath.subst(seasonBPIndex, size) : fallbackImage
  return {
    rendObj = ROBJ_IMAGE
    size = [size, size]
    image = Picture(bpImagePath)
    fallbackImage = Picture(fallbackImage)
  }
}


let dynamicSeasonBpBg = @(size, opacity) function() {
  let bpIdx = seasonIndex.value % bpColors.len()
  let bpImagePath = bpBgPath.subst(bpIdx)
  return {
    watch = seasonIndex
    rendObj = ROBJ_IMAGE
    size
    opacity
    image = Picture(bpImagePath)
  }
}

let dynamicSeasonBPIcon = @(size) @()
  staticSeasonBPIcon(seasonIndex.value, size).__update({ watch = seasonIndex })

let timeTracker = @() {
  watch = timeLeft
  hplace = ALIGN_RIGHT
  children = timeLeft.value > 0
    ? mkSeasonTime(timeLeft.value)
    : {
        rendObj = ROBJ_TEXT
        text = loc("bp/timeExpired")
      }.__update(defTxtStyle)
}


return {
  timeTracker
  dynamicSeasonBPIcon
  staticSeasonBPIcon
  dynamicSeasonBpBg
  bpColors
}
