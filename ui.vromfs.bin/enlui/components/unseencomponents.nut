from "%enlSqGlob/ui_library.nut" import *

let { titleTxtColor, fullTransparentBgColor, unseenColor } = require("%enlSqGlob/ui/designConst.nut")
let { mkTwoSidesGradientX } = require("%enlSqGlob/ui/gradients.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")


let panelTxtStyle = { color = titleTxtColor }.__update(fontBody)
let defUnseenDotSize = hdpxi(22)
let blinkingSize = hdpxi(18)
let unblinkSignDotSize = hdpxi(8)

const BLINK_TRIGGER = "start_blinking_animation"
const BLINK_DELAY = 4


let smallDot = {
  rendObj = ROBJ_VECTOR_CANVAS
  size = [unblinkSignDotSize, unblinkSignDotSize]
  color = unseenColor
  fillColor = unseenColor
  commands =  [[ VECTOR_ELLIPSE, 50, 50, 50, 50 ]]
}


gui_scene.setInterval(BLINK_DELAY, @() anim_start(BLINK_TRIGGER))

let blinkUnseen = {
  size = [defUnseenDotSize, defUnseenDotSize]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  children = [
    {
      rendObj = ROBJ_VECTOR_CANVAS
      size = [blinkingSize, blinkingSize]
      fillColor = fullTransparentBgColor
      color = unseenColor
      opacity = 0
      commands =  [
        [ VECTOR_ELLIPSE, 50, 50, 50, 50 ],
        [VECTOR_WIDTH, 50]
      ]
      transform = {}
      animations = [
        { prop = AnimProp.opacity, from = 1, to = 0.3, duration = 0.8, play = true, easing = OutCubic,
          trigger = BLINK_TRIGGER }
        { prop = AnimProp.scale, from = [0,0], to = [1, 1], duration = 0.8, trigger = BLINK_TRIGGER,
          play = true}
      ]
    }
    smallDot
  ]
}


let unblinkUnseen = {
  size = [defUnseenDotSize, defUnseenDotSize]
  hplace = ALIGN_RIGHT
  halign = ALIGN_CENTER
  vplace = ALIGN_TOP
  valign = ALIGN_CENTER
  children = smallDot
}


let panelBgImg = mkTwoSidesGradientX({sideColor = 0x00116C15, centerColor = 0x00116C15, isAlphaPremultiplied=false})

let unseenPanel = @(text, override = null, txtStyle = null) {
  size = [flex(), hdpx(44)]
  rendObj = ROBJ_IMAGE
  image = panelBgImg
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = utf8ToUpper(text)
    halign = ALIGN_CENTER
  }.__update(panelTxtStyle, txtStyle ?? {})
}.__update(override ?? {})

return {
  blinkUnseen
  unblinkUnseen
  unseenPanel
}
