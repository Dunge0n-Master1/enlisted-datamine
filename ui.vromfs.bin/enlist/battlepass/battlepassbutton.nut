from "%enlSqGlob/ui_library.nut" import *

let { fontXLarge, fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { smallPadding, bigPadding, defTxtColor, titleTxtColor, startBtnWidth, colPart,
  defHorGradientImg, hoverHorGradientImg, midPadding
} = require("%enlSqGlob/ui/designConst.nut")
let { BP_INTERVAL_STARS } = require("%enlSqGlob/bpConst.nut")
let { hasReward, currentProgress, nextUnlock } = require("%enlist/battlepass/bpState.nut")
let { getOneReward, mkRewardIcon, rewardIconWidth } = require("%enlist/battlepass/rewardPkg.nut")
let { openBPwindow } = require("%enlist/battlepass/bpWindowState.nut")
let { timeTracker } = require("%enlist/battlepass/battlePassPkg.nut")
let { rewardAnimBg, taskLabelSize } = require("%enlSqGlob/ui/tasksPkg.nut")
let { canTakeDailyTaskReward } = require("%enlist/unlocks/taskListState.nut")
let { hasEliteBattlePass } = require("%enlist/battlepass/eliteBattlePass.nut")
let { sound_play } = require("sound")
let { bpStarsAnimGen } = require("%enlist/unlocks/weeklyUnlocksState.nut")
let { soundDefault } = require("%ui/components/textButton.nut")
let { mkColoredGradientX } = require("%enlSqGlob/ui/gradients.nut")
let { dynamicSeasonBPIcon } = require("battlePassPkg.nut")


let defTxtStyle = { color = titleTxtColor }.__update(fontXLarge)
let smallTxtStyle = { color = defTxtColor }.__update(fontSmall)
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


let function mkStar(idx, isFilled = false, hasRewardAnim = false, hasAppearAnim = false) {
  let trigger = $"bp_star_{idx}"
  return {
    size = [starSize, starSize]
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [starSize, starSize]
        image = Picture("ui/skin#tasks/star_empty.svg:{0}:{0}:K".subst(starSize))
      }
      !isFilled ? null
        : {
            rendObj = ROBJ_IMAGE
            size = [starSize, starSize]
            image = Picture("ui/skin#tasks/star_filled.svg:{0}:{0}:K".subst(starSize))
            transform = {}
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


let function taskLimitMessage() {
  let res = { watch = canTakeDailyTaskReward, hasEliteBattlePass}
  if (canTakeDailyTaskReward.value && !hasEliteBattlePass.value)
    return res
  return res.__update({
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    size = [flex(), SIZE_TO_CONTENT]
    padding = [0, bigPadding]
    margin = [smallPadding, 0]
    color = defTxtColor
    text = loc("unlocks/dailyTasksLimit")
  }.__update(smallTxtStyle))
}


let titleBpBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("bp/battlePassUpper")
    }.__update(defTxtStyle)
    rewardProgress
    taskLimitMessage
  ]
}


let function rewardBpBlock() {
  let item = nextUnlock.value
  let { reward = null } = getOneReward(item?.rewards ?? {})
  let cardIcon = mkRewardIcon(reward, rewardIconWidth)
  return {
    watch = nextUnlock
    size = [SIZE_TO_CONTENT, bpButtonHeight]
    padding = [0, taskLabelSize[0] + smallPadding, 0, 0]
    valign = ALIGN_CENTER
    children = cardIcon
  }
}


let mkWidgetInfo = @(sf) {
  size = [flex(), SIZE_TO_CONTENT]
  minHeight = bpButtonHeight
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = flex()
      image = defHorGradientImg
    }
    sf & S_HOVER
      ? {
          rendObj = ROBJ_IMAGE
          size = flex()
          image = hoverHorGradientImg
          animations = [{
            prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true
          }]
        }
      : null
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
            titleBpBlock
            rewardBpBlock
          ]
        }
      ]
    }
  ]
}

let lineGradient = mkColoredGradientX(0x5AFFFFFF, 0x00FFFFFF, 12, false)
let highlightLine = @(isTop = true) {
  rendObj = ROBJ_IMAGE
  size = [flex(), colPart(0.064)]
  image = lineGradient
  vplace = isTop ? ALIGN_TOP : ALIGN_BOTTOM
}

let bpWidgetOpen = {
  size = [startBtnWidth, SIZE_TO_CONTENT]
  children = [
    timeTracker({ pos = [0, -(fontSmall.fontSize + midPadding)] })
    {
      size = [flex(), SIZE_TO_CONTENT]
      children = [
        watchElemState(@(sf) {
          size = [flex(), SIZE_TO_CONTENT]
          sound = soundDefault
          behavior = Behaviors.Button
          onClick = @() openBPwindow()
          children = mkWidgetInfo(sf)
        })
        highlightLine()
        highlightLine(false)
      ]
    }
  ]
}

console_register_command(@() openBPwindow(), "ui.battlepassWindow")

return bpWidgetOpen
