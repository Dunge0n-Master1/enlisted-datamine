import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let forcedMinimalHud = Watched(false)

let noBotsModeHud = Watched(false)

ecs.register_es("forcedMinimalHud_es", {
    onInit = @(_eid, _comp) forcedMinimalHud(true)
    onDestroy = @(_eid, _comp) forcedMinimalHud(false)
  },
  { comps_rq = ["forceMinimalHud"] }
)

ecs.register_es("noBotsModeHud_es", {
    onInit = @(_eid, _comp) noBotsModeHud(true)
    onDestroy = @(_eid, _comp) noBotsModeHud(false)
  },
  { comps_rq = ["noBotsMode"] }
)

return {
  forcedMinimalHud
  noBotsModeHud
}