from "%enlSqGlob/ui_library.nut" import *

let {canStartMeleeCharge} = require("%ui/hud/state/hero_weapons.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let showPlayerHuds = require("%ui/hud/state/showPlayerHuds.nut")

let tip = tipCmp({
  text = loc("tips/melee_charge")
  inputId = "Human.Melee"
  animations = [{ prop=AnimProp.opacity, from=0.0, to=0.0, duration=1.0, play=true }]
})

let showTip = Computed(@() showPlayerHuds.value && canStartMeleeCharge.value)

return @(){
  watch = [showTip]
  children = showTip.value ? tip : null
}
