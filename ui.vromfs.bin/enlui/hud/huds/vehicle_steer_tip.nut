from "%enlSqGlob/ui_library.nut" import *

let {sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let { inGroundVehicle, inShip, isDriver, inTank } = require("%ui/hud/state/vehicle_state.nut")
let {mkHasBinding } = require("%ui/components/controlHudHint.nut")
let {textListFromAction, keysImagesMap} = require("%ui/control/formatInputBinding.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")

let PASSENGER_TIPS = ["Human.SeatNext"]
let DRIVER_TIPS = ["Human.SeatNext", "Vehicle.Brake", "Vehicle.Accel", "Vehicle.Steer", "Vehicle.Throttle", "Vehicle.Horn"]
let WHEELED_VEHICLE_DRIVER_TIPS = ["Human.SeatNext", "Vehicle.Brake", "Vehicle.HandBrake", "Vehicle.Accel", "Vehicle.Steer", "Vehicle.Throttle", "Vehicle.Horn"]

let watches = {}
foreach (key in [].extend(WHEELED_VEHICLE_DRIVER_TIPS).extend(PASSENGER_TIPS))
  watches[key] <- mkHasBinding(key)

let showTip = Watched(true)
let animations =[{ prop=AnimProp.opacity, from=1, to=0, duration=0.5, playFadeOut = true, easing=InOutCubic}]
let defWatches = [inGroundVehicle, inShip, isDriver]
let fullWatches = [showTip,keysImagesMap].extend(defWatches).extend(watches.values())

const showTipFor = 15
inGroundVehicle.subscribe(@(v) showTip(v))
let hideTip = @() gui_scene.setTimeout(showTipFor, @() showTip(false))
showTip.subscribe(function(v) {if (v) hideTip()})
hideTip()

let function prepareTipCmp(key,imageMap) {
  if (isGamepad.value) {
    let hasImage = textListFromAction(key, 1).findvalue(@(e) e in imageMap) != null
    if (!hasImage)
      return null
  }

  return tipCmp({
      inputId = key
      text = loc($"controls/{key}")
      style = {rendObj = null}
      animations = animations
    }.__update(sub_txt))
}

return function() {
  let res = { watch = defWatches}
  if (!inGroundVehicle.value)
    return res
  res.watch = fullWatches
  let tips = !isDriver.value || inTank.value ? PASSENGER_TIPS
    : inShip.value ? DRIVER_TIPS
    : WHEELED_VEHICLE_DRIVER_TIPS

  let children = showTip.value ? tips.filter(@(key) watches[key].value).map(@(key) prepareTipCmp(key,keysImagesMap.value)): null
  return res.__update({
    flow = FLOW_VERTICAL
    gap = hdpx(3)
    children = children
    rendObj = ROBJ_WORLD_BLUR
  })
}
