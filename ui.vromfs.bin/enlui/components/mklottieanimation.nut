from "%enlSqGlob/ui_library.nut" import *

let { colPart } = require("%enlSqGlob/ui/designConst.nut")


let defSize = {
  height = colPart(0.4)
  width = colPart(0.4)
}
let getPicture = memoize(@(source) LottieAnimation(source))


let function mkLottieAnimation(lottie, params = defSize) {
  let { width, height } = params
  let lottieString = $"lottie:t={lottie}; canvasWidth:i={width}; canvasHeight:i={height}; loop:b=true; play:b=true;"
  let imageSource = $"ui/skin#render\{{lottieString}\}.render"
  let image = getPicture(imageSource)


  return {
    rendObj = ROBJ_IMAGE
    image
    key = image
    animated = true
    size = [width, height]
    keepAspect = KEEP_ASPECT_FIT
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
  }
}

return mkLottieAnimation