from "%enlSqGlob/ui_library.nut" import *

let { MY_SQUAD_TEXT_COLOR } = require("%ui/hud/style.nut")
let { SquadMateOrder } = require("%enlSqGlob/dasenums.nut")
let { makeArrow } = require("%ui/hud/hud_markers/components/hud_markers_components.nut")
let { watchedHeroSquadPersonalOrdersSet, watchedHeroSquadPersonalOrdersGetWatched } = require("%ui/hud/state/squad_personal_orders.nut")

let moveToPicSize = array(2, hdpxi(43))
let moveToPicName = $"!ui/skin#moveto.svg:{moveToPicSize[0]}:{moveToPicSize[1]}:K"

let squadPersonalOrderAnim = [
  { prop=AnimProp.scale, from=[0.9, 0.9], to=[1.1, 1.1], duration=2, play=true, loop=true, easing=CosineFull }
  { prop=AnimProp.rotate, from=0, to=360, duration=20, play=true, loop=true }
  { prop=AnimProp.opacity, from=0, to=1, duration=0.3, play=true}
  { prop = AnimProp.opacity, from = 0.8, to = 1,
    duration = 2, play = true, loop = true, easing = CosineFull}
]

let squadPersonalOrderIcon = freeze({
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
})

let squadPersonalOrderArrow = makeArrow(
  { color=MY_SQUAD_TEXT_COLOR, yOffs=fsh(4), anim = squadPersonalOrderAnim }
)

let squadPersonalOrderChildren = [squadPersonalOrderIcon, squadPersonalOrderArrow]

let ctor = function(eid) {
  let watch = watchedHeroSquadPersonalOrdersGetWatched(eid)

  return function() {
    let { orderType, orderPosition } = watch.value
    if ( orderType != SquadMateOrder.ESMO_DEFEND_POINT )
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
      transform = {}
      key = eid
      sortOrder = eid

      children = squadPersonalOrderChildren
    }
  }
}

let memoizedMap = mkMemoizedMapSet(ctor)
return {
  watched_hero_squad_personal_orders_ctor = {
    watch = watchedHeroSquadPersonalOrdersSet
    ctor = @() memoizedMap(watchedHeroSquadPersonalOrdersSet.value).values()
  }
}