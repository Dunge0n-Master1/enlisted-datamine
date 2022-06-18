from "%enlSqGlob/ui_library.nut" import *

let {tipCmp} = require("tipComponent.nut")

let tipNext = tipCmp({
  inputId = "Spectator.Next"
})

let tipPrev = tipCmp({
  inputId = "Spectator.Prev"
})

let spectatorKeys_tip = @() {
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    {rendObj  = ROBJ_TEXT text = loc("hud/spectator_change_target")}
    tipPrev
    tipNext
  ]
}

return spectatorKeys_tip
