import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let showFuel = Watched(false)
let showFuelIfLessPct = Watched(10.0)

let function checkFuelLevel(_evt, _eid, comp) {
  let fuelPct = comp["plane_view__fuel_pct"]
  let isLeaking = comp["plane_view__fuel_leak"]
  showFuel(isLeaking || fuelPct < showFuelIfLessPct.value)
}

ecs.register_es("plane_fuel_es", {
  onUpdate = checkFuelLevel
},
{
  comps_ro = [
    ["plane_view__fuel_pct", ecs.TYPE_FLOAT],
    ["plane_view__fuel_leak", ecs.TYPE_BOOL],
  ],
  comps_rq = ["vehicleWithWatched"]
},
{ updateInterval=5.0, tags="ui", after="*", before="*" })

return {showFuel}