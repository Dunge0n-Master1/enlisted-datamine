import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { inPlane } = require("%ui/hud/state/vehicle_state.nut")

const DEFAULT_PLANE_MAP_RADIUS = 2500
const DEFAULT_GROUND_MAP_RADIUS = 350

let bigmapDefaultVisibleRadius = Watched(DEFAULT_GROUND_MAP_RADIUS)
let function updateMapDefaultVisibleRadius(...) {
  bigmapDefaultVisibleRadius(inPlane.value ? DEFAULT_PLANE_MAP_RADIUS : DEFAULT_GROUND_MAP_RADIUS)
}
updateMapDefaultVisibleRadius()
ecs.register_es("set_bigmap_default_visible_radius_es",
  { onInit = updateMapDefaultVisibleRadius },
  { comps_rq = ["level"] }
)

inPlane.subscribe(updateMapDefaultVisibleRadius)

return {
  bigmapDefaultVisibleRadius
}
