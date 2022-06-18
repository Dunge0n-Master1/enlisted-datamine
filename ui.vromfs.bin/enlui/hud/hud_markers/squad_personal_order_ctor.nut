from "%enlSqGlob/ui_library.nut" import *

let { MY_SQUAD_TEXT_COLOR } = require("%ui/hud/style.nut")
let { ESMO_DEFEND_POINT } = require("ai")
let { makeArrow } = require("%ui/hud/huds/hud_markers/components/hud_markers_components.nut")

let moveToPicSize = [fsh(4), fsh(4)]
let moveToPicName = $"!ui/skin#moveto.svg:{moveToPicSize[0]}:{moveToPicSize[1]}:K"

let squadPersonalOrderAnim = [
  { prop=AnimProp.scale, from=[0.9, 0.9], to=[1.1, 1.1], duration=2, play=true, loop=true, easing=CosineFull }
  { prop=AnimProp.rotate, from=0, to=360, duration=20, play=true, loop=true }
  { prop=AnimProp.opacity, from=0, to=1, duration=0.3, play=true}
  { prop = AnimProp.opacity, from = 0.8, to = 1,
    duration = 2, play = true, loop = true, easing = CosineFull}
]

let squadPersonalOrderIcon = {
  transform = {
    scale = [1, 0.5]
  }
  children = {
    rendObj = ROBJ_IMAGE
    size = moveToPicSize
    pos = [0, 0]
    color = MY_SQUAD_TEXT_COLOR
    image = Picture(moveToPicName)
    animations = squadPersonalOrderAnim
    transform = {}
  }
}

let squadPersonalOrderArrow = makeArrow(
  { color=MY_SQUAD_TEXT_COLOR, yOffs=fsh(4), anim = squadPersonalOrderAnim }
)

let squadPersonalOrderChildren = [squadPersonalOrderIcon, squadPersonalOrderArrow]

let function watchedHeroSquadPersonalOrderCtor(eid, marker) {
  let {orderPosition, orderType} = marker
  if (orderType != ESMO_DEFEND_POINT)
    return null

  return {
    data = {
      minDistance = 0.5
      maxDistance = 10000
      distScaleFactor = 0.3
      worldPos = orderPosition
    }
    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    transform = {}
    key = eid
    sortOrder = eid

    children = squadPersonalOrderChildren
  }
}

return watchedHeroSquadPersonalOrderCtor