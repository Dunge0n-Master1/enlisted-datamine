from "%enlSqGlob/ui_library.nut" import *

let {addModalWindow, removeModalWindow} = require("%ui/components/modalWindows.nut")
let { mkRankIcon, getRankConfig } = require("%enlSqGlob/ui/rankPresentation.nut")
let { playerRank, rankUnlock } = require("%enlist/profile/rankState.nut")
let { mkSeasonTime } = require("%enlist/battlepass/rewardsPkg.nut")
let { timeLeft } = require("%enlist/battlepass/bpState.nut")
let { Bordered } = require("%ui/components/textButton.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { h2_txt, tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  bigPadding, smallPadding, idleBgColor, accentTitleTxtColor, defTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")

const RANK_WND_UID = "RankToolTip"
const MAX_RANKS_IN_COLUMN = 10

let rankRowHeight = hdpx(40)
let rankRewardIconSize = hdpx(12)
let columnRankHeigth = (rankRowHeight + smallPadding) * MAX_RANKS_IN_COLUMN

let wrapParams = {
  height = columnRankHeigth
  width = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  hGap = hdpx(100)
  vGap = smallPadding
}

let function ranksRow(stage) {
  let { progress, ratingOnNextSeason, index, rewardLocId = null } = stage
  return {
    flow = FLOW_HORIZONTAL
    size = [hdpx(330), rankRowHeight]
    gap = hdpx(10)
    children = [
      {
        rendObj = ROBJ_TEXT
        size = [hdpx(20), SIZE_TO_CONTENT]
        halign = ALIGN_RIGHT
        text = index
        color = idleBgColor
      }
      mkRankIcon(index)
      {
        rendObj = ROBJ_TEXT
        size = [flex(), SIZE_TO_CONTENT]
        text = loc(getRankConfig(index).locId)
      }
      {
        rendObj = ROBJ_TEXT
        hplace = ALIGN_RIGHT
        color = accentTitleTxtColor
        text = progress
      }
      {
        rendObj = ROBJ_IMAGE
        color = rewardLocId == null ? idleBgColor : defTxtColor
        margin = [hdpx(5), 0, 0, 0]
        size = [rankRewardIconSize, rankRewardIconSize]
        image = Picture($"!ui/uiskin/reward_player_icon.svg:{rankRewardIconSize}:{rankRewardIconSize}:K")
        behavior = Behaviors.Button
        onHover = @(on) setTooltip(on
          ? tooltipBox({
              flow = FLOW_VERTICAL
              children = [
                txt(loc("rank/nextSeasonPoints", {rating = ratingOnNextSeason / 100}))
                rewardLocId == null ? null : txt(loc($"rank/{rewardLocId}/info"))
              ]
            })
          : null)
      }
    ]
  }
}

let function ranksTable() {
  if (rankUnlock.value == null)
    return null

  return {
    flow = FLOW_HORIZONTAL
    watch = rankUnlock
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    margin = [hdpx(50), 0, hdpx(20), 0]
    hplace = ALIGN_CENTER
    children = wrap(rankUnlock.value.map(ranksRow), wrapParams)
  }
}

let headerBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  margin = [hdpx(15), 0]
  children = [
    @() {
      watch = timeLeft
      gap = bigPadding
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("bp/timeLeft")
          color = defTxtColor
        }
        timeLeft.value > 0 ? mkSeasonTime(timeLeft.value) : null
      ]
    }
    {
      hplace = ALIGN_RIGHT
      flow = FLOW_HORIZONTAL
      children = [
        {
          rendObj = ROBJ_TEXT
          hplace = ALIGN_RIGHT
          text = loc("rank/playerRating")
        }
        @() {
          rendObj = ROBJ_TEXT
          watch = playerRank
          text = $"{(playerRank.value?.rating ?? 0) / 100}"
          color = accentTitleTxtColor
        }
      ]
    }
  ]
}

let rankToolTip = {
  rendObj = ROBJ_SOLID
  color = Color(0, 0, 0, 210)
  size = [flex(), SIZE_TO_CONTENT]
  vplace = ALIGN_CENTER
  children = {
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    flow = FLOW_VERTICAL
    size = [hdpx(760), SIZE_TO_CONTENT]
    padding = [hdpx(20), 0]
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("rank/title")
      }.__update(h2_txt)
      headerBlock
      {
        rendObj = ROBJ_TEXTAREA
        size = [flex(), SIZE_TO_CONTENT]
        behavior = Behaviors.TextArea
        text = loc("rank/description")
      }
      ranksTable
      {
        size = [flex(), SIZE_TO_CONTENT]
        children = {
          rendObj = ROBJ_TEXT
          text = loc("rank/needAchieve")
          color = accentTitleTxtColor
        }.__update(tiny_txt)
      }
      {
        flow = FLOW_HORIZONTAL
        margin = [hdpx(10), 0]
        gap = hdpx(10)
        children = [
          {
            rendObj = ROBJ_IMAGE
            color = idleBgColor
            vplace = ALIGN_CENTER
            size = [rankRewardIconSize, rankRewardIconSize]
            image = Picture($"!ui/uiskin/reward_player_icon.svg:{rankRewardIconSize}:{rankRewardIconSize}:K")
          }
          {
            rendObj = ROBJ_TEXT
            text = loc ("rank/rewardTip")
          }.__update(tiny_txt)
        ]
      }
      Bordered(loc("BackBtn"), @() removeModalWindow(RANK_WND_UID),
        {
          hplace = ALIGN_RIGHT
          margin = 0
          hotkeys = [["^J:B | Esc", { description = loc("BackBtn") } ]]
        }
      )
    ]
  }
}


let open = @() addModalWindow({
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = flex()
  vplace = ALIGN_CENTER
  key = RANK_WND_UID
  onClick = @() null
  children = rankToolTip
})

return open