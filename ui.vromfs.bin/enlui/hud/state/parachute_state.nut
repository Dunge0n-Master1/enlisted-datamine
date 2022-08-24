import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let canOpenParachute = Watched(false)
let isParachuteOpened = Watched(false)

ecs.register_es("human_parachute_track_openable_es",
  {
    [["onInit","onChange"]] = @(_eid, comp) canOpenParachute(comp.human_parachute__canDeploy),
    [["onDestroy"]] = @() canOpenParachute(false)
  },
  {
    comps_track = [["human_parachute__canDeploy", ecs.TYPE_BOOL]]
    comps_rq = ["hero"]
  }
)

ecs.register_es("parachute_track_opened_es",
  {
    [["onInit"]] = @() isParachuteOpened(true),
    [["onDestroy"]] = @() isParachuteOpened(false)
  },
  {
    comps_rq = ["hero", "parachuteDeployed"]
  }
)

return {
  canOpenParachute
  isParachuteOpened
}
