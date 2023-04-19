from "%enlSqGlob/ui_library.nut" import *

let { fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { midPadding, commonBtnHeight, defTxtColor, startBtnWidth, bigPadding,
  defItemBlur, accentColor, transpPanelBgColor, colPart, darkTxtColor, smallPadding
} = require("%enlSqGlob/ui/designConst.nut")
let { blinkUnseen, unblinkUnseen } = require("%ui/components/unseenComponents.nut")
let profileScene = require("%enlist/profile/profileScene.nut")
let { hasUnopenedWeeklyTasks, hasUnseenWeeklyTasks } = require("unseenUnlocksState.nut")


let defTxtStyle = {
  color = defTxtColor
}.__update(fontLarge)

let hoverTxtStyle = {
  color = darkTxtColor
}.__update(fontLarge)

let buttonSize = [startBtnWidth, commonBtnHeight]
let iconSize = [colPart(0.4), colPart(0.5)]


let weeklyUnseenSign = @() {
  watch = [hasUnseenWeeklyTasks, hasUnopenedWeeklyTasks]
  vplace = ALIGN_TOP
  hplace = ALIGN_RIGHT
  children = !hasUnseenWeeklyTasks.value ? null
    : hasUnopenedWeeklyTasks.value ? blinkUnseen
    : unblinkUnseen
}

let buttonContent = @(sf) {
  size = flex()
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
        }.__update(sf & S_HOVER ? hoverTxtStyle : defTxtStyle)
      ]
    }
    weeklyUnseenSign
  ]
}


let weeklyTasksUi = watchElemState(@(sf) {
  rendObj = ROBJ_WORLD_BLUR
  size = buttonSize
  fillColor = sf & S_HOVER ? accentColor : transpPanelBgColor
  color = defItemBlur
  behavior = Behaviors.Button
  onClick = @() profileScene("weeklyTasks")
  children = buttonContent(sf)
})


return weeklyTasksUi
