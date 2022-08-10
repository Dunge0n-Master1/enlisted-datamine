from "%enlSqGlob/ui_library.nut" import *

let {isMortarMode} = require("%ui/hud/state/mortar.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")

let tip = tipCmp({
  inputId = "HUD.SetMark"
  text = loc("controls/HUD.SetMark")
  textColor = Color(200,140,100,110)
})

return @() {
  watch = isMortarMode
  children = isMortarMode.value ? tip : null
}
