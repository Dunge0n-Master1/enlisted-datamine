from "%enlSqGlob/ui_library.nut" import *

let { mkHorScrollMask } = require("%enlSqGlob/ui/gradients.nut")


const GLARE_TRIGGER = "start_glare_animation"

let glareImg = mkHorScrollMask(hdpxi(124), [hdpxi(112), hdpxi(6)])
let glareMask = mkHorScrollMask(hdpxi(248), [0, hdpxi(248)])

let startGlareAnim = @() anim_start(GLARE_TRIGGER)


let GLARE_PARAMS = {
  nestWidth = hdpxi(248)
  glareWidth = hdpxi(92)
  glareDuration = 0.5
  glareDelay = 2
  glareOpacity = 0.3
  hasMask = false
}


let maskOverride = {
  rendObj = ROBJ_MASK
  image = glareMask
}


let function mkGlare(glareParams = GLARE_PARAMS) {
  glareParams = GLARE_PARAMS.__update(glareParams)

  let {
    nestWidth, glareWidth, glareDuration, glareDelay, glareOpacity, hasMask
  } = glareParams
  let moveDistance = nestWidth + 3 * glareWidth
  return {
    size = flex()
    valign = ALIGN_CENTER
    clipChildren = true
    onAttach = @() gui_scene.clearTimer(startGlareAnim)
    children = {
      rendObj = ROBJ_IMAGE
      size = [glareWidth, ph(200)]
      pos = [-1.5 * glareWidth, 0]
      image = glareImg
      opacity = glareOpacity
      transform = {
        pivot = [0.5, 0.5]
        rotate = 15.0
      }
      animations = [{
        prop = AnimProp.translate, duration = glareDuration, delay = 0.5, play = true,
        to = [moveDistance, 0], trigger = GLARE_TRIGGER,
        onFinish = @() gui_scene.resetTimeout(glareDelay, startGlareAnim)
      }]
    }
  }.__update(hasMask ? maskOverride : {})
}

return mkGlare
