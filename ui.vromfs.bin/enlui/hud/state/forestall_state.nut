import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let Point3 = require("dagor.math").Point3

let forestallMarkActive = Watched(false)
let forestallMarkPos = Watched(Point3(0, 0, 0))
let forestallMarkOpacity = Watched(1.0)

let function updateForestallPos(_eid, comp) {
  forestallMarkActive.update(comp["target_lock__selectedEntity"] != ecs.INVALID_ENTITY_ID)
  forestallMarkPos.update(comp["forestallPos"])
  forestallMarkOpacity.update(comp["forestallOpacity"])
}

let function hideForestallMark() {
  forestallMarkActive.update(false)
}

ecs.register_es("forestall_mark_ui_es", {
    [["onInit", "onChange"]] = updateForestallPos,
    [ecs.EventComponentsDisappear] = hideForestallMark,
  },
  { comps_track = [
      ["forestallPos", ecs.TYPE_POINT3],
      ["forestallOpacity", ecs.TYPE_FLOAT],
      ["target_lock__selectedEntity", ecs.TYPE_EID]
    ],
    comps_rq = ["heroVehicle"]
  },
  { tags="gameClient"}
)

return {
  forestallMarkActive
  forestallMarkPos
  forestallMarkOpacity
}
