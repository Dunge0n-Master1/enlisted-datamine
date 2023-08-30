from "%enlSqGlob/ui_library.nut" import *

let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let { receiveTaskRewards } = require("taskListState.nut")
let { weeklyTasks, saveFinishedWeeklyTasks, triggerBPStarsAnim
} = require("weeklyUnlocksState.nut")
let { seenUnlocks, markUnlockSeen, markUnlocksOpened
} = require("%enlist/unlocks/unseenUnlocksState.nut")
let { getUnlockProgress, unlockProgress } = require("%enlSqGlob/userstats/unlocksState.nut")
let { unlockRewardsInProgress } = require("%enlSqGlob/userstats/userstat.nut")
let { smallPadding, smallOffset, tinyOffset, defBgColor, defTxtColor,
  activeTxtColor, taskProgressColor, bigPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { taskMinHeight, taskSlotPadding, mkTaskEmblem, taskHeader, taskDescription,
  taskDescPadding, mkGetTaskRewardBtn, statusBlock
} = require("%enlSqGlob/ui/tasksPkg.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let { smallUnseenNoBlink } = require("%ui/components/unseenComps.nut")
let { bpColors } = require("%enlist/battlepass/battlePassPkg.nut")
let { seasonIndex } = require("%enlist/battlepass/bpState.nut")
let { hoverSlotBgColor } = require("%enlSqGlob/ui/designConst.nut")

let finishedOpacity = 0.5
let finishedBgColor = mul_color(defBgColor, 1.0 / finishedOpacity)

let mkTaskContent = @(task, sf) function() {
  let progress = getUnlockProgress(task, unlockProgress.value)
  let { isFinished = false, activity = null } = task
  let { active = false } = activity
  return {
    watch = unlockProgress
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = tinyOffset
    valign = ALIGN_CENTER
    children = [
      mkTaskEmblem(task, progress, true, Watched(false), false, 0, seasonIndex, bpColors)
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = taskDescPadding
        opacity = isFinished || !active ? finishedOpacity : 1.0
        children = [
          taskHeader(task, progress, true, sf)
          taskDescription(task?.localization.description, sf)
        ]
      }
    ]
  }
}

let timerSize = hdpxi(18)
let timerIcon = {
  rendObj = ROBJ_IMAGE
  size = [timerSize, timerSize]
  image = Picture($"ui/skin#/battlepass/boost_time.svg:{timerSize}:{timerSize}:K")
  color = taskProgressColor
}

let function mkTaskExpireTimer(expireTime) {
  let expireText = Computed(function() {
    let expireSec = expireTime - serverTime.value
    return expireSec <= 0 ? "" : secondsToStringLoc(expireSec)
  })
  return @() {
    watch = expireText
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    vplace = ALIGN_CENTER
    children = expireText.value == "" ? null
      : [
          {
            rendObj = ROBJ_TEXT
            text = loc("unlock/expireHeader")
            color = activeTxtColor
          }.__update(fontSub)
          {
            flow = FLOW_HORIZONTAL
            gap = bigPadding
            valign = ALIGN_CENTER
            children = [
              timerIcon
              {
                rendObj = ROBJ_TEXT
                text = expireText.value
                color = taskProgressColor
              }.__update(fontSub)
            ]
          }
        ]
  }
}

let function mkWeeklyTaskSlot(task, isUnseen) {
  let { name, isFinished = false, hasReward = false, activity = null } = task
  let { end_timestamp = 0, active = false } = activity
  let hasExpireTimer = active && !isFinished
  let timeLeft = hasReward ? mkGetTaskRewardBtn(task, receiveTaskRewards, unlockRewardsInProgress)
    : !active ? {
        rendObj = ROBJ_TEXT
        text = loc("notActive")
        color = defTxtColor
      }
    : hasExpireTimer ? mkTaskExpireTimer(end_timestamp)
    : null
  return {
    size = [flex(), SIZE_TO_CONTENT]
    children = [
      watchElemState(@(sf) {
        size = [flex(), SIZE_TO_CONTENT]
        minHeight = taskMinHeight
        rendObj = ROBJ_SOLID
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        padding = taskSlotPadding
        valign = ALIGN_CENTER
        color = sf & S_HOVER ? hoverSlotBgColor : isFinished ? finishedBgColor : defBgColor
        xmbNode = XmbNode()
        behavior = Behaviors.Button
        onHover = function(on) {
          if (isUnseen)
            hoverHoldAction("markUnlockSeen", name, @(v) markUnlockSeen(v))(on)
        }
        children = [
          mkTaskContent(task, sf)
          timeLeft
        ]
      })
      statusBlock(task)
      isUnseen ? smallUnseenNoBlink : null
    ]
  }
}

let WINDOW_CONTENT_SIZE = [fsh(100), flex()]
return {
  key = "weeklyBlock"
  size = WINDOW_CONTENT_SIZE
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  padding = [fsh(2),0,0,0]
  onAttach = saveFinishedWeeklyTasks
  onDetach = function() {
    markUnlockSeen((seenUnlocks.value?.unseenWeeklyTasks ?? {}).keys())
    triggerBPStarsAnim()
    markUnlocksOpened((seenUnlocks.value?.unopenedWeeklyTasks ?? {}).keys())
  }
  children = makeVertScroll(function() {
    let unseen = seenUnlocks.value?.unseenWeeklyTasks ?? {}
    let tasks = clone weeklyTasks.value
    return {
      rendObj = ROBJ_WORLD_BLUR_PANEL
      watch = [weeklyTasks, seenUnlocks]
      size = [flex(), SIZE_TO_CONTENT]
      minHeight = ph(100)
      xmbNode = XmbContainer({
        canFocus = false
        scrollSpeed = 5
        isViewport = true
        wrap = false
      })
      flow = FLOW_VERTICAL
      gap = smallPadding
      margin = [0,0,0,smallOffset]
      halign = ALIGN_CENTER
      children = tasks
        .sort(@(a, b) b.hasReward <=> a.hasReward
          || (b?.activity.active ?? false) <=> (a?.activity.active ?? false)
          || a.isCompleted <=> b.isCompleted
          || (a?.meta.taskListPlace ?? 0) <=> (b?.meta.taskListPlace ?? 0))
        .map(@(task) mkWeeklyTaskSlot(task, task.name in unseen))
    }
  })
}
