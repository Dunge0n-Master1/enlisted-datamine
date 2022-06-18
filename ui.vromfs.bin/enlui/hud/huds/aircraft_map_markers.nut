from "%enlSqGlob/ui_library.nut" import *

let {aircraft_markers} = require("%ui/hud/state/aircraft_markers.nut")
let {controlledVehicleEid} = require("%ui/hud/state/vehicle_state.nut")
let {MAP_COLOR_TEAMMATE, MAP_COLOR_ENEMY, MAP_COLOR_UNIDENTIFIED} = require("%enlSqGlob/ui/style/unit_colors.nut")

let iconSz = [fsh(1.4), fsh(1.4)].map(@(v) v.tointeger())
let iconImg = Picture("!ui/skin#aircraft_icon.svg:{0}:{1}:K".subst(iconSz[0].tointeger(), iconSz[1].tointeger()))

let heroColor = Color(200,200,0,250)

let function mkAircraftMapMarker(eid, marker, _options = null) {
  let isHeroPlane = Computed(@() controlledVehicleEid.value == eid)
  let {isIdentified, isFriendly} = marker

  return @() {
    data = {
      eid = eid
      minDistance = 0.7
      maxDistance = 2000
      clampToBorder = false
      dirRotate = true
    }
    transform = {}
    children = [{
      rendObj = ROBJ_IMAGE
      size = iconSz
      color = isHeroPlane.value ? heroColor
            : !isIdentified ? MAP_COLOR_UNIDENTIFIED
            : isFriendly ? MAP_COLOR_TEAMMATE
            : MAP_COLOR_ENEMY
      image = iconImg
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = {
        rotate=45.0
      }
    }]
    watch=[isHeroPlane]
  }
}

return {
  watch = aircraft_markers
  ctor = @(p) aircraft_markers.value.reduce(@(res, info, eid) res.append(mkAircraftMapMarker(eid, info, p)), [])
}