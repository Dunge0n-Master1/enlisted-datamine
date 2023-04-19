import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let showPlayerHuds = require("%ui/hud/state/showPlayerHuds.nut")


let canGrenadeRethrow = Watched(false)
let showGrenadeRethrowTip = Computed(@() showPlayerHuds.value && canGrenadeRethrow.value)


ecs.register_es("can_grenade_rethrow_track_ui",
  {
    [["onInit", "onChange"]] = @(_, comp) canGrenadeRethrow(comp.grenade_rethrow__grenadeEid),
    onDestroy = @() canGrenadeRethrow(false)
  },
  {
    comps_rq=["watchedByPlr"]
    comps_track=[["grenade_rethrow__grenadeEid", ecs.TYPE_EID]]
  }
)


return { showGrenadeRethrowTip }
