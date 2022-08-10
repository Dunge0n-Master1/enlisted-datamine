from "%enlSqGlob/ui_library.nut" import *

let {user_points} = require("%ui/hud/state/user_points.nut")

let pinSz = [fsh(1.2), fsh(1.7)]
let images = {
  main_user_point = Picture("!ui/skin#map_pin.svg:{0}:{1}".subst(pinSz[0].tointeger(),pinSz[1].tointeger()))
  enemy_user_point = Picture("!ui/skin#unit_inner.svg:{0}:{1}".subst(pinSz[0].tointeger(),pinSz[1].tointeger()))
}

let pin = memoize(@(pic, color) {
  size = pinSz
  rendObj = ROBJ_IMAGE
  color
  pos = [0, -pinSz[1] * 0.5]
  image = pic
})

let size = [hdpx(12), hdpx(12)]

let function makeUserPoint(eid, data) {
  let dataType = data.type
  if (dataType != "main_user_point" && dataType != "enemy_user_point")
    return null

  let {byLocalPlayer=false} = data
  let color = dataType == "enemy_user_point"
    ? Color(250,50,0,250)
    : byLocalPlayer
        ? Color(250,250,50,250)
        : Color(180,180,250,250)

  return {
    size

    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    transform = {}

    data = {
      eid
      clampToBorder = true
    }

    children = pin(images?[dataType], color)
  }
}

return {
  watch = user_points
  childrenCtor = @() user_points.value.keys().map(memoize(@(eid) makeUserPoint(eid, user_points.value[eid])))
}
