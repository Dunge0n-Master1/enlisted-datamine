from "%enlSqGlob/ui_library.nut" import *

let {isMortarMode} = require("%ui/hud/state/mortar.nut")
let { user_points } = require("%ui/hud/state/user_points.nut")

let textSize = calc_str_box("1234")

let mortar = memoize(function(eid){
  return {
    transform = {}
    pos = [0, sh(1)]
    data = { eid }
    children = {
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      halign = ALIGN_CENTER
      targetEid = eid
      rendObj = ROBJ_TEXT
      color = Color(200,50,50,250)
      behavior = Behaviors.DistToEntity
      size = textSize
      markerFlags = MARKER_KEEP_SCALE
    }
  }
})
return {
  user_point_mortar_dist_ctor = {
    watch = [user_points, isMortarMode]
    ctor = @() !isMortarMode.value ? [] : user_points.value.keys().map(mortar)
  }
}
