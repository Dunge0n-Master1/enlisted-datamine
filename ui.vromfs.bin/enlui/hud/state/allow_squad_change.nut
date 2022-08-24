import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let allowChangeSquad = Watched(false)
let armyData = require("%ui/hud/state/armyData.nut")

ecs.register_es("allow_squad_change_state_es", {
    onInit    = @(_evt, _eid, _comp) allowChangeSquad.update(true)
    onDestroy = @(_evt, _eid, _comp) allowChangeSquad.update(false)
  },
  { comps_rq = ["allowChangeSquad"] }
)

let isChangeSquadAllowed = Computed(@() allowChangeSquad.value
  && (armyData.value?.squads.len() ?? 0) > 1)

return isChangeSquadAllowed