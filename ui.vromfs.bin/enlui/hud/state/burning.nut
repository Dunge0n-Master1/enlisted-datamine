import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let def = {
  isPuttingOut = false
  force = 0.0
  maxForce = 0.0
}
let burningState = Watched(def)

let function trackComponents(_eid, comp) {
  burningState({
    force = comp["burning__force"]
    isPuttingOut = comp["burning__isPuttingOut"]
    maxForce = comp["burning__maxForce"]
  })
}

ecs.register_es("burning_state_ui_es",
  {
    [["onInit", "onChange"]] = trackComponents
    onDestroy = @(...) burningState(def),
  },
  {
    comps_ro = [
      ["burning__maxForce", ecs.TYPE_FLOAT],
    ]
    comps_track = [
      ["burning__force", ecs.TYPE_FLOAT],
      ["burning__isPuttingOut", ecs.TYPE_BOOL]
    ]
    comps_rq = ["hero"],
    comps_no = ["deadEntity"]
  }
)

return burningState