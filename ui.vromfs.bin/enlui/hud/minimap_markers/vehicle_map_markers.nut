from "%enlSqGlob/ui_library.nut" import *

let { vehicle_markers_Set, vehicle_markers_GetWatched } = require("%ui/hud/state/vehicle_markers.nut")
let { controlledVehicleEid } = require("%ui/hud/state/vehicle_state.nut")
let { MAP_COLOR_TEAMMATE, MAP_COLOR_SQUADMATE, MAP_COLOR_GROUPMATE
} = require("%enlSqGlob/ui/style/unit_colors.nut")

let iconSz = array(2, hdpxi(15))
let mkIcon = memoize(@(icon) (icon ?? "") != ""
  ? Picture("!ui/skin#{0}.svg:{1}:{2}:K".subst(icon, iconSz[0], iconSz[1]))
  : null)

let mkData = @(eid) freeze({
    eid
    minDistance = 0.7
    maxDistance = 2000
    clampToBorder = false
})

let transform = freeze({ rotate = -90 })

let function mkMarker(eid) {
  let data = mkData(eid)
  let markerState = vehicle_markers_GetWatched(eid)
  let watch = [markerState, controlledVehicleEid]

  return function() {
    let { isEmpty, hasSquadmates=null, hasGroupmates=null, icon=null } = markerState.value
    if (hasGroupmates==null || controlledVehicleEid.value == eid || isEmpty)
      return { watch }
    return {
      data
      watch
      transform = {}
      children = {
        rendObj = ROBJ_IMAGE
        size = iconSz
        color = hasSquadmates ? MAP_COLOR_SQUADMATE
              : hasGroupmates ? MAP_COLOR_GROUPMATE
              : MAP_COLOR_TEAMMATE
        image = mkIcon(icon)
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        transform
      }
    }
  }
}

let memoizedMap = mkMemoizedMapSet(mkMarker)
return {
  watch = vehicle_markers_Set
  ctor = @(_) memoizedMap(vehicle_markers_Set.value).values()
}