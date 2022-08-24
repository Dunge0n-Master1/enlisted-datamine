import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {CONNECTIVITY_OK} = require("connectivity")
/*
local netstats = {
  ping={dim=1, avg=1, min=0 max=1}
  rx={dim=1, avg=1, min=0 max=1}
  tx={dim=1, avg=1, min=0 max=1}
  rx_pps={dim=1, avg=1, min=0 max=1}
  tx_pps={dim=1, avg=1, min=0 max=1}
  ploss={dim=1, avg=1, min=0 max=1}
}
*/

let connectivity = Watched(CONNECTIVITY_OK)

ecs.register_es("hud_network_ui_es", {
  [["onChange", "onInit"]] = function(_eid, comp) {
    connectivity(comp["hud_state__connectivity"])
  }
  onDestroy = @() connectivity(CONNECTIVITY_OK)
  },
  {
    comps_track = [["hud_state__connectivity", ecs.TYPE_INT]]
  }
)

return {
  connectivity
}
