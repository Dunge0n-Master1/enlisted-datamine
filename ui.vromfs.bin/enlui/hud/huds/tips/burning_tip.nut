from "%enlSqGlob/ui_library.nut" import *

let {isBurning} = require("%ui/hud/state/burning_state_es.nut")
let {tipCmp} = require("tipComponent.nut")
let {inVehicle} = require("%ui/hud/state/vehicle_state.nut")
let burningState = require("%ui/hud/state/burning.nut")

let color0 = Color(200,40,40,110)
let color1 = Color(200,200,40,180)

let animColor = [
  { prop=AnimProp.color, from=color0, to=color1, duration=1.0, play=true, loop=true, easing=CosineFull }
  { prop=AnimProp.scale, from=[1,1], to=[1.0, 1.1], duration=3.0, play=true, loop=true, easing=CosineFull }
]
let animAppear = [{ prop=AnimProp.translate, from=[sw(50),0], to=[0,0], duration=0.5, play=true, easing=InBack }]

let tip = tipCmp({
  inputId = "Inventory.UseMedkit"
  text = loc("tips/burning_tip")
  textColor = Color(200,40,40,110)
  animations = animAppear
  textAnims = animColor
})

let tipLeaveFromVehicle = tipCmp({
  inputId = "Human.Use"
  text = loc("tips/burning_in_vehicle_tip", "Leave from vehcile from extinguish a fire")
  textColor = Color(200,40,40,110)
  animations = animAppear
  textAnims = animColor
})

return function() {
  return {
    watch = [isBurning, inVehicle, burningState]
    size = SIZE_TO_CONTENT
    children = !isBurning.value || burningState.value.isPuttingOut ? null
      : inVehicle.value ? tipLeaveFromVehicle
      : tip
  }
}

