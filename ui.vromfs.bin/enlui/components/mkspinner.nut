from "%enlSqGlob/ui_library.nut" import *

let mkLottieAnimation = require("%ui/components/mkLottieAnimation.nut")
let { colPart } = require("%enlSqGlob/ui/designConst.nut")


return @(size = colPart(0.35)) mkLottieAnimation("ui/lottieAnimations/spinner.json", {
  width = size
  height = size
})
