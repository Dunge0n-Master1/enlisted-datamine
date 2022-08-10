from "%enlSqGlob/ui_library.nut" import *

let {
  mkTaskEmblem, taskHeader, taskMinHeight, taskSlotPadding,
  taskDescription, taskDescPadding
} = require("%enlSqGlob/ui/taskPkg.nut")
let {
  darkBgColor, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { DAILY_TASK_KEY } = require("%enlSqGlob/userstats/unlocksState.nut")

let function mkTaskContent(unlockDesc) {
  let {
    isCompleted = false, isFinished = false, required = 0, current = 0
  } = unlockDesc
  let progress = { isCompleted, required, current, isFinished }
  return watchElemState(@(sf) {
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    children = {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      valign = ALIGN_CENTER
      children = [
        mkTaskEmblem(unlockDesc, progress)
        taskHeader(unlockDesc, progress, true, sf)
      ]
    }
  })
}

let mkUnlockSlot = @(unlockDesc) watchElemState(@(sf) {
  size = [flex(), SIZE_TO_CONTENT]
  minHeight = taskMinHeight
  behavior = Behaviors.Button
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_SOLID
      size = flex()
      color = darkBgColor
    }
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      padding = taskSlotPadding
      gap = smallPadding
      valign = ALIGN_CENTER
      children = [
        mkTaskContent(unlockDesc)
        unlockDesc?.table != DAILY_TASK_KEY ? null
          : taskDescription(unlockDesc.localization.description, sf, {
              margin = taskDescPadding
            })
      ]
    }
  ]
})

return mkUnlockSlot
