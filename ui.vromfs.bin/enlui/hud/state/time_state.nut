from "%enlSqGlob/ui_library.nut" import *

let {get_sync_time} = require("net")
let curTime = Watched(0.0)

gui_scene.setInterval(1.0/60.0, @() curTime(get_sync_time()))
let curTimePerSec = Computed(@() (curTime.value+0.5).tointeger())

return {
  curTime
  curTimePerSec
}
