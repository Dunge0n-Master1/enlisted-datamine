from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { PrimaryFlat } = require("%ui/components/textButton.nut")
let { commonBtnHeight, taskProgressColor, activeTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { defTxtColor, titleTxtColor, smallPadding, midPadding, bigPadding, accentColor, colPart,
  darkTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let { getDescription } = require("unlocksText.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkCountdownTimerPerSec } = require("%ui/helpers/timers.nut")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let faComp = require("%ui/components/faComp.nut")
let spinner = require("%ui/components/spinner.nut")
let { getStageByIndex } = require("%enlSqGlob/unlocks_utils.nut")
let { progressBar } = require("%enlSqGlob/ui/defComponents.nut")

let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let hoveredTxtStyle = { color = darkTxtColor }.__update(fontSmall)
let titleTxtStyle = { color = titleTxtColor }.__update(fontSmall)
let taskProgressTxtStyle = { color = accentColor }.__update(fontSmall)


let waitingSpinner = spinner(colPart(0.4))
let starSize = colPart(0.35)
let taskMinHeight = colPart(0.91)
let statusWidth = colPart(0.4)
let taskSlotPadding = [smallPadding, bigPadding, smallPadding, bigPadding]
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
  image = Picture("ui/skin#tasks/completed_task_sign.avif")
  transform = { scale = [3, 3] }
}.__update(blinkAnimation)


let taskLabelSize = [colPart(0.14), colPart(0.3)]
let mkTaskLabel = @(labelName) labelName == null ? null : {
  size = taskLabelSize
  rendObj = ROBJ_IMAGE
  hplace = ALIGN_RIGHT
  image = Picture($"ui/skin#tasks/{labelName}.svg:{taskLabelSize[0]}:{taskLabelSize[1]}:K")
  vplace = ALIGN_TOP
}


let isDailyTask = @(task) task.table == "daily"
let isRankUnlock = @(task) (task?.meta.rank_unlock ?? 0) > 0
  && (task?.stages[0].updStats[0].value ?? 0) == 0
let isWeeklyTask = @(task) task?.meta.weekly_unlock ?? false
let isAchievementTask = @(task) task?.meta.achievement ?? false
let isEventTask = @(task) task?.meta.event_unlock ?? (task?.meta.event_group != null) // backward compatibility
let getUnlockLimit = @(task) task?.meta.unlock_limit ?? 0
let getProgressDiv = @(task) task?.meta.descProgressDiv.tointeger() ?? 0


let mkFaIcon = @(name, color = 0xFFFFFF, fontSize = fontSmall.fontSize)
  faComp(name, {fontSize, color})
let completedUnlockIcon = mkFaIcon("check", taskProgressColor)
let canceledUnlockIcon = mkFaIcon("times", darkTxtColor)
let rerollUnlockIcon = {
  rendObj = ROBJ_IMAGE
  size = [starSize, starSize]
  image = Picture("ui/skin#tasks/rerool_icon.svg:{0}:{0}:K".subst(starSize))
  color = darkTxtColor
}

let mkTaskTextArea = @(text, sf, style = {}) {
  size = [pw(75), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  key = text
}.__update(sf & S_HOVER ? hoveredTxtStyle : defTxtStyle, style)

let statusIcon = @(unlockDesc, hasWaitIcon = Watched(false), canReroll = false)
  function() {
    local statusObj
    if (hasWaitIcon.value)
      statusObj = waitingSpinner
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
          children = statusObj
        })
  }


let function statusBlock(unlockDesc) {
  let { isCompleted = false, isFinished = false, isCanceled = false } = unlockDesc
  let statusObj = isCanceled ? canceledUnlockIcon
    : isFinished || isCompleted ? completedUnlockIcon
    : null

  return {
    pos = [-statusWidth, 0]
    size = [statusWidth, statusWidth]
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = statusObj
    animations = [{
      prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true
    }]
  }
}


let taskHeader = @(unlockDesc, progress, canTakeReward = true, sf = 0, textStyle = {})
  function() {
    let { isCompleted, isFinished, hasReward = false } = progress
    let { lastRewardedStage = 0, stages = [] } = unlockDesc
    if (isDailyTask(unlockDesc) && isCompleted) {
      let locId = isCompleted && !canTakeReward ? "finishedTaskText" : "completeTaskText"
      return mkTaskTextArea(utf8ToUpper(loc(locId)), sf,
      { animations = hasReward && canTakeReward ? blinkAnimation.animations : []}.__update(
        sf & S_HOVER ? hoveredTxtStyle : hasReward && canTakeReward ? titleTxtStyle : defTxtStyle))
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


let btnSize = [hdpx(230), commonBtnHeight]
let mkGetTaskRewardBtn = @(task, cb, inProgressWatch) @() {
  watch = inProgressWatch
  size = [SIZE_TO_CONTENT, btnSize[1]]
  minWidth = btnSize[0]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = inProgressWatch.value?[task.name] ?? false
    ? waitingSpinner
    : PrimaryFlat(loc("bp/getNextReward"), @() cb(task), {
        key = "btnReceiveReward"
        size = [SIZE_TO_CONTENT, btnSize[1]]
        minWidth = btnSize[0]
        margin = 0
      })
}


let mkEmblemImg = @(img, iSize, hasAnim = false, sf = 0, seasonIndex=null, bpColors=null) function() {
  let colorIdx = (seasonIndex != null && bpColors!=null) ? (seasonIndex.value % bpColors.len()) : null
  return {
    watch = seasonIndex
    size = [iSize, iSize]
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [iSize, iSize]
        color = sf & S_HOVER ? darkTxtColor : bpColors?[colorIdx]
        image = Picture("{0}.svg:{1}:{1}:K".subst(img, iSize))
      }
      hasAnim ? rewardAnimBg : null
    ]
  }
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
  if (isRankUnlock(unlockDesc))
    return isCompleted
      ?  "ui/skin#tasks/goblet_filled"
      :  "ui/skin#tasks/goblet_empty"
  if (isDailyTask(unlockDesc) || isWeeklyTask(unlockDesc))
    return isCompleted
      ? "ui/skin#star_level_filled"
      : "ui/skin#star_level_empty"
  if (isAchievementTask(unlockDesc) || isEventTask(unlockDesc))
    return isCompleted
      ? "ui/skin#tasks/medal_filled"
      : "ui/skin#tasks/medal_empty"
  return ""
}

let function mkTaskEmblem(unlockDesc, progress, canTakeReward = true, hasWaitIcon = Watched(false),
  canReroll = false, sf = 0, seasonIndex=null, bpColors=null) {

  let { lastRewardedStage = 0, stages = [], periodic = false } = unlockDesc
  let { hasReward = false, current, required } = progress
  let emblemImg = getTaskEmblemImg(unlockDesc, current >= required)
  let passedProgress = lastRewardedStage <= 0 ? 0
    : stages?[lastRewardedStage - 1].progress ?? 0
  let curStageCurrent = current - passedProgress
  let curStageRequired = required - passedProgress
  let progBarValue = hasReward ? 1
    : !periodic && curStageRequired > 0 ? curStageCurrent.tofloat() / curStageRequired
    : 0
  let sIcon = statusIcon(unlockDesc, hasWaitIcon, canReroll)

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
              sf & S_HOVER ? sIcon
                : mkEmblemImg(emblemImg, starSize, unlockDesc.hasReward && canTakeReward, sf, seasonIndex, bpColors)
              mkEmblemQty(unlockDesc)
            ]
          }
          function() {
            let colorIdx = seasonIndex!=null && bpColors!=null ? (seasonIndex.value % bpColors.len()) : null
            let progressColor = bpColors?[colorIdx] ?? taskProgressColor
            return {
              size = flex()
              watch = seasonIndex
              children = progressBar(progBarValue, {
                size = [flex(), colPart(0.07)]
                progressColor
              }
            )
            }
          }
        ]
      }
}

let function mkAchievementTitle(tasksList, locId) {
  let finished = tasksList.reduce(@(s, u) u.isCompleted ? s + 1 : s, 0)
  return {
    rendObj = ROBJ_TEXT
    text = "{0} {1}".subst(loc(locId), $"{finished}/{tasksList.len()}")
    color = activeTxtColor
  }.__update(body_txt)
}

return {
  mkTaskLabel
  rewardAnimBg
  taskLabelSize
  taskHeader
  taskDescription
  taskDescPadding
  taskMinHeight
  taskSlotPadding
  mkTaskEmblem
  mkAchievementTitle
  statusBlock
  mkGetTaskRewardBtn
}
