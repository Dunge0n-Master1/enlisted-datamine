from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let {
  defBgColor, smallPadding, bigPadding, defTxtColor,
  titleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { BP_INTERVAL_STARS } = require("%enlSqGlob/bpConst.nut")
let {
  hasReward, currentProgress, nextUnlock
} = require("bpState.nut")
let { startBtnWidth } = require("%enlist/startBtn.nut")
let { getOneReward, mkRewardIcon  } = require("rewardsPkg.nut")
let { openBPwindow } = require("bpWindowState.nut")
let { timeTracker } = require("bpPkg.nut")
let {
  taskSlotPadding, rewardAnimBg, mkTaskLabel
} = require("%enlSqGlob/ui/taskPkg.nut")
let { canTakeDailyTaskReward } = require("%enlist/unlocks/taskListState.nut")
let { hasEliteBattlePass } = require("eliteBattlePass.nut")
let { sound_play } = require("sound")
let { bpStarsAnimGen } = require("%enlist/unlocks/weeklyUnlocksState.nut")
let { soundDefault } = require("%ui/components/textButton.nut")
let { dynamicSeasonBPIcon } = require("battlePassPkg.nut")



let starSize = hdpxi(20)
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
      isFilled
        ? {
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
              { prop = AnimProp.translate, from = [hdpx(50 + idx * 40),-hdpx(30)], to = [0,0],
                duration = 0.5, play = hasAppearAnim, trigger }
            ]
          }
        : null
      hasRewardAnim ? rewardAnimBg : null
    ]
  }
}

let function rewardProgress() {
  let hasRewardVal = hasReward.value
  return {
    watch = hasReward
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    valign = ALIGN_CENTER
    children = [
      txt({
        key = $"reward_{hasRewardVal}"
        text = hasRewardVal
          ? utf8ToUpper(loc("bp/getNextReward"))
          : loc("nextReward")
        color = hasRewardVal ? titleTxtColor : defTxtColor
        animations = hasRewardVal
          ? [{
              prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1,
              play = true, loop = true, easing = Blink
            }]
          : null
      })
      function() {
        let { required, current, interval } = currentProgress.value
        let starFactor = (interval / BP_INTERVAL_STARS).tointeger()
        let filledStars = current >= required || hasReward.value
          ? BP_INTERVAL_STARS
          : clamp(((current + interval - required) / starFactor).tointeger(), 0, BP_INTERVAL_STARS - 1)
        let visible = visibleStars ?? BP_INTERVAL_STARS
        visibleStars = hasRewardVal ? BP_INTERVAL_STARS : filledStars
        return {
          watch = currentProgress
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = array(BP_INTERVAL_STARS).map(function(_, idx) {
            let isFilled = hasRewardVal || idx < filledStars
            let hasAppearAnim = hasRewardVal && idx > visible - 1 ? true
              : idx < filledStars && idx > visible - 1 ? true
              : false
            return mkStar(idx, isFilled, hasRewardVal, hasAppearAnim)
          })
        }
      }
    ]
  }
}

let rewardIconWidth = hdpx(46)
let leftContentSize = startBtnWidth - rewardIconWidth - bigPadding * 4

let taskLimitMessage = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = [leftContentSize , SIZE_TO_CONTENT]
  padding = [smallPadding, bigPadding]
  margin = [hdpx(30), 0]
  color = defTxtColor
  text = loc("unlocks/dailyTasksLimit")
}

let function mkWidgetInfo(sf) {
  let item = nextUnlock.value
  let { reward = null } = getOneReward(item?.rewards ?? {})
  let cardIcon = mkRewardIcon(reward, rewardIconWidth, { vplace = ALIGN_CENTER })
  return @() {
    watch = [hasReward, canTakeDailyTaskReward, hasEliteBattlePass]
    size = [flex(), SIZE_TO_CONTENT]
    children = [
      sf & S_HOVER
        ? {
            rendObj = ROBJ_SOLID
            size = flex()
            color = defBgColor
            animations = [{
              prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true
            }]
          }
        : null
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        padding = taskSlotPadding
        gap = bigPadding
        children = [
          {
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            children = dynamicSeasonBPIcon(hdpx(42))
          }
          {
            flow = FLOW_VERTICAL
            size = [flex(), SIZE_TO_CONTENT]
            gap = smallPadding
            children = [
              timeTracker
              {
                flow = FLOW_HORIZONTAL
                size = [flex(), SIZE_TO_CONTENT]
                gap = smallPadding
                children = [
                  {
                    flow = FLOW_VERTICAL
                    size = [flex(), SIZE_TO_CONTENT]
                    gap = smallPadding
                    children = [
                      txt({
                        text = loc("bp/battlePassUpper")
                        color = sf & S_HOVER ? titleTxtColor : defTxtColor
                      }).__update(h2_txt)
                      rewardProgress
                    ]
                  }
                  cardIcon
                  mkTaskLabel()
                ]
              }
              !canTakeDailyTaskReward.value && hasEliteBattlePass.value
                ? taskLimitMessage
                : null
            ]
          }
        ]
      }
    ]
  }
}

let bpWidgetOpen = @() {
  flow = FLOW_VERTICAL
  children = [
    watchElemState(@(sf) {
      size = [startBtnWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      behavior = Behaviors.Button
      onClick = @() openBPwindow()
      sound = soundDefault
      children = mkWidgetInfo(sf)
    })
  ]
}

console_register_command(@() openBPwindow(), "ui.battlepassWindow")

return bpWidgetOpen
