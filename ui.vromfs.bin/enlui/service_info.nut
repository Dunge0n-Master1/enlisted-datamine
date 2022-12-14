from "%enlSqGlob/ui_library.nut" import *

let {DBGLEVEL} = require("dagor.system")
let sessionId = require("%ui/hud/huds/session_id.ui.nut")
let {fpsBar, latencyBar} = require("fpsBar.nut")
let platform = require("%dngscripts/platform.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")
let { canShowGameHudInReplay } = require("%ui/hud/replay/replayState.nut")

let showFps = mkWatched(persist, "showFps", false)

let showService = Computed(@() !(isReplay.value && !canShowGameHudInReplay.value)
  && (platform.is_pc || DBGLEVEL>0 || showFps.value))
let function serviceInfo() {
  let children = showService.value ? [fpsBar, latencyBar] : []
  if (platform.is_pc || platform.is_xbox)
    children.append(sessionId)
  return {
    watch = showService
    flow = FLOW_HORIZONTAL
    gap = hdpx(5)
    vplace = DBGLEVEL > 0 ? ALIGN_TOP : ALIGN_BOTTOM
    padding = [hdpx(2), hdpx(10)]
    children
  }
}
return {serviceInfo, fpsBar, latencyBar, showFps}