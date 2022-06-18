from "%enlSqGlob/ui_library.nut" import *

let {friendly_vehicle_markers} = require("%ui/hud/state/vehicle_markers.nut")
let {controlledVehicleEid} = require("%ui/hud/state/vehicle_state.nut")
let {MAP_COLOR_TEAMMATE, MAP_COLOR_SQUADMATE, MAP_COLOR_GROUPMATE} = require("%enlSqGlob/ui/style/unit_colors.nut")

let iconSz = [fsh(1.4), fsh(1.4)].map(@(v) v.tointeger())
let mkIcon = @(icon) icon != null ? Picture("!ui/skin#{0}.svg:{1}:{2}:K".subst(icon, iconSz[0].tointeger(), iconSz[1].tointeger()))
                                    : null

let function mkMarker(eid, marker, _options = null) {
  let {isEmpty, hasSquadmates, hasGroupmates} = marker

  return @() (isEmpty || controlledVehicleEid.value == eid) ? null : {
    data = {
      eid = eid
      minDistance = 0.7
      maxDistance = 2000
      clampToBorder = false
    }
    transform = {}
    children = [{
      rendObj = ROBJ_IMAGE
      size = iconSz
      color = hasSquadmates ? MAP_COLOR_SQUADMATE
            : hasGroupmates ? MAP_COLOR_GROUPMATE
            : MAP_COLOR_TEAMMATE
      image = mkIcon(marker?.icon)
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = {rotate=-90}
    }]
    watch=[controlledVehicleEid]
  }
}

return {
  watch = friendly_vehicle_markers
  ctor = @(p) friendly_vehicle_markers.value.reduce(@(res, info, eid) res.append(mkMarker(eid, info, p)), [])
}