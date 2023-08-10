from "%enlSqGlob/ui_library.nut" import *

let { fontXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { smallPadding, bigPadding, defTxtColor, startBtnWidth, colPart, transpPanelBgColor, defItemBlur,
  highlightLineTop, hoverSlotBgColor, darkTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let { BP_INTERVAL_STARS } = require("%enlSqGlob/bpConst.nut")
let { hasReward, currentProgress, nextUnlock, seasonIndex } = require("%enlist/battlepass/bpState.nut")
let { getOneReward, mkRewardIcon, rewardIconWidth } = require("%enlist/battlepass/rewardPkg.nut")
let { openBPwindow } = require("%enlist/battlepass/bpWindowState.nut")
let { timeTracker, dynamicSeasonBPIcon, bpColors, dynamicSeasonBpBg
} = require("%enlist/battlepass/battlePassPkg.nut")
let { rewardAnimBg, taskLabelSize } = require("%enlSqGlob/ui/tasksPkg.nut")
let { sound_play } = require("%dngscripts/sound_system.nut")
let { bpStarsAnimGen } = require("%enlist/unlocks/weeklyUnlocksState.nut")
let { soundDefault } = require("%ui/components/textButton.nut")
let { hasBattlePass } = require("%enlist/unlocks/taskRewardsState.nut")


let starSize = colPart(0.33)
let bpButtonHeight = colPart(1.3) + smallPadding * 2
local visibleStars = null
let showUnseenBPStars = function() {
  for (local i = 0; i < BP_INTERVAL_STARS; i++)
    anim_start($"bp_star_{i}")
}


bpStarsAnimGen.subscribe(function(_v) {
  gui_scene.resetTimeout(0.1, showUnseenBPStars)
})


let mkStar = @(idx, isFilled = false, hasRewardAnim = false, hasAppearAnim = false) function() {
  let trigger = $"bp_star_{idx}"
  let colorIdx = seasonIndex.value % bpColors.len()
  return {
    watch = seasonIndex
    size = [starSize, starSize]
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [starSize, starSize]
        color = bpColors[colorIdx]
        image = Picture("ui/skin#star_level_empty.svg:{0}:{0}:K".subst(starSize))
      }
      !isFilled ? null
        : {
            rendObj = ROBJ_IMAGE
            size = [starSize, starSize]
            image = Picture("ui/skin#star_level_filled.svg:{0}:{0}:K".subst(starSize))
            transform = {}
            color = bpColors[colorIdx]
            animations = [
              { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3,
                play = hasAppearAnim, onFinish = @() sound_play("ui/debriefing/squad_star"),
                trigger }
              { prop = AnimProp.scale, from = [3,3], to = [1,1], duration = 0.5,
                play = hasAppearAnim, trigger }
              { prop = AnimProp.translate, from = [colPart(0.82 + idx * 0.65),-colPart(0.49)],
                to = [0,0], duration = 0.5, play = hasAppearAnim, trigger }
            ]
          }
      hasRewardAnim ? rewardAnimBg : null
    ]
  }
}


let function rewardProgress() {
  let hasRewardVal = hasReward.value
  let { required, current, interval } = currentProgress.value
  let starFactor = (interval / BP_INTERVAL_STARS).tointeger()
  let filledStars = current >= required || hasReward.value
    ? BP_INTERVAL_STARS
    : clamp(((current + interval - required) / starFactor).tointeger(),
      0, BP_INTERVAL_STARS - 1)
  let visible = visibleStars ?? BP_INTERVAL_STARS
  visibleStars = hasRewardVal ? BP_INTERVAL_STARS : filledStars
  return {
    watch = currentProgress
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    children = array(BP_INTERVAL_STARS).map(function(_, idx) {
      let isFilled = hasRewardVal || idx < filledStars
      let hasAppearAnim = isFilled && idx > visible - 1
      return mkStar(idx, isFilled, hasRewardVal, hasAppearAnim)
    })
  }
}


let titleBpBlock = @(sf) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("bp/battlePassUpper")
      color = sf & S_HOVER ? darkTxtColor : defTxtColor
    }.__update(fontXLarge)
    rewardProgress
  ]
}


let function rewardBpBlock() {
  let item = nextUnlock.value
  let { reward = null } = getOneReward(item?.rewards ?? {})
  let cardIcon = mkRewardIcon(reward, rewardIconWidth)
  return {
    watch = nextUnlock
    size = [SIZE_TO_CONTENT, bpButtonHeight]
    padding = [0, taskLabelSize[0], 0, 0]
    valign = ALIGN_CENTER
    children = cardIcon
  }
}


let mkWidgetInfo = @(sf) {
  size = [flex(), SIZE_TO_CONTENT]
  animations = [{
    prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true
  }]
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      valign = ALIGN_CENTER
      padding = [smallPadding, 0, smallPadding, bigPadding]
      children = [
        dynamicSeasonBPIcon(colPart(0.85))
        {
          size = [flex(), SIZE_TO_CONTENT]
          valign = ALIGN_CENTER
          vplace = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = [
            titleBpBlock(sf)
            rewardBpBlock
          ]
        }
      ]
    }
  ]
}

let mkBpWidgetOpen = @(onHover = null) @() {
  watch = hasBattlePass
  size = [startBtnWidth, SIZE_TO_CONTENT]
  children = !hasBattlePass.value ? null : watchElemState(@(sf) {
    rendObj = ROBJ_WORLD_BLUR
    size = [flex(), SIZE_TO_CONTENT]
    minHeight = bpButtonHeight
    color = defItemBlur
    fillColor = sf & S_HOVER ? hoverSlotBgColor : transpPanelBgColor
    behavior = Behaviors.Button
    sound = soundDefault
    onClick = openBPwindow
    onHover
    children = [
      timeTracker
      dynamicSeasonBpBg([colPart(6), colPart(1.58)], (sf & S_HOVER) != 0 ? 1 : 0.7)
      mkWidgetInfo(sf)
      highlightLineTop
    ]
  })
}

console_register_command(@() openBPwindow(), "ui.battlepassWindow")

return mkBpWidgetOpen
