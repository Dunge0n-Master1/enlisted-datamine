from "%enlSqGlob/ui_library.nut" import *

let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { midPadding, commonBtnHeight, defTxtColor, hoverTxtColor, startBtnWidth
} = require("%enlSqGlob/ui/designConst.nut")
let { isNewDesign } = require("%enlSqGlob/designState.nut")
let { mkLeftPanelButton } = isNewDesign.value
  ? require("%enlist/components/mkPanelBtn.nut")
  : require("%enlist/components/mkPanelButton.nut")
let { blinkUnseen } = require("%ui/components/unseenComponents.nut")
let { hasCustomRooms, openCustomGameMode, openEventsGameMode, hasBaseEvent
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
      children = unseenEvents.value.len() > 0 ? blinkUnseen : null
    }
    {
      rendObj = ROBJ_TEXT
      size = [flex(), SIZE_TO_CONTENT]
      padding = [0, midPadding]
      behavior = Behaviors.Marquee
      halign = ALIGN_RIGHT
      text = loc("events_and_custom_matches")
    }.__update(sf & S_HOVER ? hoverTxtStyle : defTxtStyle)
  ]
}

let function resButton() {
  let btnAction = hasBaseEvent.value ? openEventsGameMode : openCustomGameMode
  return {
    watch = [hasCustomRooms, hasBaseEvent]
    children = hasBaseEvent.value || !hasCustomRooms.value ? null
      : mkLeftPanelButton(buttonContent, buttonSize, btnAction, "!ui/uiskin/events/events_icon.svg")
  }
}


return resButton
