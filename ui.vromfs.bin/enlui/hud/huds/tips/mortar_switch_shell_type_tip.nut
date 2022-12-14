from "%enlSqGlob/ui_library.nut" import *

let {isMortarMode} = require("%ui/hud/state/mortar.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")

let tip = tipCmp({
  inputId = "Mortar.SwitchShellType"
  text = loc("controls/switchMortarShellType")
  textColor = Color(200,140,100,110)
})

return @() {
  watch = isMortarMode
  children = isMortarMode.value ? tip : null
}
