from "%enlSqGlob/ui_library.nut" import *

let {localPlayerEid} = require("%ui/hud/state/local_player.nut")
let {squad_orders} = require("%ui/hud/state/squad_orders.nut")
let {MY_SQUAD_TEXT_COLOR} = require("%ui/hud/style.nut")
let {ESO_DEFEND_POINT} = require("ai")
let moveto = Picture("!ui/skin#moveto.svg")

let persistentColor = Color(64, 64, 255, 255)

let animations = [
  { prop=AnimProp.scale, from=[4,4], to=[1,1], duration=0.3, play=true}
  { prop=AnimProp.scale, from=[0.9, 0.9], to=[1.1, 1.1], duration=2, play=true, loop=true, easing=CosineFull }
  { prop=AnimProp.rotate, from=0, to=360, duration=20, play=true, loop=true }
  { prop=AnimProp.scale, from=[4,4], to=[1,1], duration=0.3, play=true}
  { prop=AnimProp.opacity, from=0, to=1, duration=0.3, play=true}
]

let minimapSquadOrders = Computed(function() {
  let orders = squad_orders.value
  let playerEid = localPlayerEid.value
  let components = []
  foreach (eid, orderData in orders) {
    if (eid != playerEid)
      continue
    let persistent = orderData?.persistent
    if (orderData.orderType == ESO_DEFEND_POINT) {
      let size = [fsh(2.5), fsh(2.5)]
      let orderIcon = {
        rendObj = ROBJ_IMAGE
        image = moveto
        size = size
        color = persistent ? persistentColor : MY_SQUAD_TEXT_COLOR
        transform = { pivot = [0.5, 0.5] }
        key = eid
        animations = persistent ? null : animations
      }
      components.append({
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        data = {
          worldPos = orderData.orderPosition
          clampToBorder = true
        }
        transform = {}
        children = orderIcon
      })
    }
  }
  return components
})


return {
  watch = minimapSquadOrders
  ctor = @(_) minimapSquadOrders.value
}
