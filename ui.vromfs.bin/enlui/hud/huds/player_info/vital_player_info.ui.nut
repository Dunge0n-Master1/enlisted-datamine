from "%enlSqGlob/ui_library.nut" import *

let health = require("health.ui.nut")
let breath = require("breath.ui.nut")
let stamina = require("stamina.ui.nut")

return {
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  gap = fsh(0.2)
  children = [
    health, stamina, breath
  ]
}
