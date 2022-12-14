from "%enlSqGlob/ui_library.nut" import *

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor, titleTxtColor, smallPadding, midPadding, bigPadding, accentColor, colPart,
  defHorGradientImg
} = require("%enlSqGlob/ui/designConst.nut")
let { getDescription } = require("unlocksText.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkCountdownTimerPerSec } = require("%ui/helpers/timers.nut")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let faComp = require("%ui/components/faComp.nut")
let mkSpinner = require("%ui/components/mkSpinner.nut")(colPart(0.4))
let { getStageByIndex } = require("%enlSqGlob/unlocks_utils.nut")
let { progressBar } = require("%enlSqGlob/ui/defComponents.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let hoveredTxtStyle = { color = titleTxtColor }.__update(fontSmall)
let titleTxtStyle = { color = titleTxtColor }.__update(fontSmall)
let taskProgressTxtStyle = { color = accentColor }.__update(fontSmall)


let starSize = colPart(0.35)
let rerollIconSize = colPart(0.3)
let taskMinHeight = colPart(0.91)
let statusWidth = colPart(0.4)
let taskSlotPadding = [smallPadding, 0, smallPadding, bigPadding]
let taskDescPadding = [midPadding, smallPadding, bigPadding,
  colPart(0.39) + statusWidth + midPadding * 2]


let blinkAnimation = {
  animations = [{
    prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1, play = true,
    loop = true, easing = Blink
  }]
}

let rewardAnimBg = {
  rendObj = ROBJ_IMAGE
  size = [pw(100), pw(100)]
  image = Picture("ui/skin#tasks/completed_task_sign.png")
  transform = { scale = [3, 3] }
}.__update(blinkAnimation)


let taskLabelSize = [colPart(0.14), colPart(0.3)]
let mkTaskLabel = @(labelName) {
  size = taskLabelSize
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/skin#tasks/{labelName}.svg:{taskLabelSize[0]}:{taskLabelSize[1]}:K")
  vplace = ALIGN_TOP
}


let isDailyTask = @(task) task.table == "daily"
let isWeeklyTask = @(task) task?.meta.weekly_unlock ?? false
let isAchievementTask = @(task) task?.meta.achievement ?? false
let isEventTask = @(task) task?.meta.event_unlock ?? false
let getUnlockLimit = @(task) task?.meta.unlock_limit ?? 0
let getProgressDiv = @(task) task?.meta.descProgressDiv.tointeger() ?? 0


let mkFaIcon = @(name, color = 0xFFFFFF, fontSize = fontSmall.fontSize)
  faComp(name, {fontSize, color})
let completedUnlockIcon = mkFaIcon("check", titleTxtColor)
let canceledUnlockIcon = mkFaIcon("times", titleTxtColor)
let rerollUnlockIcon = {
  rendObj = ROBJ_IMAGE
  size = [rerollIconSize, rerollIconSize]
  image = Picture("ui/skin#tasks/rerool_icon.svg:{0}:{0}:K".subst(rerollIconSize))
}

let mkTaskTextArea = @(text, sf, style = {}) {
  size = [pw(75), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  key = text
}.__update(sf & S_HOVER ? hoveredTxtStyle : defTxtStyle, style)


let statusBlock = @(unlockDesc, hasWaitIcon = Watched(false), canReroll = false)
  function() {
    local statusObj
    if (hasWaitIcon.value)
      statusObj = mkSpinner
    else if (!isEventTask(unlockDesc)) {
      let { isCompleted = false, isFinished = false, isCanceled = false } = unlockDesc
      let hasCompletedMark = isFinished || isCompleted
      statusObj = isCanceled ? canceledUnlockIcon
        : hasCompletedMark ? completedUnlockIcon
        : canReroll ? rerollUnlockIcon
        : null
    }

    let res = { watch = hasWaitIcon }
    return statusObj == null ? res
      : res.__update({
          pos = [-statusWidth / 2, 0]
          size = [statusWidth, statusWidth]
          vplace = ALIGN_CENTER
          children = [
            {
              rendObj = ROBJ_MASK
              size = [statusWidth / 2, statusWidth]
              image = Picture("ui/uiskin/tasks/task_status_mask.png")
              children = [
                {
                  rendObj = ROBJ_IMAGE
                  size = flex()
                  image = defHorGradientImg
                }
              ]
            }
            {
              size = flex()
              valign = ALIGN_CENTER
              halign = ALIGN_CENTER
              children = statusObj
            }
          ]
          animations = [{
            prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true
          }]
        })
  }



let taskHeader = @(unlockDesc, progress, canTakeReward = true, sf = 0, textStyle = {})
  function() {
    let { isCompleted, isFinished, hasReward = false } = progress
    let { lastRewardedStage = 0, stages = [] } = unlockDesc
    if (isDailyTask(unlockDesc) && isCompleted) {
      let locId = isCompleted && !canTakeReward ? "finishedTaskText" : "completeTaskText"
      return mkTaskTextArea(utf8ToUpper(loc(locId)), sf,
      { animations = hasReward && canTakeReward ? blinkAnimation : {}}.__update(
        hasReward && canTakeReward ? titleTxtStyle : defTxtStyle))
    }

    local { required, current } = progress
    let descProgressDiv = getProgressDiv(unlockDesc)
    if (descProgressDiv > 0 && required != null && current != null) {
      current = current / descProgressDiv
      required = required / descProgressDiv
    }

    let unlockWatch = mkCountdownTimerPerSec(Watched(unlockDesc?.completeAt ?? 0))
    local unlockTxt = getDescription(unlockDesc, progress, (unlockDesc?.locParams ?? {}).__merge({
      duration = secondsToStringLoc(unlockWatch.value)
    }))

    let addTexts = []
    if (stages.len() > 1) {
      let curStage = min(lastRewardedStage + 1, stages.len())
      addTexts.append($"{loc("stageText")} {curStage}/{stages.len()}")
    }

    let unlockLimit = getUnlockLimit(unlockDesc)
    local { stage = 0 } = progress
    if (!isCompleted && !hasReward && (unlockLimit == 0 || stage < unlockLimit)) {
      let { periodic = false } = unlockDesc
      local curStageCurrent, curStageRequired
      if (periodic) {
        let loopIndex = unlockDesc.startStageLoop - 1
        if (stage > loopIndex)
          stage = loopIndex + (stage - loopIndex) % (stages.len() - loopIndex)
        let interval = stages[stage].progress
        curStageCurrent = current + interval - required
        curStageRequired = interval
      } else {
        let passedProgress = stages?[lastRewardedStage - 1].progress ?? 0
        curStageCurrent = current - passedProgress
        curStageRequired = required - passedProgress
      }
      if (curStageRequired > 1)
        addTexts.append($"{loc("progressText")} {curStageCurrent}/{curStageRequired}")
    }

    if (addTexts.len() > 0)
      unlockTxt = "{0} ({1})".subst(unlockTxt, ", ".join(addTexts))

    return mkTaskTextArea(unlockTxt, sf)
      .__update({ watch = unlockWatch }, isEventTask(unlockDesc) && isFinished ? titleTxtStyle
        : sf & S_HOVER ? hoveredTxtStyle
        : defTxtStyle, textStyle)
  }


let taskDescription = @(description, sf = 0, style = {})
(description ?? "") == "" ? null
  : mkTaskTextArea(description, sf, style)


let mkEmblemImg = @(img, iSize, hasAnim = false) {
  size = [iSize, iSize]
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = [iSize, iSize]
      image = Picture("ui/skin#tasks/{0}.svg:{1}:{1}:K".subst(img, iSize))
    }
    hasAnim ? rewardAnimBg : null
  ]
}


let function mkEmblemQty(unlockDesc) {
  let { lastRewardedStage = 0, isFinished = false } = unlockDesc
  let stage = isFinished
    ? getStageByIndex(unlockDesc, lastRewardedStage - 1)
    : getStageByIndex(unlockDesc, lastRewardedStage)
  let count = (stage?.updStats[0].value ?? 1).tointeger()
  return count <= 1 ? null
    : {
        rendObj = ROBJ_TEXT
        text = count
        hplace = ALIGN_RIGHT
        pos = [midPadding, -smallPadding]
      }.__update(taskProgressTxtStyle)
}


let function getTaskEmblemImg(unlockDesc, isCompleted) {
  let img = isDailyTask(unlockDesc) ? "star"
    : isWeeklyTask(unlockDesc) ? "star"
    : isAchievementTask(unlockDesc) ? "medal"
    : isEventTask(unlockDesc) ? "medal"
    : ""
  return img == "" ? "" : "{0}_{1}".subst(img, isCompleted ? "filled" : "empty")
}


let function mkTaskEmblem(unlockDesc, progress, canTakeReward = true) {
  let { lastRewardedStage = 0, stages = [] } = unlockDesc
  let { hasReward=false, current, required } = progress
  let emblemImg = getTaskEmblemImg(unlockDesc, current >= required)
  let passedProgress = lastRewardedStage <= 0 ? 0
    : stages?[lastRewardedStage - 1].progress ?? 0
  let curStageCurrent = current - passedProgress
  let curStageRequired = required - passedProgress
  return emblemImg == "" ? null
    : {
        size = [starSize + smallPadding, SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = midPadding
        halign = ALIGN_CENTER
        opacity = unlockDesc.isFinished ? 0.3 : 1
        children = [
          {
            children = [
              mkEmblemImg(emblemImg, starSize, unlockDesc.hasReward && canTakeReward)
              mkEmblemQty(unlockDesc)
            ]
          }
          progressBar(hasReward ? 1
            : curStageRequired > 0 ? curStageCurrent.tofloat() / curStageRequired
            : 0, {
              size = [flex(), colPart(0.07)]
              bgColor = 0x55555555
            }
          )
        ]
      }
}

return {
  mkTaskLabel
  rewardAnimBg
  taskLabelSize
  taskHeader
  statusBlock
  taskDescription
  taskDescPadding
  taskMinHeight
  taskSlotPadding
  mkTaskEmblem
}
