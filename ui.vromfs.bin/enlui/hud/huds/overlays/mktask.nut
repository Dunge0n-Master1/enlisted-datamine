from "%enlSqGlob/ui_library.nut" import *

let {
  mkTaskEmblem, taskHeader, taskMinHeight, taskSlotPadding,
  taskDescription, taskDescPadding
} = require("%enlSqGlob/ui/tasksPkg.nut")
let {
  darkBgColor, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { DAILY_TASK_KEY, getUnlockProgress, unlockProgress
} = require("%enlSqGlob/userstats/unlocksState.nut")

let mkTaskContent = @(unlockDesc) watchElemState(function(sf) {
  let progress = getUnlockProgress(unlockDesc, unlockProgress.value)
  return {
    size = [flex(), SIZE_TO_CONTENT]
    watch = unlockProgress
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
  }
})

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
