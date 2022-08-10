from "%enlSqGlob/ui_library.nut" import *

let { localSquadOrder } = require("%ui/hud/state/squad_orders.nut")
let {MY_SQUAD_TEXT_COLOR} = require("%ui/hud/style.nut")
let moveto = Picture("!ui/skin#moveto.svg")


let animations = [
  { prop=AnimProp.scale, from=[4,4], to=[1,1], duration=0.3, play=true}
  { prop=AnimProp.scale, from=[0.9, 0.9], to=[1.1, 1.1], duration=2, play=true, loop=true, easing=CosineFull }
  { prop=AnimProp.rotate, from=0, to=360, duration=20, play=true, loop=true }
  { prop=AnimProp.scale, from=[4,4], to=[1,1], duration=0.3, play=true}
  { prop=AnimProp.opacity, from=0, to=1, duration=0.3, play=true}
]

let size = [fsh(2.5), fsh(2.5)]
let transform = { pivot = [0.5, 0.5] }

let ctor = function(...) {
  let watch = localSquadOrder
  return function() {
    let orderPosition = localSquadOrder.value
    if (orderPosition==null)
      return {watch}
    return {
      watch
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      data = {
        worldPos = orderPosition
        clampToBorder = true
      }
      transform = {}
      children = {
        rendObj = ROBJ_IMAGE
        image = moveto
        size
        color = MY_SQUAD_TEXT_COLOR
        transform
        animations = animations
      }
    }
  }
}


return {
  watch = null
  ctor
}
