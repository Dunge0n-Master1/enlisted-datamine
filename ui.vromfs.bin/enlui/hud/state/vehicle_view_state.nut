import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let comps = freeze([
  {comp = "vehicle_view__isAutomaticTransmission", typ = ecs.TYPE_BOOL,def=false,name="isAutomaticTransmission"}
  {comp = "vehicle_view__gear",                    typ = ecs.TYPE_INT, def=0,    name="gear"}
  {comp = "vehicle_view__neutralGear",             typ = ecs.TYPE_INT, def=0,    name="neutralGear"}
  {comp = "vehicle_view__rpm",                     typ = ecs.TYPE_INT, def=0,    name="rpm"}
  {comp = "vehicle_view__cruiseControl",           typ = ecs.TYPE_INT, def=0,    name="cruiseControl"}
  {comp = "vehicle_view__speed",                   typ = ecs.TYPE_INT, def=0,    name="speed"}
])

let state = comps.reduce(function(a,b) {
  a[b.name]<-Watched(b.def)
  return a
}, {})

ecs.register_es("ui_vehicle_view_state",
  {
    [["onInit","onChange"]] = function(_, comp){
      comps.each(@(v) state[v.name](comp[v.comp]))
    }
    function onDestroy(_, __){
      comps.each(@(v) state[v.name](v.def))
    }
  },
  {
    comps_track = comps.map(@(obj) [obj.comp, obj.typ, obj.name]),
    comps_rq = ["isTank", "vehicleWithWatched"] // only needed for tanks now
    comps_no = ["deadEntity"]
  },
  { tags="ui" }
)

return state