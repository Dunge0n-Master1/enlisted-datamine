from "%enlSqGlob/ui_library.nut" import *

let { tutorialZones } = require("%ui/hud/tutorial/state/tutorial_zones_state.nut")

let icons = {
  waypoint = {
    image = Picture($"!ui/skin#waypoint_tutorial.svg:{hdpxi(16)}:{hdpxi(16)}:K")
    size = [hdpxi(16), hdpxi(16)]
  }
}

let map_zone_pointer_ctor = @(eid, comp) function() {
  let { image, size } = icons?[comp.tutorial_zone__icon] ?? icons.waypoint
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
        image
        size
        pos = [0, -size[1] * 0.15]
    }
  }
}

return {
  tutorialZoneMarkers = {
    watch = tutorialZones
    ctor = @(_p) tutorialZones.value.reduce(@(res, comp, eid) res.append(map_zone_pointer_ctor(eid, comp)), [])
  }
}
