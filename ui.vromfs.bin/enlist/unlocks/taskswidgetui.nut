from "%enlSqGlob/ui_library.nut" import *

let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { smallPadding, bigPadding, hoverBgColor, disabledTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { receiveTaskRewards } = require("taskListState.nut")
let { taskDescription, taskDescPadding, mkTaskLabel
} = require("%enlSqGlob/ui/tasksPkg.nut")
let { mkUnlockSlot } = require("mkUnlockSlots.nut")
let { unlockRewardsInProgress } = require("%enlSqGlob/userstats/userstat.nut")
let { specialEvents, showNotActiveTaskMsgbox } = require("eventsTaskState.nut")
let buyUnlockMsg = require("buyUnlockMsg.nut")
let { isUnlockAvailable, unlockProgress
} = require("%enlSqGlob/userstats/unlocksState.nut")
let { PrimaryFlat, Purchase } = require("%ui/components/textButton.nut")
let { unlockPrices, purchaseInProgress } = require("taskRewardsState.nut")
let spinner = require("%ui/components/spinner.nut")


let btnHeight = hdpxi(46)
let btnMinWidth = hdpxi(200)
let waitingSpinner = spinner()

let function mkBtnBuyTask(task) {
  let hasBlockedByRequirement = Computed(function() {
    let pRequirement = task?.purchaseRequirement ?? ""
    return pRequirement == "" ? false
      : !(unlockProgress.value?[pRequirement].isCompleted ?? false)
  })
  return @() {
    watch = [purchaseInProgress, hasBlockedByRequirement]
    size = [SIZE_TO_CONTENT, btnHeight]
    valign = ALIGN_CENTER
    halign = ALIGN_RIGHT
    children = hasBlockedByRequirement.value ? null
      : purchaseInProgress.value?[task.name] ? waitingSpinner
      : Purchase(loc("bp/Purchase"),
          @() buyUnlockMsg(task),
          {
            key = "buyBtnTask"
            size = [SIZE_TO_CONTENT, btnHeight]
            minWidth = btnMinWidth
            margin = 0
            hotkeys = [["^J:Y", { description = { skip = true }}]]
          })
  }
}

let mkBtnReceiveReward = @(task) @() {
  watch = unlockRewardsInProgress
  size = [SIZE_TO_CONTENT, btnHeight]
  valign = ALIGN_CENTER
  halign = ALIGN_RIGHT
  children = unlockRewardsInProgress.value?[task.name] ? waitingSpinner
    : PrimaryFlat(loc("bp/getNextReward"),
        @() receiveTaskRewards(task),
        {
          key = "btnReceiveReward"
          size = [SIZE_TO_CONTENT, btnHeight]
          minWidth = btnMinWidth
          margin = 0
          hotkeys = [["^J:X", { description = { skip = true }}]]
        })
}

local lastActiveIdx = 0

const MAIN_EVENT_TASK_PLACE = 1
let function mkEventTask(task, taskPrice, idx, uProgress, isMainActive) {
  let { isCompleted, hasReward, isFinished, step, totalSteps, meta = null } = task
  let isActive = isUnlockAvailable(uProgress, task)
  let { currency = "", price = 0 } = taskPrice
  let isMain = meta?.taskListPlace == MAIN_EVENT_TASK_PLACE
  let onClick = isActive ? null : showNotActiveTaskMsgbox
  let isPurchasable = isMainActive && !isCompleted && price > 0 && currency != ""

  lastActiveIdx = isActive ? idx + 1 : lastActiveIdx

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = [
      mkUnlockSlot({
        task
        isAllRewardsVisible = true
        onClick
        hasDescription = !isFinished && isActive
        bottomBtn = !isActive ? null
          : hasReward ? mkBtnReceiveReward(task)
          : isPurchasable ? mkBtnBuyTask(task)
          : null
        customDescription = !isMain && idx >= lastActiveIdx
            ? taskDescription(loc("unlocks/blockedByPrevious"), 0, {
                margin = taskDescPadding
              })
          : isFinished
            ? taskDescription(utf8ToUpper(loc("finishedTaskText")), 0, {
                margin = taskDescPadding
              })
          : null
        rightObject = mkTaskLabel(isMain ? "main_task_lable" : null)
      })
      {
        flow = FLOW_VERTICAL
        size = [hdpx(12), flex()]
        halign = ALIGN_CENTER
        gap = bigPadding
        children = totalSteps <= 1 ? null
          : [
              {
                rendObj = ROBJ_TEXT
                text = step
                color = isActive ? hoverBgColor : disabledTxtColor
              }.__update(fontBody)
              step >= totalSteps ? null
                : {
                    rendObj = ROBJ_SOLID
                    size = [smallPadding, flex()]
                    color = isActive ? hoverBgColor : disabledTxtColor
                  }
            ]
      }
    ]
  }
}

let eventTasksUi = @(eventId) function() {
  let res = { watch = [specialEvents, unlockPrices, unlockProgress] }
  let eUnlocks = specialEvents.value?[eventId].unlocks
  if (eUnlocks == null)
    return res

  let uProgress = unlockProgress.value
  let isMainActive = eUnlocks?[0].activity.active ?? true
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    minHeight = ph(100)
    flow = FLOW_VERTICAL
    gap = fsh(2)
    valign = ALIGN_CENTER
    children = eUnlocks.map(@(task, idx)
      mkEventTask(task, unlockPrices.value?[task.name], idx, uProgress, isMainActive))
  })
}

return {
  eventTasksUi
}
