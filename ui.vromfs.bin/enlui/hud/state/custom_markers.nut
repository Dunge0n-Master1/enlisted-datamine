import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")
let { custom_markers, custom_markersSetKeyVal, custom_markersDeleteKey } = mkFrameIncrementObservable({}, "custom_markers")

ecs.register_es(
  "ui_custom_markers_state",
  {
    [["onInit", "onChange"]] = function(eid, comp) {
      if (comp.custom_marker__active)
        custom_markersSetKeyVal(eid, {
          icon = comp.custom_marker__icon
          size = comp.custom_marker__iconSize
          color = comp.custom_marker__iconColor
        })
      else
        custom_markersDeleteKey(eid)
    },
    onDestroy = @(eid, _comp) custom_markersDeleteKey(eid)
  },
  {
    comps_track = [
      ["custom_marker__active", ecs.TYPE_BOOL],
      ["custom_marker__icon", ecs.TYPE_STRING],
      ["custom_marker__iconSize", ecs.TYPE_POINT2],
      ["custom_marker__iconColor", ecs.TYPE_COLOR],
    ]
  }
)

return custom_markers
