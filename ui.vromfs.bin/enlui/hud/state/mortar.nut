import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let isMortarMode = Watched(false)

ecs.register_es("mortar_mode_ui_es",
  {
    [["onInit", "onChange"]] = @(_eid, comp) isMortarMode(comp["human_weap__mortarMode"])
    function onDestroy() {
      isMortarMode(false)
    }
  },
  {
  comps_track = [
    ["human_weap__mortarMode", ecs.TYPE_BOOL],
  ]
  comps_rq = ["hero","watchedByPlr"]
})

return {
  isMortarMode
}