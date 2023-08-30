from "%enlSqGlob/ui_library.nut" import *

let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { midPadding, commonBtnHeight, defTxtColor, startBtnWidth, bigPadding, defItemBlur,
  transpPanelBgColor, darkTxtColor, smallPadding, hoverSlotBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let { blinkUnseen, unblinkUnseen } = require("%ui/components/unseenComponents.nut")
let profileScene = require("%enlist/profile/profileScene.nut")
let { hasWeeklyTasks, hasUnopenedWeeklyTasks, hasUnseenWeeklyTasks
} = require("unseenUnlocksState.nut")


let buttonSize = [startBtnWidth, commonBtnHeight]
let iconSize = [hdpxi(24), hdpxi(30)]


let weeklyUnseenSign = @() {
  watch = [hasUnseenWeeklyTasks, hasUnopenedWeeklyTasks]
  vplace = ALIGN_TOP
  hplace = ALIGN_RIGHT
  children = !hasUnseenWeeklyTasks.value ? null
    : hasUnopenedWeeklyTasks.value ? blinkUnseen
    : unblinkUnseen
}

let buttonContent = watchElemState(@(sf) {
  rendObj = ROBJ_WORLD_BLUR
  size = buttonSize
  fillColor = sf & S_HOVER ? hoverSlotBgColor : transpPanelBgColor
  color = defItemBlur
  behavior = Behaviors.Button
  onClick = @() profileScene("weeklyTasks")
  sound = {
    hover = "ui/enlist/button_highlight"
    click = "ui/enlist/button_click"
    active = "ui/enlist/button_action"
  }
  children = [
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      padding = [0, bigPadding]
      valign = ALIGN_CENTER
      children = [
        {
          rendObj = ROBJ_IMAGE
          size = iconSize
          color = sf & S_HOVER ? darkTxtColor : defTxtColor
          image = Picture("!ui/uiskin/tasks/weekly_tasks_icon.svg:{0}:{1}:K"
          .subst(iconSize[0], iconSize[1]))
        }
        {
          rendObj = ROBJ_TEXT
          size = [flex(), SIZE_TO_CONTENT]
          padding = [0, midPadding]
          text = loc("profile/weeklyTasks")
          color = sf & S_HOVER ? darkTxtColor : defTxtColor
        }.__update(fontBody)
      ]
    }
    weeklyUnseenSign
  ]
})


let function weeklyTasksUi() {
  let res = { watch = hasWeeklyTasks }
  if (!hasWeeklyTasks.value)
    return res

  return res.__update({
    children = buttonContent
  })
}

return weeklyTasksUi
