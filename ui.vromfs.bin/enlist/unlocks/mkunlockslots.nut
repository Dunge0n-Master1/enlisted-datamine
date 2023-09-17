from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { smallPadding, titleTxtColor, defTxtColor, defItemBlur, transpPanelBgColor, darkTxtColor,
  hoverSlotBgColor, midPadding
} = require("%enlSqGlob/ui/designConst.nut")
let { taskDescription, taskHeader, taskDescPadding, taskMinHeight,
  taskSlotPadding, mkTaskEmblem, completedUnlockIcon,
  getTaskEmblemImg, mkEmblemImgReward, mkTaskTextArea
} = require("%enlSqGlob/ui/tasksPkg.nut")
let { bpColors } = require("%enlist/battlepass/battlePassPkg.nut")
let { seasonIndex } = require("%enlist/battlepass/bpState.nut")

let { getOneReward, mkRewardIcon, prepareRewards } = require("%enlist/battlepass/rewardsPkg.nut")
let { getUnlockProgress, unlockProgress } = require("%enlSqGlob/userstats/unlocksState.nut")
let { rewardIconWidth } = require("%enlist/battlepass/rewardPkg.nut")
let { soundDefault } = require("%ui/components/textButton.nut")
let { sound_play } = require("%dngscripts/sound_system.nut")
let { receiveTaskRewards } = require("taskListState.nut")
let { getDescription } = require("%enlSqGlob/ui/unlocksText.nut")

let btnOffset = hdpx(22)
let starSizeReward = hdpxi(17)
let minHeight = hdpx(65)
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
        gap = hdpx(10)
        valign = ALIGN_CENTER
        children = [
          mkTaskEmblem(unlockDesc, progress, canTakeReward, hasWaitIcon, canReroll, sf, seasonIndex, bpColors)
          taskHeader(unlockDesc, progress, canTakeReward, sf,
            { size = [flex(), SIZE_TO_CONTENT] color = sf & S_HOVER ? darkTxtColor : defTxtColor}.__update(fontSub))
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
            fontFxFactor = hdpx(32)
            color = titleTxtColor
          }.__update(fontSub)
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
  task, onClick = null, onHover = null, hasWaitIcon = Watched(false), rerolls = 0,
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
    onHover
    margin = bottomBtn != null ? [0,0, btnOffset,0] : 0
    transform = {}
    animations = (hasShowAnim && needShowAnim(task)
      ? [{ prop = AnimProp.translate, from = [hdpx(248), 0], to = [0,0],
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

let mkTaskContentReward = @(unlockDesc, sf = 0)
  function() {
    let progress = getUnlockProgress(unlockDesc, unlockProgress.value)
    let colorIdx = (seasonIndex != null && bpColors!=null) ? (seasonIndex.value % bpColors.len()) : null
    let bpColor = bpColors?[colorIdx]
    let emblemImg = getTaskEmblemImg(unlockDesc, true)
    let iconReward = sf & S_HOVER ? completedUnlockIcon
      : mkEmblemImgReward(emblemImg, starSizeReward, bpColor)

    return {
      watch = [unlockProgress, seasonIndex]
      size = [flex(), SIZE_TO_CONTENT]
      clipChildren = true
      minHeight
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          children = [
            {
              size = [flex(), SIZE_TO_CONTENT]
              flow = FLOW_VERTICAL
              gap = smallPadding
              children = [
                {
                  size = [flex(), SIZE_TO_CONTENT]
                  flow = FLOW_HORIZONTAL
                  gap = smallPadding
                  valign = ALIGN_CENTER
                  children = [
                    {
                      rendObj = ROBJ_TEXT
                      halign = ALIGN_CENTER
                      color = sf & S_HOVER ? darkTxtColor : titleTxtColor
                      text = loc("completeTaskTitle")
                    }.__update(fontSub)
                    iconReward
                  ]
                }
                mkTaskTextArea(getDescription(unlockDesc, progress, unlockDesc?.locParams ?? {}), sf, {size = [pw(100), SIZE_TO_CONTENT]})
              ]
            }
            mkTaskRewards(unlockDesc)
          ]
        }
        {
          rendObj = ROBJ_TEXT
          size = [flex(), SIZE_TO_CONTENT]
          halign = ALIGN_RIGHT
          color = bpColor
          text = loc("completeTaskReward")
        }.__update(fontSub)
      ]
    }
  }


let mkUnlockSlotReward = @(task)
  watchElemState(@(sf) {
    key = task.name
    rendObj = ROBJ_SOLID
    size = [flex(), SIZE_TO_CONTENT]
    color = sf & S_HOVER ? hoverSlotBgColor : transpPanelBgColor
    padding = midPadding
    flow = FLOW_HORIZONTAL
    behavior = Behaviors.Button
    sound = soundDefault
    onClick = function() {
      sound_play("ui/reward_receive")
      receiveTaskRewards(task)
    }
    children = mkTaskContentReward(task, sf)
  })

return {
  mkUnlockSlot
  mkUnlockSlotReward
  mkTaskRewards
  mkHideTrigger
}