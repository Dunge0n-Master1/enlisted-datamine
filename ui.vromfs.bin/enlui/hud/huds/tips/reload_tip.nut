from "%enlSqGlob/ui_library.nut" import *

let {inVehicle} = require("%ui/hud/state/vehicle_state.nut")
let {needReload} = require("%ui/hud/state/hero_weapons.nut")
let isMachinegunner = require("%ui/hud/state/machinegunner_state.nut")
let {tipCmp} = require("tipComponent.nut")

let color0 = Color(200,40,40,110)
let color1 = Color(200,200,40,180)

let tip = tipCmp({
  inputId = "Human.Reload"
  text = loc("tips/need_reload")
  sound = {
    attach = {name="ui/need_reload", vol=0.1}
  }
  textColor = Color(200,40,40,110)
  textAnims = [
    { prop=AnimProp.color, from=color0, to=color1, duration=1.0, play=true, loop=true, easing=CosineFull }
  ]
})
let showReloadTip = Computed(@() needReload.value && !inVehicle.value && !isMachinegunner.value)
return @() {
  watch = showReloadTip
  size = SIZE_TO_CONTENT
  children = showReloadTip.value ? tip : null
}
