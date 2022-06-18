from "%enlSqGlob/ui_library.nut" import *

let { ceil } = require("math")
let { tutorialZones } = require("%ui/hud/tutorial/state/tutorial_zones_state.nut")

let zonePointerArrowSz = [fsh(1.2), fsh(1.2)]
let zonePointerArrow = Picture("!ui/skin#waypoint_tutorial.svg:{0}:{1}:K".subst(
    ceil(zonePointerArrowSz[0]*1.3).tointeger(), ceil(zonePointerArrowSz[1]*1.3).tointeger()))

let map_zone_pointer_ctor = @(eid) function() {
  return {
    key = eid
    data = {
      eid = eid
    }
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    transform = {
      rotate = -90
    }
    children = {
        rendObj = ROBJ_IMAGE
        color = Color(255, 255, 255)
        image = zonePointerArrow
        size = SIZE_TO_CONTENT
        pos = [0, -zonePointerArrowSz[1] * 0.2]
    }
  }
}

return {
  tutorialZoneMarkers = {
    watch = tutorialZones
    ctor = @(_p) tutorialZones.value.reduce(@(res, _info, eid) res.append(map_zone_pointer_ctor(eid)), [])
  }
}
