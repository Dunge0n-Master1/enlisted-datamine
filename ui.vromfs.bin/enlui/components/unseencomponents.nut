from "%enlSqGlob/ui_library.nut" import *

let mkLottieAnimation = require("%ui/components/mkLottieAnimation.nut")
let { colPart, titleTxtColor } = require("%enlSqGlob/ui/designConst.nut")
let { mkTwoSidesGradientX } = require("%enlSqGlob/ui/gradients.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")


let panelTxtStyle = { color = titleTxtColor }.__update(fontLarge)

let mkBlinkNotifier = @(size = colPart(0.5))
  mkLottieAnimation("ui/lottieAnimations/notifier.json", {
    width = size
    height = size
  })


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
  mkBlinkNotifier
  unseenPanel
}
