from "%enlSqGlob/ui_library.nut" import *

let { aircraft_markers_Set, aircraft_markers_GetWatched} = require("%ui/hud/state/aircraft_markers.nut")
let {controlledVehicleEid} = require("%ui/hud/state/vehicle_state.nut")
let {MAP_COLOR_TEAMMATE, MAP_COLOR_ENEMY, MAP_COLOR_UNIDENTIFIED} = require("%enlSqGlob/ui/style/unit_colors.nut")
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")

let iconSz = [fsh(1.4), fsh(1.4)].map(@(v) v.tointeger())
let iconImg = Picture("!ui/skin#aircraft_icon.svg:{0}:{1}:K".subst(iconSz[0], iconSz[1]))

let heroColor = Color(200,200,0,250)

let function mkAircraftMapMarker(eid) {
  let isHeroPlane = Computed(@() controlledVehicleEid.value == eid)
  let state = aircraft_markers_GetWatched(eid)
  let data = freeze({
    eid
    minDistance = 0.7
    maxDistance = 2000
    clampToBorder = false
    dirRotate = true
  })
  let isFriendly = Computed(@() state.value?.team == localPlayerTeam.value)
  let colorState = Computed(@() isHeroPlane.value
            ? heroColor
            : !state.value.isIdentified
              ? MAP_COLOR_UNIDENTIFIED
              : isFriendly.value
                ? MAP_COLOR_TEAMMATE
                : MAP_COLOR_ENEMY
             )
  return function() {
    return {
      data
      transform = {}
      children = {
        rendObj = ROBJ_IMAGE
        size = iconSz
        color = colorState.value
        image = iconImg
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        transform = {
          rotate=45.0
        }
      }
      watch = colorState
    }
  }
}

let memoizedMap = mkMemoizedMapSet(mkAircraftMapMarker)
return {
  watch = aircraft_markers_Set
  ctor = @(_) memoizedMap(aircraft_markers_Set.value).values()
}