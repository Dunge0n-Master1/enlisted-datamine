from "%enlSqGlob/ui_library.nut" import *

let {DBGLEVEL} = require("dagor.system")
let sessionId = require("%ui/hud/huds/session_id.ui.nut")
let {fpsBar, latencyBar} = require("fpsBar.nut")
let platform = require("%dngscripts/platform.nut")

let showFps = mkWatched(persist, "showFps", false)

let showService = Computed(@() platform.is_pc || DBGLEVEL>0 || showFps.value)
let function serviceInfo() {
  let children = showService.value ? [fpsBar, latencyBar] : []
  if (platform.is_pc || platform.is_xbox)
    children.append(sessionId)
  return {
    children
    flow = FLOW_HORIZONTAL
    vplace = ALIGN_BOTTOM
    gap = hdpx(5)
    padding = [hdpx(2), hdpx(10)]
    watch = showService
  }
}
return {serviceInfo, fpsBar, latencyBar, showFps}