import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let customProfilePath = Watched(null)

ecs.register_es("ui_custom_profile_state_es", {
    onInit    = @(_eid, comp) customProfilePath.update(comp["customProfile"])
    onDestroy = @(_eid, _comp) customProfilePath.update(null)
  },
  { comps_ro = [["customProfile", ecs.TYPE_STRING]] }
)

return {
  customProfilePath
}