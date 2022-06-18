from "%enlSqGlob/ui_library.nut" import *

let { get_video_modes } = require("videomode")
let { monitorValue } = require("monitor_state.nut")
let { get_primary_screen_info } = require("dagor.system")
let platform = require("%dngscripts/platform.nut")

let function getResolutions(monitor) {
  let res = get_video_modes(monitor)

  // Fixing the truncated list when working via Remote Desktop.
  if (platform.is_windows && res.list.len() <= 2) {
    let newList = res.list.filter(@(v) type(v) == "array")
    local maxRes = newList?[newList.len() - 1]
    if (maxRes == null) {
      try {
        let { pixelsWidth, pixelsHeight } = get_primary_screen_info()
        maxRes = [ pixelsWidth, pixelsHeight ]
      }
      catch(e) { // Avoids testbuilder fail while running Linux csq binary with param win32
        return res
      }
    }
    let resolutions = [ [1024,768], [1280,720], [1280,1024], [1920,1080], [1920,1200],
      [2520,1080], [2560,1440], [3840,1080], [3840,2160] ]
        .filter(@(v) newList.findvalue(@(r) r[0] == v[0] && r[1] == v[1]) == null
          && v[0] <= maxRes[0] && v[1] <= maxRes[1])
    newList.extend(resolutions)
    newList.sort(@(a, b) a[0] <=> b[0]  || a[1] <=> b[1])
    newList.insert(0, "auto")
    res.list = newList
  }

  return res
}

// load it from blk on init
local availableResolutions = getResolutions(monitorValue.value)

let resolutionList = Watched(availableResolutions.list)
let resolutionValue = Watched(availableResolutions.current)

monitorValue.subscribe(function(_val){
  availableResolutions = getResolutions(monitorValue.value)
  resolutionList(availableResolutions.list)
  resolutionValue("auto")
})

return {
  resolutionList
  resolutionValue
}