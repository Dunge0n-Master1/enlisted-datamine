from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let { inPlane, isDriver } = require("%ui/hud/state/vehicle_state.nut")
let { mkHasBinding } = require("%ui/components/controlHudHint.nut")
let DRIVER_TIPS = ["Human.SeatNext", "Plane.Throttle", "Plane.Ailerons","Plane.Elevator", "plane.Rudder","Plane.EngineToggle", "Plane.ToggleGear"] //"Plane.MouseAimToggle", "Plane.MouseAimRollOverride", "Plane.SimpleJoy"
let PASSENGER_TIPS = ["Human.SeatNext"]
let watches = {}
foreach (key in [].extend(DRIVER_TIPS).extend(PASSENGER_TIPS))
  watches[key] <- mkHasBinding(key)

let showTip = Watched(true)
let animations =[{ prop=AnimProp.opacity, from=1, to=0, duration=0.5, playFadeOut = true, easing=InOutCubic}]
let defWatches = [inPlane, isDriver]
let fullWatches = [showTip].extend(defWatches).extend(watches.values())

const showTipFor = 15
inPlane.subscribe(@(v) showTip(v))
let hideTip = @() gui_scene.setTimeout(showTipFor, @() showTip(false))
showTip.subscribe(function(v) {if (v) hideTip()})
hideTip()

return function() {
  let res = { watch = defWatches}
  if (!inPlane.value)
    return res
  res.watch = fullWatches
  let tips = isDriver.value ? DRIVER_TIPS : PASSENGER_TIPS
  let children = showTip.value ? tips.filter(@(key) watches[key].value).map(@(key) tipCmp({
      inputId = key
      text = loc($"controls/{key}")
      style = {rendObj = null}
      animations
    }.__update(sub_txt))): null
  return res.__update({
    flow = FLOW_VERTICAL
    gap = hdpx(3)
    children = children
    rendObj = ROBJ_WORLD_BLUR
  })
}
