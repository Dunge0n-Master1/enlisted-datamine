from "%enlSqGlob/ui_library.nut" import *

let {take_screenshot_nogui, take_screenshot} = require("screencap")
let voiceHotkeys = require("%enlSqGlob/voiceControl.nut")

let eventHandlers = {
    ["Global.Screenshot"] = @(...) take_screenshot(),
    ["Global.ScreenshotNoGUI"] = @(...) take_screenshot_nogui()
  }
foreach (k, v in voiceHotkeys.eventHandlers)
  eventHandlers[k] <- v

return { eventHandlers = eventHandlers }
