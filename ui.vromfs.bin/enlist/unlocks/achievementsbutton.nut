from "%enlSqGlob/ui_library.nut" import *

let { fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { midPadding, commonBtnHeight, defTxtColor, hoverTxtColor, startBtnWidth
} = require("%enlSqGlob/ui/designConst.nut")
let { mkRightPanelButton } = require("%enlist/components/mkPanelBtn.nut")
let { blinkUnseen } = require("%ui/components/unseenComponents.nut")
let profileScene = require("%enlist/profile/profileScene.nut")
let { hasUnopenedAchievements } = require("unseenUnlocksState.nut")


let defTxtStyle = {
  color = defTxtColor
}.__update(fontLarge)

let hoverTxtStyle = {
  color = hoverTxtColor
}.__update(fontLarge)

let buttonSize = [startBtnWidth, commonBtnHeight]


let achievementsUnseenSign = @() {
  watch = hasUnopenedAchievements
  children = hasUnopenedAchievements.value ? blinkUnseen : null
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
      text = loc("profile/achievementsTab")
    }.__update(sf & S_HOVER ? hoverTxtStyle : defTxtStyle)
    achievementsUnseenSign
  ]
}

let achievementsButtonsUi = mkRightPanelButton(buttonContent, buttonSize,
    @() profileScene("achievements"),
    "!ui/uiskin/tasks/weekly_tasks_icon.svg") /* FIX ME: temp picture - has to be changed */

return achievementsButtonsUi
