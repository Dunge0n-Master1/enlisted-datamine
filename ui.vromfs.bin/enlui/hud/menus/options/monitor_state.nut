from "%enlSqGlob/ui_library.nut" import *


let { get_available_monitors, get_monitor_info } = require("videomode")

let availableMonitors = get_available_monitors()

let monitorValue = Watched(availableMonitors.current)

let get_friendly_monitor_name = function(v) {
  let monitor_info = get_monitor_info(v)
  if (!monitor_info)
    return v

  let hdr_string = monitor_info?[2]
    ? (" ({0})".subst(loc("option/hdravailable", "HDR is available")))
    : ""
  return $"{monitor_info[0]} [#{monitor_info[1] + 1}]{hdr_string}"
}

return {
  availableMonitors
  monitorValue
  get_friendly_monitor_name
}