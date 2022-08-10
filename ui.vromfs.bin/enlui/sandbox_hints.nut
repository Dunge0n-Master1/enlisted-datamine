from "%enlSqGlob/ui_library.nut" import *
from "%darg/laconic.nut" import *

let mkWindow = require("%daeditor/components/window.nut")
let textButton = require("%daeditor/components/textButton.nut")
let checkbox = require("%ui/components/checkbox.nut")
let entity_editor = require_optional("entity_editor")
let {editorIsActive} = require("%ui/editor.nut")


let hintShown = Watched(false)
let hintMessage = Watched("")
let hintWarning = Watched(false)
local hintCb = @() null

let hintStep = mkWatched(persist, "hintStep", 0)

let hintWelcomeKeepShowing = Watched(true)
const SETTING_EDITOR_WELCOME_HINT = "daEditor4/sandboxWelcomeHint"
let { save_settings=null, get_setting_by_blk_path=null, set_setting_by_blk_path=null } = require_optional("settings")
hintWelcomeKeepShowing(get_setting_by_blk_path?(SETTING_EDITOR_WELCOME_HINT) ?? true)
hintWelcomeKeepShowing.subscribe(function(v) {
  set_setting_by_blk_path?(SETTING_EDITOR_WELCOME_HINT, v)
  save_settings?()
})


let hintWindow = mkWindow({
  id = "editor_hint_window"
  windowStyle = {fillColor = Color(40,40,40,120)}
  initialSize = [sw(32), sh(26)]
  minSize     = [sw(32), sh(26)]
  maxSize     = [sw(32), sh(26)]
  content = @() {
    flow  = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    gap  = hdpx(2)
    watch = hintMessage
    halign = ALIGN_CENTER
    children = [
      hflow( Gap(hdpx(5)), VACenter, Size(flex(), SIZE_TO_CONTENT), Padding(hdpx(5),hdpx(5)), RendObj(ROBJ_SOLID), Colr(60,60,90),
        txt(!hintWarning.value ? "Sandbox" : "Sandbox Warning"),
        hintStep.value == 1 ? { size = [flex(), SIZE_TO_CONTENT] } : null,
        hintStep.value == 1 ? checkbox(hintWelcomeKeepShowing, {text = "Show at startup"}) : null
      )
      {
        size = [sw(30), sh(15)]
        children = {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          size = [flex() , SIZE_TO_CONTENT]
          padding = [hdpx(4), hdpx(3)]
          margin = [hdpx(30), 0]
          color = Color(255,255,255)
          text = hintMessage.value
          valign = ALIGN_TOP
        }
      }
      textButton("Continue", function() {
        hintShown(false)
        gui_scene.resetTimeout(0.3, @() hintCb())
      }, {hotkeys = [["Esc"]]})
    ]
  }
})

let function showHintMessage(text, callback=@() null) {
  hintMessage(text)
  hintWarning(false)
  hintShown(true)
  hintShown.trigger()
  hintCb = callback
}

let function showHintWarning(text, callback=@() null) {
  hintMessage(text)
  hintWarning(true)
  hintShown(true)
  hintShown.trigger()
  hintCb = callback
}


let function showHintCheckRespawns() {
  if (!editorIsActive.value || hintStep.value != 2)
    return
  local has_respawns = entity_editor?.get_instance()?.checkSceneEntities("respbase") ?? false
  hintStep(-1)
  if (!has_respawns)
    showHintWarning("Mission is missing respawn points.\n\nPlease, add at least one Mission respawn point.")
}

let function showHintCheckTeams() {
  if (!editorIsActive.value || hintStep.value != 1)
    return
  local has_teams  = entity_editor?.get_instance()?.checkSceneEntities("teamTag") ?? false
  hintStep(2)
  if (!has_teams)
    showHintWarning("Mission is missing players teams.\n\nPlease, add at least one Mission team.", showHintCheckRespawns)
  else
    showHintCheckRespawns()
}

editorIsActive.subscribe(function(_v) {
  if (hintShown.value)
    return
  // should call via resetTimeout to let editor initialize objects
  if (hintStep.value == 1)
    gui_scene.resetTimeout(0.1, showHintCheckTeams)
  else if (hintStep.value == 2)
    gui_scene.resetTimeout(0.1, showHintCheckRespawns)
})


let function showHints() {
  if (hintStep.value > 0)
    return

  hintStep(1)
  if (hintWelcomeKeepShowing.value)
    showHintMessage("Welcome to Enlisted Sandbox.\n\nPress F12 to toggle open editor. Then F1 for help.\nPlease, read accompanying documentation for more detailed information.", showHintCheckTeams)
  else
    showHintCheckTeams()
}

return {
  showHints
  hintShown
  hintWindow
  hintWelcomeKeepShowing
}
