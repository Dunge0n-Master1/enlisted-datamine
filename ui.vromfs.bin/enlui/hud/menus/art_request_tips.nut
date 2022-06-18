import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {currentShellType} = require("artillery_radio_map_shell_type.nut")
let {DEFAULT_TEXT_COLOR, HUD_TIPS_FAIL_TEXT_COLOR} = require("%ui/hud/style.nut")
let {aircraftRequestAvailableTimeLeft} = require("%ui/hud/state/artillery.nut")
let {hintTextFunc} = require("mapComps.nut")
let {secondsToStringLoc} = require("%ui/helpers/time.nut")

let isAircraftRequest = Computed(function() {
  if (!currentShellType.value)
    return false

  let artilleryTemplate = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(currentShellType.value.name)

  return artilleryTemplate?.getCompValNullable("aircraft_request") != null
})

let artRequestTips = @() {
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    watch = [aircraftRequestAvailableTimeLeft]
    children = [
      hintTextFunc(loc("artillery/bombers_cooldown"), DEFAULT_TEXT_COLOR)
      hintTextFunc(secondsToStringLoc(aircraftRequestAvailableTimeLeft.value), HUD_TIPS_FAIL_TEXT_COLOR)
    ]
  }

return {
  isAircraftRequest
  artRequestTips
}
