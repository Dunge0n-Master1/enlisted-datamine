from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { smallPadding, bigPadding, defTxtColor, hoverBgColor, disabledTxtColor, defBgColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { dailyTasksByDifficulty, receiveTaskRewards, getTotalRerolls, getLeftRerolls,
  isRerollInProgress, canTakeDailyTaskReward, doRerollUnlock
} = require("taskListState.nut")
let { startBtnWidth } = require("%enlist/startBtn.nut")
let { weeklyTasks } = require("weeklyUnlocksState.nut")
let { hasUnopenedWeeklyTasks, hasUnseenWeeklyTasks } = require("unseenUnlocksState.nut")
let { taskHeader, taskDescription, taskDescPadding, mkTaskLabel, weeklyTasksTitle
} = require("%enlSqGlob/ui/taskPkg.nut")
let { mkUnlockSlot, mkHideTrigger } = require("mkUnlockSlot.nut")
let { userstatStats, unlockRewardsInProgress } = require("%enlSqGlob/userstats/userstat.nut")
let eliteBattlePassWnd = require("%enlist/battlepass/eliteBattlePassWnd.nut")
let { eventUnlocks, showNotActiveTaskMsgbox } = require("eventsTaskState.nut")
let buyUnlockMsg = require("buyUnlockMsg.nut")
let { isUnlockAvailable, getUnlockProgress, unlockProgress
} = require("%enlSqGlob/userstats/unlocksState.nut")
let { PrimaryFlat, Purchase, soundDefault } = require("%ui/components/textButton.nut")
let { unlockPrices, purchaseInProgress } = require("taskRewardsState.nut")
let spinner = require("%ui/components/spinner.nut")
let { sound_play } = require("sound")
let profileScene = require("%enlist/profile/profileScene.nut")
let { smallUnseenNoBlink, smallUnseenBlink } = require("%ui/components/unseenComps.nut")


let mkRerollText = @(leftRerolls, totalRerolls) {
  size = [sw(30), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = defTxtColor
  text = "\n".concat(
    loc("unlocks/reroll/youCanReroll"),
    loc("unlocks/reroll/info", {
      left = leftRerolls
      total = totalRerolls
    }))
}.__update(sub_txt)

let function askForRerollConfirm(unlockDesc) {
  msgbox.show({
    text = loc("unlocks/reroll/askForConfirm")
    buttons = [
      { text = loc("Ok"), action = @() doRerollUnlock(unlockDesc) }
      { text = loc("Cancel"), isCurrent = true, isCancel = true }
    ]
  })
}

let function openTaskMsgbox(unlockDesc, leftRerolls = 0, totalRerolls = 0) {
  let progress = getUnlockProgress(unlockDesc)
  let buttons = []
  if (leftRerolls > 0)
    buttons.append({
      text = loc("btn/rerollUnlock")
      action = @() askForRerollConfirm(unlockDesc)
    })
  buttons.append({ text = loc("Ok"), isCurrent = true, isCancel = true })

  msgbox.showMessageWithContent({
    content = {
      flow = FLOW_VERTICAL
      size = [sh(100), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      margin = [0,0,fsh(5),0]
      gap = fsh(5)
      children = [
        taskHeader(unlockDesc, progress, true, 0, {
          halign = ALIGN_CENTER
        }.__update(body_txt))
        taskDescription(unlockDesc.localization.description, 0, { halign = ALIGN_CENTER})
        leftRerolls > 0 ? mkRerollText(leftRerolls, totalRerolls) : null
      ]
    }
    buttons
  })
}

local curTimeout = null

let function mkDailyTasksBlock(tasksList, stats, canTakeReward){
  return {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      halign = ALIGN_RIGHT
      children = tasksList.value.map(@(tasks, taskStype) {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          children = tasks.map(function(task) {
            let leftRerolls = getLeftRerolls(task, stats)
            let totalRerolls = getTotalRerolls(task, stats)
            let onClick = !task.hasReward ? @() openTaskMsgbox(task, leftRerolls, totalRerolls)
              : canTakeReward
                ? function() {
                    if (curTimeout != null)
                      return
                    anim_start(mkHideTrigger(task))
                    sound_play("ui/reward_receive")
                    curTimeout = gui_scene.setTimeout(0.5, function() {
                      curTimeout = null
                      receiveTaskRewards(task)
                    })
                  }
              : @() msgbox.show({
                  text = loc("unlocks/dailyTasksLimitOnReward")
                  buttons = [
                    {
                      text = loc("bp/buyBattlePass")
                      action = eliteBattlePassWnd
                    }
                    { text = loc("Cancel"), isCancel = true}
                  ]
                })
            return mkUnlockSlot({
              task
              onClick
              hasWaitIcon = isRerollInProgress
              rerolls = leftRerolls
              rightObject = taskStype == "hardTasks"
                ? mkTaskLabel("main_task_lable")
                : mkTaskLabel()
              hasShowAnim = true
              canTakeReward
            })
          })
        }
      ).values()
    }
  }

let function dailyTasksUi() {
  let res = {
    watch = [dailyTasksByDifficulty, canTakeDailyTaskReward, userstatStats]
  }
  let { easyTasks = [], hardTasks = [] } = dailyTasksByDifficulty.value
  if (easyTasks.len() <= 0 && hardTasks.len() <= 0)
    return res

  let canTakeReward = canTakeDailyTaskReward.value
  let stats = userstatStats.value?.stats
  return res.__update({
    size = [startBtnWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = mkDailyTasksBlock(dailyTasksByDifficulty, stats, canTakeReward)
  })
}

let widgetStyle = {
  size = [flex(), SIZE_TO_CONTENT]
  behavior = Behaviors.Button
  sound = soundDefault
}

let mkHoverBar = @(sf) sf & S_HOVER
  ? {
      rendObj = ROBJ_SOLID
      size = flex()
      color = defBgColor
      animations = [{
        prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true
      }]
    }
  : null

let weeklyUnseenSign = @() {
  watch = [hasUnseenWeeklyTasks, hasUnopenedWeeklyTasks]
  margin = bigPadding
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  children = !hasUnseenWeeklyTasks.value ? null
    : hasUnopenedWeeklyTasks.value ? smallUnseenBlink
    : smallUnseenNoBlink
}

let weeklyTasksUi = @() {
  watch = weeklyTasks
  size = [startBtnWidth, SIZE_TO_CONTENT]
  children = weeklyTasks.value.len() == 0 ? null
    : watchElemState(@(sf) {
        onClick = @() profileScene("weeklyTasks")
        children = [
          mkHoverBar(sf)
          weeklyTasksTitle(sf)
          weeklyUnseenSign
        ]
      }.__update(widgetStyle))
}

let btnHeight = hdpxi(46)
let btnMinWidth = hdpxi(200)

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
      : purchaseInProgress.value?[task.name] ? spinner
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
  children = unlockRewardsInProgress.value?[task.name] ? spinner
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
        bgColor = defBgColor
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
              }.__update(body_txt)
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

let function eventTasksUi() {
  let uProgress = unlockProgress.value
  let eUnlocks = eventUnlocks.value
  let isMainActive = eUnlocks?[0].activity.active ?? true
  return {
    watch = [eventUnlocks, unlockPrices, unlockProgress]
    size = [flex(), SIZE_TO_CONTENT]
    minHeight = ph(100)
    flow = FLOW_VERTICAL
    gap = fsh(2)
    valign = ALIGN_CENTER
    children = eUnlocks.map(@(task, idx)
      mkEventTask(task, unlockPrices.value?[task.name], idx, uProgress, isMainActive))
  }
}

return {
  dailyTasksUi
  weeklyTasksUi
  eventTasksUi
}
