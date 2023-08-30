from "%enlSqGlob/ui_library.nut" import *
let {logerr} = require("dagor.debug")

require("%ui/ui_config.nut")
require("%ui/sound_handlers.nut")
let {msgboxes} = require("%ui/msgboxes.nut")
let {uiDisabled, levelLoaded} = require("%ui/hud/state/appState.nut")
let {loadingUI, showLoading} = require("%ui/loading/loading.nut")
let globInput = require("%ui/glob_input.nut")
let { hotkeysButtonsBar } = require("%ui/hotkeysPanel.nut")
let {modalWindowsComponent} = require("%ui/components/modalWindows.nut")
let platform = require("%dngscripts/platform.nut")
let {editorActivness, uiInEditor} = require("%enlSqGlob/editorState.nut")
let {serviceInfo} = require("%ui/service_info.nut")
let {canShowReplayHud, canShowGameHudInReplay} = require("%ui/hud/replay/replayState.nut")
let {isReplay} = require("%ui/hud/state/replay_state.nut")

local hud
try{
  hud = require("hud.nut")
}
catch(e){
  log(e)
  logerr("errr loading hud.nut")
}

require("dainput2").set_double_click_time(220)

if (platform.is_xbox || platform.is_sony)
  require("%ui/invitation/onInviteAccept.nut")

let function root() {

  local content
  if (uiDisabled.value) {
    content = null
  }
  else if (showLoading.value || !levelLoaded.value) {
    content = loadingUI
  }
  else {
    content = hud
  }

  local children = !uiDisabled.value
    ? [
        content
        modalWindowsComponent
        msgboxes
        hotkeysButtonsBar
        globInput
      ]
    : [ content ]


  if (editorActivness.value && !uiInEditor.value)
    children = [globInput]

  if (!uiDisabled.value && levelLoaded.value)
    children.append(serviceInfo)
  if (isReplay.value) {
    let idxToRemove = children.findindex(@(v) v == hotkeysButtonsBar)
    if (idxToRemove != null)
      children.remove(idxToRemove)
    children.append({
      eventHandlers = {
        ["Replay.DisableHUD"] = @(_event) canShowReplayHud(!canShowReplayHud.value),
        ["Replay.DisableGameHUD"] = @(_event) canShowGameHudInReplay(!canShowGameHudInReplay.value)
      }
    })
  }

  return {
    watch = [showLoading, uiDisabled, editorActivness, uiInEditor, levelLoaded, isReplay]
    size = flex()
    children
  }
}

return root
