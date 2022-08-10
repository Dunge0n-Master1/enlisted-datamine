from "%enlSqGlob/ui_library.nut" import *

let { MY_SQUAD_TEXT_COLOR } = require("%ui/hud/style.nut")
let { makeArrow } = require("%ui/hud/hud_markers/components/hud_markers_components.nut")
let { localSquadOrder } = require("%ui/hud/state/squad_orders.nut")

let moveToPicSize = [fsh(4), fsh(4)]
let moveToPicName = $"!ui/skin#moveto.svg:{moveToPicSize[0]}:{moveToPicSize[1]}:K"

let defTransform = {}

let squadOrderAnim = [
  { prop=AnimProp.scale, from=[0.9, 0.9], to=[1.1, 1.1], duration=2, play=true, loop=true, easing=CosineFull }
  { prop=AnimProp.rotate, from=0, to=360, duration=20, play=true, loop=true }
  { prop=AnimProp.opacity, from=0, to=1, duration=0.3, play=true}
  { prop = AnimProp.opacity, from = 0.8, to = 1,
    duration = 2, play = true, loop = true, easing = CosineFull}
]

let squadOrderIcon = {
  transform = {
    scale = [1, 0.5]
  }
  children = {
    rendObj = ROBJ_IMAGE
    size = moveToPicSize
    pos = [0, 0]
    color = MY_SQUAD_TEXT_COLOR
    image = Picture(moveToPicName)
    animations = squadOrderAnim
    transform = defTransform
  }
}

let squadOrderArrow = makeArrow({ color=MY_SQUAD_TEXT_COLOR, yOffs=fsh(4), anim = squadOrderAnim })

let squadOrderChildren = freeze([squadOrderIcon, squadOrderArrow])

let ctor = function(...) {
  let watch = localSquadOrder
  return function() {
    let orderPosition = watch.value
    if (orderPosition == null)
      return {watch}

    return {
      watch
      data = {
        minDistance = 0.5
        maxDistance = 10000
        distScaleFactor = 0.3
        worldPos = orderPosition
      }
      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      transform = defTransform
      key = orderPosition
      children = squadOrderChildren
    }
  }
}

return {
  squad_order_ctor = {
    ctor
    watch = null
  }
}