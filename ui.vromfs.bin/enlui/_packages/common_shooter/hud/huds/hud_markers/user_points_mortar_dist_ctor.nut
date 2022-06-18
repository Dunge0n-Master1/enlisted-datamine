from "%enlSqGlob/ui_library.nut" import *

let {isMortarMode} = require("%ui/_packages/common_shooter/hud/state/mortar.nut")

let textSize = calc_str_box("1234")

return {
  user_point_mortar_dist_ctor = @(eid, _) @(){
    watch = isMortarMode
    transform = {}
    pos = [0, sh(1)]
    data = { eid = eid }
    children = !isMortarMode.value ? null : [{
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      halign = ALIGN_CENTER
      targetEid = eid
      rendObj = ROBJ_TEXT
      color = Color(200,50,50,250)
      behavior = [Behaviors.DistToEntity]
      size = textSize
      markerFlags = MARKER_KEEP_SCALE
    }]
  }
}
