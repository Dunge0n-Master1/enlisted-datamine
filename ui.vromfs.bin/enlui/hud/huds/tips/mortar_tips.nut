from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")


let fireTip = tipCmp({inputId = "Human.Shoot", text = loc("controls/Human.Shoot"), style={rendObj=null}}.__update(fontSub))
let exitTip = tipCmp({inputId = "Mortar.Cancel", text = loc("controls/cancelMortarAiming"), style={rendObj=null}}.__update(fontSub))
let mapTip = tipCmp({inputId = "HUD.BigMap", text = loc("controls/HUD.BigMap"), style={rendObj=null}}.__update(fontSub))

return {
  flow     = FLOW_VERTICAL
  children = [fireTip, exitTip, mapTip]
  gap      = hdpx(5)
}
