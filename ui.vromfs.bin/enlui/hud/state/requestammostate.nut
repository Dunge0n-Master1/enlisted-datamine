import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {mkCountdownTimerPerSec} = require("%ui/helpers/timers.nut")

let requestAmmoAllowTime = Watched(0.0)
let requestAmmoTimeout = mkCountdownTimerPerSec(requestAmmoAllowTime)

ecs.register_es("hero_ammo_request_ui_es",
  {
    [["onInit", "onChange"]] = @(_eid, comp) requestAmmoAllowTime(comp["requestAmmoAllowTime"])
  },
  { comps_track = [["requestAmmoAllowTime", ecs.TYPE_FLOAT]] }
)

return {
  requestAmmoTimeout = requestAmmoTimeout
}