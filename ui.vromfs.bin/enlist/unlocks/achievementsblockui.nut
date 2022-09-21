from "%enlSqGlob/ui_library.nut" import *

let { achievementsByTypes, receiveTaskRewards } = require("taskListState.nut")
let { getUnlockProgress, unlockProgress } = require("%enlSqGlob/userstats/unlocksState.nut")
let { unlockRewardsInProgress } = require("%enlSqGlob/userstats/userstat.nut")
let {
  smallPadding, bigPadding, defBgColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { mkAchievementTitle, mkTaskEmblem, taskHeader, taskDescription, taskDescPadding,
  statusBlock, taskMinHeight, taskSlotPadding, mkGetTaskRewardBtn
} = require("%enlSqGlob/ui/taskPkg.nut")
let { mkTaskRewards } = require("mkUnlockSlot.nut")
let scrollbar = require("%ui/components/scrollbar.nut")
let { seenUnlocks, markUnlocksOpened } = require("%enlist/unlocks/unseenUnlocksState.nut")


let mkTaskContent = @(task)
  function() {
    let progress = getUnlockProgress(task)
    return {
      watch = [unlockProgress]
      size = [flex(), SIZE_TO_CONTENT]
      valign = ALIGN_CENTER
      children = {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = hdpx(10)
        valign = ALIGN_CENTER
        children = [
          mkTaskEmblem(task, progress)
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            gap = taskDescPadding
            children = [
              taskHeader(task, progress)
              taskDescription(task.localization.description)
            ]
          }
        ]
      }
    }
  }

let finishedOpacity = 0.5
let finishedBgColor = mul_color(defBgColor, 1.0 / finishedOpacity)
let mkAchievementSlot = @(task) {
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      minHeight = taskMinHeight
      rendObj = ROBJ_SOLID
      xmbNode = XmbNode()
      behavior = Behaviors.Button
      color = task.isFinished ? finishedBgColor : defBgColor
      opacity = task.isFinished ? finishedOpacity : 1.0
      flow = FLOW_HORIZONTAL
      padding = taskSlotPadding
      gap = smallPadding
      valign = ALIGN_CENTER
      children = [
        mkTaskContent(task)
        task.hasReward
          ? mkGetTaskRewardBtn(task, receiveTaskRewards, unlockRewardsInProgress)
          : null
        mkTaskRewards(task, true)
      ]
    }
    statusBlock(task)
  ]
}

let WINDOW_CONTENT_SIZE = [fsh(100), flex()]
let achievementsBlockUI = {
  key = "achievementsBlock"
  size = WINDOW_CONTENT_SIZE
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  padding = [fsh(2),0,0,0]
  onDetach = @() markUnlocksOpened((seenUnlocks.value?.unopenedAchievements ?? {}).keys())
  children = scrollbar.makeVertScroll(function() {
    let achieveByTypes = achievementsByTypes.value
    let { achievements = [], challenges = [] } = achieveByTypes
    return {
      rendObj = ROBJ_WORLD_BLUR_PANEL
      watch = achievementsByTypes
      size = [flex(), SIZE_TO_CONTENT]
      minHeight = ph(100)
      xmbNode = XmbContainer({
        canFocus = @() false
        scrollSpeed = 5
        isViewport = true
      })
      flow = FLOW_VERTICAL
      gap = smallPadding
      margin = [0,0,0,hdpxi(18)]
      halign = ALIGN_CENTER
      children = [mkAchievementTitle(achievements, "achievementsTitle")]
        .extend(achievements.map(@(achievement) mkAchievementSlot(achievement)))
        .append({ size = [0, bigPadding] })
        .append(mkAchievementTitle(challenges, "challengesTitle"))
        .extend(challenges.map(@(challenge) mkAchievementSlot(challenge)))
    }
  },
  {
    needReservePlace = false
  })
}

return achievementsBlockUI