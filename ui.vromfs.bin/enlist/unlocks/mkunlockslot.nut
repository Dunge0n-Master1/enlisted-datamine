from "%enlSqGlob/ui_library.nut" import *

let {
  smallPadding, defBgColor, titleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let {
  statusBlock, taskDescription, taskHeader, taskDescPadding,
  taskMinHeight, taskSlotPadding, mkTaskEmblem
} = require("%enlSqGlob/ui/taskPkg.nut")
let {
  getOneReward, mkRewardIcon, prepareRewards
} = require("%enlist/battlepass/rewardsPkg.nut")
let {
  getUnlockProgress, unlockProgress
} = require("%enlSqGlob/userstats/unlocksState.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { soundDefault } = require("%ui/components/textButton.nut")



let taskRewardSize = taskMinHeight - 2 * taskSlotPadding[0]

let mkTaskContent = @(unlockDesc, canTakeReward, sf = 0)
  function() {
    let progress = getUnlockProgress(unlockDesc)
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
      mkRewardIcon(reward, taskRewardSize, isFinished ? { opacity = 0.5 } : {})
      count == 1 ? null
        : txt({
            text = $"x{count}"
            margin = [0, smallPadding]
            hplace = ALIGN_RIGHT
            vplace = ALIGN_BOTTOM
            color = titleTxtColor
            fontFx = FFT_GLOW
            fontFxColor = 0xCC000000
            fontFxFactor = hdpx(32)
          }).__update(sub_txt)
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

let BTN_OFFSET = hdpx(22)
let mkHideTrigger = @(task) $"hide_task_{task.name}"

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
  customDescription = null, bgColor = null, canTakeReward = true,
  rewardsAnim = null
)
  watchElemState(@(sf) {
    key = task.name
    size = [flex(), SIZE_TO_CONTENT]
    minHeight = taskMinHeight
    behavior = onClick == null ? null : Behaviors.Button
    sound = soundDefault
    onClick
    children = [
      bgColor != null
        ? {
            rendObj = ROBJ_SOLID
            size = flex()
            margin = bottomBtn != null ? [0,0,BTN_OFFSET,0] : 0
            color = bgColor
          }
        : null
      sf & S_HOVER
        ? {
            rendObj = ROBJ_SOLID
            size = flex()
            margin = bottomBtn != null ? [0,0,BTN_OFFSET,0] : 0
            color = defBgColor
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
                margin = [0, BTN_OFFSET]
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
      ? [{ prop = AnimProp.translate, from = [hdpx(250),0], to = [0,0],
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