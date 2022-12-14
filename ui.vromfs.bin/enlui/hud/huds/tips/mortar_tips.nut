from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")


let fireTip = tipCmp({inputId = "Human.Shoot", text = loc("controls/Human.Shoot"), style={rendObj=null}}.__update(sub_txt))
let exitTip = tipCmp({inputId = "Mortar.Cancel", text = loc("controls/cancelMortarAiming"), style={rendObj=null}}.__update(sub_txt))
let mapTip = tipCmp({inputId = "HUD.BigMap", text = loc("controls/HUD.BigMap"), style={rendObj=null}}.__update(sub_txt))

return {
  flow     = FLOW_VERTICAL
  children = [fireTip, exitTip, mapTip]
  gap      = hdpx(5)
}
