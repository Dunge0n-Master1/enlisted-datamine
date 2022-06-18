from "%enlSqGlob/ui_library.nut" import *

let {isBipodPlaceable, isBipodEnabled} = require("%ui/hud/state/bipod_state.nut")
let {tipCmp} = require("tipComponent.nut")

let placeTip = tipCmp({
  inputId = "Human.BipodToggle"
  text = loc("tips/place_bipod")
  textColor = Color(100,140,200,110)
})

let showPlaceBipod = Computed(@()
  isBipodPlaceable.value
  && !isBipodEnabled.value
)

return @() {
  watch = showPlaceBipod
  size = SIZE_TO_CONTENT
  children = showPlaceBipod.value ? placeTip : null
}
