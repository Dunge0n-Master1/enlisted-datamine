from "%enlSqGlob/ui_library.nut" import *

let get_time_msec = require("dagor.time").get_time_msec
let cTime = Watched(0)
let function updateCtime(){
  cTime((get_time_msec()/1000).tointeger())
}
gui_scene.setInterval(1, updateCtime)

return {
  curTimePerSec = cTime
}