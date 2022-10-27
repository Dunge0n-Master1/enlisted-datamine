from "%enlSqGlob/ui_library.nut" import *

let { sound_play } = require("sound")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { bigPadding, smallPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { getDescription } = require("%enlSqGlob/ui/unlocksText.nut")
let { progressBar } = require("%enlSqGlob/ui/defcomps.nut")

const trigger = "content_anim"

let taskColor = Color(220, 220, 220)

let function debriefingTaskHeader(unlockDesc, progress){
  let { required = 0, current = 0 } = unlockDesc
  let unlockTxt = getDescription(unlockDesc, progress, unlockDesc?.locParams ?? {})
  return{
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    gap = smallPadding
    children = [
      {
        rendObj = ROBJ_TEXTAREA
        size = [pw(75), SIZE_TO_CONTENT]
        behavior = Behaviors.TextArea
        text = unlockTxt
        color = taskColor
      }.__update(sub_txt)
      required == 0 ? null
        : {
            rendObj = ROBJ_TEXT
            text = $"({current}/{required})"
            color = taskColor
          }
    ]
  }
}

let function mkDebriefingDailyTask(unlockDesc, appearAnimations, animDelay, onFinish) {
  let progress = {
    current = unlockDesc.current
    required = unlockDesc.required
    wasCurrent = unlockDesc.wasCurrent
    isFinished = unlockDesc.isFinished
    isCompleted = unlockDesc.isCompleted
  }
  let value = progress.wasCurrent.tofloat() / progress.required
  let addValue = (progress.current - progress.wasCurrent).tofloat() / progress.required
  let children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      margin = [smallPadding, bigPadding]
      valign = ALIGN_CENTER
      children = debriefingTaskHeader(unlockDesc, progress)
    }
    progressBar({
      value
      addValue
      color = Color(150, 150, 150)
      customStyle = { margin = smallPadding }
      addValueAnimations = [
        { prop = AnimProp.scale, from = [0, 1], to = [0, 1], play = true,
          duration = animDelay + 0.6, trigger }
        { prop = AnimProp.scale, from = [0, 1], to = [1, 1], play = true,
          duration = 0.6, easing = OutCubic, delay = animDelay + 0.6,
          onFinish, trigger }
      ]
    })
  ]
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children
    gap = smallPadding
    transform = {}
    animations = appearAnimations(animDelay, @() sound_play("ui/debriefing/new_equip"))
  }
}

let function mkTasksProgress(dailyTasksProgress, appearAnimations, onFinishCb) {
  if (dailyTasksProgress.len() == 0)
    return null

  return {
    size = [hdpx(600), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = dailyTasksProgress.map(function(unlockDesc, idx) {
      let onFinish = idx < dailyTasksProgress.len() - 1 ? null : onFinishCb
      return mkDebriefingDailyTask(unlockDesc, appearAnimations, 0.5 + idx, onFinish)
    })
  }
}

return mkTasksProgress
