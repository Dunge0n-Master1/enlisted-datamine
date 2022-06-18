from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let fontIconButton = require("%ui/components/fontIconButton.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")
let { TextHighlight } = require("%ui/style/colors.nut")
let faComp = require("%ui/components/faComp.nut")

let btnActiveColor = Color(120, 120, 120, 160)
let btnDefaultColor = Color(160, 160, 160, 160)

let buttonParams = {
  onClick = @() null
  hotkeys=[[$"^Esc | {JB.B}", {description=loc("Close")}]]
  skipDirPadNav = true
  iconColor = @(sf) sf & S_ACTIVE ? btnActiveColor
    : sf & S_HOVER ? TextHighlight
    : btnDefaultColor
}

let shadowButtonParams = {
  color = Color(30, 30, 30, 150)
  pos = [hdpx(2), hdpx(2)]
}

return @(override) {
  size = [hdpx(21), hdpx(21)]
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  children = @(){
    watch = isGamepad
    children = !isGamepad.value
      ? [
          faComp("close", shadowButtonParams.__merge(override))
          fontIconButton("close", buttonParams.__merge(override))
        ]
      : {behavior = Behaviors.Button}.__merge(buttonParams, override)
  }
}
