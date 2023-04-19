from "%enlSqGlob/ui_library.nut" import *

let mkLottieAnimation = require("%ui/components/mkLottieAnimation.nut")
let { colPart, titleTxtColor } = require("%enlSqGlob/ui/designConst.nut")
let { mkTwoSidesGradientX } = require("%enlSqGlob/ui/gradients.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")


let panelTxtStyle = { color = titleTxtColor }.__update(fontLarge)
let defUnseenDotSize = colPart(0.4)
let unblinkSignDotSize = colPart(0.2)


let unseenAnimDot = mkLottieAnimation("ui/lottieAnimations/notifier.json", {
  width = defUnseenDotSize
  height = defUnseenDotSize
})

let blinkUnseen = {
  size = [defUnseenDotSize, defUnseenDotSize]
  vplace = ALIGN_TOP
  hplace = ALIGN_RIGHT
  children = unseenAnimDot
}


let unblinkUnseen = {
  size = [defUnseenDotSize, defUnseenDotSize]
  hplace = ALIGN_RIGHT
  halign = ALIGN_CENTER
  vplace = ALIGN_TOP
  valign = ALIGN_CENTER
  children = {
    size = [unblinkSignDotSize, unblinkSignDotSize]
    rendObj = ROBJ_IMAGE
    image = Picture("ui/skin#tasks/ellipse_lotty_green.svg:{0}:{0}:K".subst(unblinkSignDotSize))
  }
}


let panelBgImg = mkTwoSidesGradientX(0x00116C15, 0xFF116C15, false)

let unseenPanel = @(text, override = {}) {
  size = [flex(), colPart(0.709)]
  rendObj = ROBJ_IMAGE
  image = panelBgImg
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = utf8ToUpper(text)
    halign = ALIGN_CENTER
  }.__update(panelTxtStyle)
}.__update(override)

return {
  blinkUnseen
  unblinkUnseen
  unseenPanel
}
