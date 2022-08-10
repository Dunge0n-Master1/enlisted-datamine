from "%enlSqGlob/ui_library.nut" import *

let { animChildren } = require("%enlSqGlob/ui/glareAnimation.nut")
let { accentColor } = require("%enlSqGlob/ui/viewConst.nut")

let pbColorAcquired = accentColor
let pbColorCompleted = Color(255, 168, 0, 225)
let progressBarHeight = hdpxi(40)
let gradientWidth = hdpxi(18)
let offs = [0, (0.8 * gradientWidth).tointeger(), 0, 0]

let function progressContainerCtor(mask, borderImg, size) {
  let maskImage = $"{mask}:{size[0]}:{size[1]}:K"
  let borderImage = $"{borderImg}:{size[0]}:{size[1]}:K"
  return @(progressComp, addChild = null) {
    size
    valign = ALIGN_CENTER
    children = [
      {
        size = flex()
        rendObj = ROBJ_MASK
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        image = Picture(maskImage)
        children = progressComp
      }
      {
        rendObj = ROBJ_IMAGE
        size = flex()
        image = Picture(borderImage)
      }
      addChild
    ]
  }
}



let solidProgressCtor = @(key = "progress_bar")
  @(progress, animations = [], color = pbColorCompleted, amimColor = null) {
    key
    rendObj = ROBJ_SOLID
    size = [pw(progress * 100), flex()]
    color
    clipChildren = true
    animations = [{ prop = AnimProp.color, from = amimColor ?? pbColorAcquired, to = color
      easing = CosineFull, duration = 1.5, loop = true, play = true}]
    children = animations.len() > 0
      ? animChildren(animations)
      : null
  }

let imageProgressCtor = @(image) {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture(image)
}

let inactiveProgressCtor = @() {
  rendObj = ROBJ_SOLID
  size = [pw(100), flex()]
  color = Color(112, 112, 112)
}

let gradientProgressLine = @(progress, image = "!ui/uiskin/progress_bar_gradient.svg") {
  size = flex()
  clipChildren = true
  children = {
    rendObj = ROBJ_9RECT
    image = Picture($"{image}:{gradientWidth}:{4}:F?Ac")
    size = [pw(progress * 100), progressBarHeight]
    texOffs = offs
    screenOffs = offs
  }
}

return {
  progressBarHeight
  progressContainerCtor
  solidProgressCtor
  imageProgressCtor
  gradientProgressLine
  completedProgressLine = solidProgressCtor("animated_progress_bar")
  acquiredProgressLine = solidProgressCtor()
  inactiveProgressCtor
}
