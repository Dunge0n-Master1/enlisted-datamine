from "%enlSqGlob/ui_library.nut" import *

let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { midPadding, commonBtnHeight, defTxtColor, hoverTxtColor, startBtnWidth
} = require("%enlSqGlob/ui/designConst.nut")
let { isNewDesign } = require("%enlSqGlob/designState.nut")
let { mkLeftPanelButton } = isNewDesign.value
  ? require("%enlist/components/mkPanelBtn.nut")
  : require("%enlist/components/mkPanelButton.nut")
let { smallUnseenNoBlink } = require("%ui/components/unseenComps.nut")
let { hasCustomRooms, openCustomGameMode, openEventsGameMode, eventGameModes
} = require("eventModesState.nut")
let { unseenEvents } = require("unseenEvents.nut")

let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let hoverTxtStyle = { color = hoverTxtColor }.__update(fontMedium)
let buttonSize = [startBtnWidth, commonBtnHeight]


let buttonContent = @(sf) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    @() {
      watch = unseenEvents
      children = unseenEvents.value.len() > 0 ? smallUnseenNoBlink : null
    }
    {
      rendObj = ROBJ_TEXT
      size = [flex(), SIZE_TO_CONTENT]
      padding = [0, midPadding]
      halign = ALIGN_RIGHT
      text = loc("events_and_custom_matches")
    }.__update(sf & S_HOVER ? hoverTxtStyle : defTxtStyle)
  ]
}

let function resButton() {
  let hasAnyEvent = eventGameModes.value.len() > 0
  let btnAction = hasAnyEvent ? openEventsGameMode : openCustomGameMode
  return {
    watch = [hasCustomRooms, eventGameModes]
    children = hasCustomRooms.value || eventGameModes.value.len() > 0
      ? mkLeftPanelButton(buttonContent, buttonSize, btnAction, "!ui/uiskin/events/events_icon.svg")
      : null
  }
}


return resButton
