from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt, tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(40) })
let { utf8ToUpper } = require("%sqstd/string.nut")
let { PrimaryFlat } = require("%ui/components/textButton.nut")
let { progressBar } = require("%enlSqGlob/ui/defcomps.nut")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let { mkCountdownTimerPerSec } = require("%ui/helpers/timers.nut")
let { getDescription } = require("unlocksText.nut")
let {
  bigPadding, activeTxtColor, titleTxtColor, defBgColor, taskProgressColor,
  taskDefColor, defTxtColor, smallPadding, commonBtnHeight
} = require("%enlSqGlob/ui/viewConst.nut")
let { getStageByIndex } = require("%enlSqGlob/unlocks_utils.nut")
let { BP_INTERVAL_STARS } = require("%enlSqGlob/bpConst.nut")


let EMBLEM_SIZE = hdpxi(24)

let taskMinHeight = hdpx(56)
let statusWidth = hdpxi(36)

let taskSlotPadding = [hdpx(5), hdpx(5), hdpx(5), hdpx(24)]
let taskDescPadding = [hdpx(8), hdpx(5), hdpx(16), hdpx(24) + statusWidth + bigPadding * 2]

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

let mkTaskTextArea = @(txt, sf, style = {}) {
  rendObj = ROBJ_TEXTAREA
  size = [pw(75), SIZE_TO_CONTENT]
  behavior = Behaviors.TextArea
  color = sf & S_HOVER ? titleTxtColor : defTxtColor
  text = txt
  key = txt
}.__update(sub_txt, style)

let mkFaIcon = @(name, color = Color(255,255,255), fontSize = hdpx(16)) faComp(name, {fontSize, color})

let completedUnlockIcon = mkFaIcon("check", activeTxtColor)
let canceledUnlockIcon = mkFaIcon("times", activeTxtColor)

let rerollUnlockIcon = {
  rendObj = ROBJ_IMAGE
  size = [EMBLEM_SIZE, EMBLEM_SIZE]
  image = Picture("ui/skin#tasks/rerool_icon.svg:{0}:{0}:K".subst(EMBLEM_SIZE))
}

let taskLabelSize = [hdpxi(13), hdpxi(26)]
let function mkTaskLabel(labelName = null) {
  let res = {
    size = taskLabelSize
    vplace = ALIGN_TOP
  }
  return labelName == null ? res
    : res.__update({
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/skin#tasks/{labelName}.svg:{taskLabelSize[0]}:{taskLabelSize[1]}:K")
      })
}

let isDailyTask = @(task) task.table == "daily"
let isWeeklyTask = @(task) task?.meta.weekly_unlock ?? false
let isAchievementTask = @(task) task?.meta.achievement ?? false
let isEventTask = @(task) task?.meta.event_unlock ?? false
let getUnlockLimit = @(task) task?.meta.unlock_limit ?? 0
let getProgressDiv = @(task) task?.meta.descProgressDiv.tointeger() ?? 0

