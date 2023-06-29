import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let zoneTitle = Watched("")
let zoneCanBeAttacked = Watched(false)
let zoneCanBeDefended = Watched(false)

ecs.register_es("set_capture_zone_title_es", {
  [["onInit", "onChange"]] = function(_eid, comp) {
    zoneTitle(comp.human__lookAtZoneQuickchatTitle)
    zoneCanBeAttacked(comp.human__lookAtZoneQuickchatCanBeAttacked)
    zoneCanBeDefended(comp.human__lookAtZoneQuickchatCanBeDefended)
  },
},
{
  comps_ro = [
    ["human__lookAtZoneQuickchatTitle", ecs.TYPE_STRING],
  ]
  comps_track = [
    ["human__lookAtZoneQuickchat", ecs.TYPE_EID],
    ["human__lookAtZoneQuickchatCanBeAttacked", ecs.TYPE_BOOL],
    ["human__lookAtZoneQuickchatCanBeDefended", ecs.TYPE_BOOL],
  ],
  comps_rq = [
    ["hero"]
  ]
}
)

return {
  zoneTitle,
  zoneCanBeAttacked,
  zoneCanBeDefended
}
