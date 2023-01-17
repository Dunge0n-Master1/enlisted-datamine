from "%enlSqGlob/ui_library.nut" import *

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { smallPadding, titleTxtColor, colPart, defHorGradientImg, hoverHorGradientImg
} = require("%enlSqGlob/ui/designConst.nut")
let { statusBlock, taskDescription, taskHeader, taskDescPadding,
  taskMinHeight, taskSlotPadding, mkTaskEmblem
} = require("%enlSqGlob/ui/tasksPkg.nut")
let { getOneReward, mkRewardIcon, prepareRewards } = require("%enlist/battlepass/rewardsPkg.nut")
let { getUnlockProgress, unlockProgress } = require("%enlSqGlob/userstats/unlocksState.nut")
let { rewardIconWidth } = require("%enlist/battlepass/rewardPkg.nut")
let { soundDefault } = require("%ui/components/textButton.nut")


let titleTxtStyle = { color = titleTxtColor }.__update(fontSmall)
let btnOffset = colPart(0.36)
let mkHideTrigger = @(task) $"hide_task_{task.name}"


let mkTaskContent = @(unlockDesc, canTakeReward, sf = 0)
  function() {
    let progress = getUnlockProgress(unlockDesc)
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
          mkTaskEmblem(unlockDesc, progress, canTakeReward)
          taskHeader(unlockDesc, progress, canTakeReward, sf)
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
          }.__update(titleTxtStyle)
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
    size = [flex(), SIZE_TO_CONTENT]
    minHeight = taskMinHeight
    behavior = onClick == null ? null : Behaviors.Button
    sound = soundDefault
    onClick
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = flex()
        margin = bottomBtn != null ? [0,0, btnOffset,0] : 0
        image = defHorGradientImg
      }
      sf & S_HOVER
        ? {
            rendObj = ROBJ_IMAGE
            size = flex()
            margin = bottomBtn != null ? [0,0, btnOffset,0] : 0
            image = hoverHorGradientImg
            animations = [{
              prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true
            }]
          }
        : null
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
              mkTaskContent(task, canTakeReward, sf)
              mkTaskRewards(task, isAllRewardsVisible, rewardsAnim)
              rightObject
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
      sf & S_HOVER
        ? statusBlock(task, hasWaitIcon, rerolls > 0)
        : null
    ]
    transform = {}
    animations = (hasShowAnim && needShowAnim(task)
      ? [{ prop = AnimProp.translate, from = [colPart(4),0], to = [0,0],
          duration = 0.25, play = true }]
      : []).append(
            { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.35,
              trigger = mkHideTrigger(task) },
            { prop = AnimProp.opacity, from = 0, to = 0, duration = 3,
              delay = 0.3, trigger = mkHideTrigger(task) })
  })
)

return {
  mkUnlockSlot
  mkTaskRewards
  mkHideTrigger
}