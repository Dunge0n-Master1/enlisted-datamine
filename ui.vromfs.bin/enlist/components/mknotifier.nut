from "%enlSqGlob/ui_library.nut" import *

let {
  bigPadding, smallPadding, titleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")


let mkNotifier = @(txt, customStyle = {}, bgStyle = {}, txtStyle = {}) {
  halign = ALIGN_CENTER
  children = [
    {
      size = flex()
      rendObj = ROBJ_SOLID
      color = Color(0,100,0)
      animations = [
        { prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1, play = true, loop = true, easing = Blink }
      ]
    }.__update(bgStyle)
    {
        rendObj = ROBJ_TEXTAREA
        margin = [smallPadding, bigPadding]
        behavior = Behaviors.TextArea
        halign = ALIGN_CENTER
        color = titleTxtColor
        text = txt
    }.__update(txtStyle)
  ]
}.__update(customStyle)

let blinkOnOverride = { key = "blink_on" }
let blinkOffOverride = { key = "blink_off", animations = null }

return {
  mkNotifierBlink = @(txt, customStyle = {}, bgStyle = {}, txtStyle = {})
    mkNotifier(txt, customStyle, bgStyle.__update(blinkOnOverride), txtStyle)
  mkNotifierNoBlink = @(txt, customStyle = {}, bgStyle = {}, txtStyle = {})
    mkNotifier(txt, customStyle, bgStyle.__update(blinkOffOverride), txtStyle)
}