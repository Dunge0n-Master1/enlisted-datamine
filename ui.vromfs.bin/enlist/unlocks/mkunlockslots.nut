from "%enlSqGlob/ui_library.nut" import *

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { smallPadding, titleTxtColor, colPart, defTxtColor, defItemBlur,
  transpPanelBgColor, darkTxtColor, hoverSlotBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let { taskDescription, taskHeader, taskDescPadding, taskMinHeight, taskSlotPadding, mkTaskEmblem
} = require("%enlSqGlob/ui/tasksPkg.nut")
let { bpColors } = require("%enlist/battlepass/battlePassPkg.nut")
let { seasonIndex } = require("%enlist/battlepass/bpState.nut")

let { getOneReward, mkRewardIcon, prepareRewards } = require("%enlist/battlepass/rewardsPkg.nut")
let { getUnlockProgress, unlockProgress } = require("%enlSqGlob/userstats/unlocksState.nut")
let { rewardIconWidth } = require("%enlist/battlepass/rewardPkg.nut")
let { soundDefault } = require("%ui/components/textButton.nut")


let btnOffset = colPart(0.36)
let mkHideTrigger = @(task) $"hide_task_{task.name}"


let mkTaskContent = @(unlockDesc, canTakeReward, hasWaitIcon, canReroll, sf = 0)
  function() {
    let progress = getUnlockProgress(unlockDesc, unlockProgress.value)
    return {
      watch = unlockProgress
      size = [flex(), SIZE_TO_CONTENT]
      valign = ALIGN_CENTER
      children = {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = colPart(0.17)
        valign = ALIGN_CENTER
        children = [
          mkTaskEmblem(unlockDesc, progress, canTakeReward, hasWaitIcon, canReroll, sf, seasonIndex, bpColors)
          taskHeader(unlockDesc, progress, canTakeReward, sf,
            { size = [flex(), SIZE_TO_CONTENT] color = sf & S_HOVER ? darkTxtColor : defTxtColor}.__update(fontSmall))
        ]
      }
    }
  }


let function mkRewardBlock(rewardData, isFinished = false) {
  let { reward = null, count = 1 } = rewardData
  return {
    children = [
      mkRewardIcon(reward, rewardIconWidth, isFinished ? { opacity = 0.5 } : {})
      count == 1 ? null
        : {
            rendObj = ROBJ_TEXT
            text = $"x{count}"
            margin = [0, smallPadding]
            hplace = ALIGN_RIGHT
            vplace = ALIGN_BOTTOM
            fontFx = FFT_GLOW
            fontFxColor = 0xCC000000
            fontFxFactor = colPart(0.5)
            color = titleTxtColor
          }.__update(fontSmall)
    ]
  }
}


let function mkAllRewardsIcons(stageData, isFinished) {
  let rewardsByIcon = {}
  foreach (rewardData in prepareRewards(stageData)) {
    let key = rewardData.reward?.icon ?? "noIcon"
    if (key not in rewardsByIcon)
      rewardsByIcon[key] <- clone rewardData
    else
      rewardsByIcon[key].count += rewardData.count
  }
  return rewardsByIcon.values()
    .sort(@(a, b) b.count <=> a.count)
    .map(@(r) mkRewardBlock(r, isFinished))
}


let function mkTaskRewards(unlockDesc, isAllRewardsVisible = false, rewardsAnim = null) {
  local children
  let { personalData = {} } = unlockDesc
  let { rewards = null, boosterRewards = null } = personalData
  let { items = {} } = boosterRewards
  if (rewards != null)
    children = rewards.map(@(reward) mkRewardBlock(getOneReward(reward?.items ?? {})))
  else if (items.len() > 0)
    children = mkRewardBlock(getOneReward(items))
  else {
    let {
      stage, lastRewardedStage, isFinished, hasReward, stages = []
    } = unlockDesc
    let actualStage = isFinished ? stages.len() - 1
      : hasReward ? lastRewardedStage
      : stage
    let stageData = stages?[actualStage].rewards
    if (stageData != null)
      children = isAllRewardsVisible
        ? mkAllRewardsIcons(stageData, isFinished)
        : mkRewardBlock(getOneReward(stageData), isFinished)
  }
  return children == null ? null : {
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    children
  }.__update(rewardsAnim == null ? {}
    : {
        transform = {}
        animations = rewardsAnim
      })
}


let animatedTasks = {}
let function needShowAnim(task) {
  if (task.name in animatedTasks)
    return false

  animatedTasks[task.name] <- true
  return true
}


let mkUnlockSlot = kwarg(@(
  task, onClick = null, hasWaitIcon = Watched(false), rerolls = 0,
  isAllRewardsVisible = false, rightObject = null,
  hasDescription = false, bottomBtn = null, hasShowAnim = false,
  customDescription = null, canTakeReward = true, rewardsAnim = null
)
  watchElemState(@(sf) {
    key = task.name
    rendObj = ROBJ_WORLD_BLUR
    size = [flex(), SIZE_TO_CONTENT]
    fillColor = sf & S_HOVER ? hoverSlotBgColor : transpPanelBgColor
    color = defItemBlur
    minHeight = taskMinHeight
    behavior = onClick == null ? null : Behaviors.Button
    sound = soundDefault
    onClick
    margin = bottomBtn != null ? [0,0, btnOffset,0] : 0
    transform = {}
    animations = (hasShowAnim && needShowAnim(task)
      ? [{ prop = AnimProp.translate, from = [colPart(4),0], to = [0,0],
          duration = 0.25, play = true }]
      : []).append(
            { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.35,
              trigger = mkHideTrigger(task) },
            { prop = AnimProp.opacity, from = 0, to = 0, duration = 3,
              delay = 0.3, trigger = mkHideTrigger(task) })
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            minHeight = taskMinHeight
            flow = FLOW_HORIZONTAL
            padding = taskSlotPadding
            gap = smallPadding
            valign = ALIGN_CENTER
            children = [
              mkTaskContent(task, canTakeReward, hasWaitIcon, rerolls > 0, sf)
              mkTaskRewards(task, isAllRewardsVisible, rewardsAnim)
            ]
          }
          hasDescription
            ? taskDescription(task.localization.description, sf, {
                margin = taskDescPadding
              })
            : null
          customDescription
          bottomBtn != null
            ? {
                margin = [0, btnOffset]
                hplace = ALIGN_RIGHT
                children = bottomBtn
              }
            : null
        ]
      }
      rightObject
    ]
  })
)

return {
  mkUnlockSlot
  mkTaskRewards
  mkHideTrigger
}