let statusBlock = @(unlockDesc, hasWaitIcon = Watched(false), canReroll = false)
  function() {
    local statusObj = hasWaitIcon.value ? spinner : null
    if (!isEventTask(unlockDesc)) {
      let { isCompleted = false, isFinished = false, isCanceled = false } = unlockDesc
      let hasCompletedMark = isFinished || isCompleted
      statusObj = hasWaitIcon.value ? spinner
        : isCanceled ? canceledUnlockIcon
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
                  rendObj = ROBJ_WORLD_BLUR_PANEL
                  size = flex()
                }
                {
                  rendObj = ROBJ_SOLID
                  size = flex()
                  color = defBgColor
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
      return mkTaskTextArea(utf8ToUpper(loc(locId)), sf, {
        color = hasReward && canTakeReward ? titleTxtColor
          : hasReward && !canTakeReward ? defTxtColor
          : sf & S_HOVER ? titleTxtColor
          : defTxtColor
      }.__update(hasReward && canTakeReward ? blinkAnimation : {}))
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
      .__update({
        watch = unlockWatch
        color = isEventTask(unlockDesc) && isFinished ? defTxtColor
          : sf & S_HOVER ? titleTxtColor
          : defTxtColor
      }, textStyle)
  }

let taskDescription = @(description, sf = 0, style = {})
  (description ?? "") == "" ? null
    : mkTaskTextArea(description, sf, style)

let function getTaskEmblemImg(unlockDesc, isCompleted) {
  let img = isDailyTask(unlockDesc) ? "star"
    : isWeeklyTask(unlockDesc) ? "star"
    : isAchievementTask(unlockDesc) ? "medal"
    : isEventTask(unlockDesc) ? "medal"
    : ""
  return img == "" ? "" : "{0}_{1}".subst(img, isCompleted ? "filled" : "empty")
}

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
        pos = [bigPadding, -smallPadding]
        color = taskProgressColor
      }.__update(tiny_txt)
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
        size = [EMBLEM_SIZE + bigPadding * 2, SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = hdpx(2)
        halign = ALIGN_CENTER
        opacity = unlockDesc.isFinished ? 0.3 : 1
        children = [
          {
            children = [
              mkEmblemImg(emblemImg, EMBLEM_SIZE, unlockDesc.hasReward && canTakeReward)
              mkEmblemQty(unlockDesc)
            ]
          }
          progressBar({
            value = hasReward ? 1
              : curStageRequired > 0 ? curStageCurrent.tofloat() / curStageRequired
              : 0
            color = taskProgressColor
            bgColor = taskDefColor
            customStyle = { borderWidth = 0 }
          })
        ]
      }
}

let taskHoverBlock = {
  rendObj = ROBJ_SOLID
  size = flex()
  color = defBgColor
  animations = [{
    prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true
  }]
}

let function mkAchievementTitle(tasksList, locId) {
  let finished = tasksList.reduce(@(s, u) u.isCompleted ? s + 1 : s, 0)
  return {
    rendObj = ROBJ_TEXT
    text = "{0} {1}".subst(loc(locId), $"{finished}/{tasksList.len()}")
    color = activeTxtColor
  }.__update(body_txt)
}

let starSize = hdpxi(18)
let weeklyTasksTitle = @(sf) {
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  padding = taskSlotPadding
  margin = [bigPadding, 0]
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("profile/weeklyTasks")
      color = sf & S_HOVER ? titleTxtColor : defTxtColor
    }.__update(body_txt)
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        {
          rendObj = ROBJ_TEXT
          text = BP_INTERVAL_STARS
          color = taskProgressColor
        }.__update(body_txt)
        {
          rendObj = ROBJ_IMAGE
          size = [starSize, starSize]
          image = Picture("ui/skin#tasks/star_filled.svg:{0}:{0}:K".subst(starSize))
        }
      ]
    }
  ]
}

let btnSize = [hdpx(230), commonBtnHeight]
let mkGetTaskRewardBtn = @(task, cb, inProgressWatch) @() {
  watch = inProgressWatch
  size = [SIZE_TO_CONTENT, btnSize[1]]
  minWidth = btnSize[0]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = inProgressWatch.value?[task.name] ?? false
    ? spinner
    : PrimaryFlat(loc("bp/getNextReward"), @() cb(task), {
        key = "btnReceiveReward"
        size = [SIZE_TO_CONTENT, btnSize[1]]
        minWidth = btnSize[0]
        margin = 0
      })
}

return {
  taskMinHeight
  mkTaskEmblem
  taskHeader
  statusBlock
  taskDescription
  mkAchievementTitle
  weeklyTasksTitle
  mkTaskLabel
  mkGetTaskRewardBtn

  rewardAnimBg
  taskHoverBlock
  taskSlotPadding
  taskDescPadding
}
