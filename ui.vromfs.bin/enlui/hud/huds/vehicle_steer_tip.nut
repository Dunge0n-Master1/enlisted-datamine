from "%enlSqGlob/ui_library.nut" import *

let dainput = require("dainput2")
let {fontSub} = require("%enlSqGlob/ui/fontsStyle.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let {inGroundVehicle, controlledVehicleEid} = require("%ui/hud/state/vehicle_state.nut")
let {steerTipDuration, vehicleSteerTips} = require("%ui/hud/state/vehicle_steer_tips.nut")
let {textListFromAction, keysImagesMap} = require("%ui/control/formatInputBinding.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")

let showTip = Watched(true)
let animations =[{ prop=AnimProp.opacity, from=1, to=0, duration=0.5, playFadeOut = true, easing=InOutCubic}]
let defWatches = [inGroundVehicle]
let fullWatches = [showTip,keysImagesMap,vehicleSteerTips, steerTipDuration].extend(defWatches)

inGroundVehicle.subscribe(@(v) showTip(v))
let hideTipCb = @() showTip(false)
let hideTip = function() {
  let duration = steerTipDuration.value
  if (duration > 0)
    gui_scene.resetTimeout(duration, hideTipCb)
}
steerTipDuration.subscribe(function(duration) {
  if (duration < 0)
    gui_scene.clearTimer(hideTipCb)
  else
    gui_scene.resetTimeout(duration, hideTipCb)
})
showTip.subscribe(function(v) {if (v) hideTip()})
hideTip()
controlledVehicleEid.subscribe(@(_) showTip(true))

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
    }.__update(fontSub))
}

return function() {
  let res = { watch = defWatches }
  if (!inGroundVehicle.value)
    return res
  res.watch = fullWatches
  let children = showTip.value ?
    vehicleSteerTips.value
      .filter(@(key) dainput.is_action_binding_set(dainput.get_action_handle(key, 0xFFFF), isGamepad.value ? 1 : 0))
      .map(@(key) prepareTipCmp(key,keysImagesMap.value))
    : null
  return res.__update({
    flow = FLOW_VERTICAL
    gap = hdpx(3)
    children = children
    rendObj = ROBJ_WORLD_BLUR
  })
}
