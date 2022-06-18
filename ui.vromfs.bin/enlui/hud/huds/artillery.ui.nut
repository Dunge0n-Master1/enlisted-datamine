from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {artilleryAvailableTimeLeft, artilleryIsReady, artilleryIsAvailable} = require("%ui/hud/state/artillery.nut")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let {blurBack} = require("%ui/hud/huds/player_info/style.nut")
let artillerySize = [fsh(4.0), fsh(4.0)]
let artilleryIcon = Picture("ui/skin#artillery_strike.svg:{0}:{0}:K".subst(artillerySize[1]))

let artilleryIconComp = @() {
  rendObj = ROBJ_IMAGE
  image = artilleryIcon
  hplace = ALIGN_RIGHT
  size = artillerySize
  color = Color(255, 255, 255)
  opacity = artilleryIsReady.value ? 1.0 : 0.5
  watch = artilleryIsReady
}

let artilleryStartedTimeLeftComp = @() {
  watch = artilleryAvailableTimeLeft
  rendObj = ROBJ_TEXT
  color = Color(255, 255, 255)
  text = artilleryAvailableTimeLeft.value > 0 ? secondsToStringLoc(artilleryAvailableTimeLeft.value) : null
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
}.__update(body_txt)

let artilleryComps = [
  blurBack,
  {
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    children = [artilleryIconComp, artilleryStartedTimeLeftComp]
  }
]

let artillery = @() {
  watch=[artilleryIsAvailable]
  children = !artilleryIsAvailable.value ? null : artilleryComps
}

return artillery
