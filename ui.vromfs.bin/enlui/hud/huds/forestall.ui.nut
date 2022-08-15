from "%enlSqGlob/ui_library.nut" import *

let {forestallMarkActive, forestallMarkPos, forestallMarkOpacity} = require("%ui/hud/state/forestall_state.nut")

let forestallImageSize = [fsh(3),fsh(3)]
let forestallImage = freeze({
  size = forestallImageSize
  rendObj = ROBJ_IMAGE
  color = Color(255, 255, 255, 255)
  valign = ALIGN_CENTER
  transform = {}
  image = Picture("!ui/skin#sniper_rifle.svg:{0}:{0}:K".subst(forestallImageSize[1].tointeger()))
})

let animations = [
  { prop = AnimProp.scale, from =[0.25, 0.25], to = [1, 1], duration = 0.3, easing = InCubic, play = true}
]

let function mkForestallMark(){
  return {
    data = {
      minDistance = 0.1
      clampToBorder = false
      worldPos = forestallMarkPos.value
    }
    opacity = forestallMarkOpacity.value
    watch = [forestallMarkPos, forestallMarkOpacity]
    animations = animations
    transform = {}
    children = forestallImage
  }
}

let function forestallMarkComp() {
  return {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = [sw(100), sh(100)]
    children = forestallMarkActive.value ? mkForestallMark : null
    watch = [forestallMarkActive]
    behavior = Behaviors.Projection
  }
}

return forestallMarkComp
