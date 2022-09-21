from "%enlSqGlob/ui_library.nut" import *

let { fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { colFull, midPadding, commonBtnHeight, defTxtColor, hoverTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let { mkLeftPanelButton } = require("%enlist/components/mkPanelButton.nut")
let { smallUnseenNoBlink, smallUnseenBlink } = require("%ui/components/unseenComps.nut")
let profileScene = require("%enlist/profile/profileScene.nut")
let { hasUnopenedWeeklyTasks, hasUnseenWeeklyTasks } = require("unseenUnlocksState.nut")


let defTxtStyle = {
  color = defTxtColor
}.__update(fontLarge)

let hoverTxtStyle = {
  color = hoverTxtColor
}.__update(fontLarge)

let buttonSize = [colFull(5), commonBtnHeight]

let weeklyUnseenSign = @() {
  watch = [hasUnseenWeeklyTasks, hasUnopenedWeeklyTasks]
  children = !hasUnseenWeeklyTasks.value ? null
    : hasUnopenedWeeklyTasks.value ? smallUnseenBlink
    : smallUnseenNoBlink
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

let weeklyTasksUi = mkLeftPanelButton(buttonContent, buttonSize, @() profileScene("weeklyTasks"))

return {
  weeklyTasksUi
}
