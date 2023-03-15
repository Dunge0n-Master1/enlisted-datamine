from "%enlSqGlob/ui_library.nut" import *

let { fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { midPadding, commonBtnHeight, defTxtColor, hoverTxtColor, startBtnWidth
} = require("%enlSqGlob/ui/designConst.nut")
let { isNewDesign } = require("%enlSqGlob/designState.nut")
let { mkLeftPanelButton, mkRightPanelButton } = isNewDesign.value
  ? require("%enlist/components/mkPanelBtn.nut")
  : require("%enlist/components/mkPanelButton.nut")
let { blinkUnseen, unblinkUnseen } = require("%ui/components/unseenComponents.nut")
let profileScene = require("%enlist/profile/profileScene.nut")
let { hasUnopenedWeeklyTasks, hasUnseenWeeklyTasks } = require("unseenUnlocksState.nut")


let defTxtStyle = {
  color = defTxtColor
}.__update(fontLarge)

let hoverTxtStyle = {
  color = hoverTxtColor
}.__update(fontLarge)

let buttonSize = [startBtnWidth, commonBtnHeight]


let weeklyUnseenSign = @() {
  watch = [hasUnseenWeeklyTasks, hasUnopenedWeeklyTasks]
  children = !hasUnseenWeeklyTasks.value ? null
    : hasUnopenedWeeklyTasks.value ? blinkUnseen
    : unblinkUnseen
}

let buttonContent = @(sf) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      size = [flex(), SIZE_TO_CONTENT]
      padding = [0, midPadding]
      text = loc("profile/weeklyTasks")
    }.__update(sf & S_HOVER ? hoverTxtStyle : defTxtStyle)
    weeklyUnseenSign
  ]
}

let weeklyTasksUi = isNewDesign.value
  ? mkRightPanelButton(buttonContent, buttonSize, @() profileScene("weeklyTasks"),
    "!ui/uiskin/tasks/weekly_tasks_icon.svg")
  : mkLeftPanelButton(buttonContent, buttonSize, @() profileScene("weeklyTasks"))

return {
  weeklyTasksUi
}
