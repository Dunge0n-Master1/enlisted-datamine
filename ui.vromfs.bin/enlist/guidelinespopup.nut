from "%enlSqGlob/ui_library.nut" import *

let msgbox = require("%enlist/components/msgbox.nut")
let { get_setting_by_blk_path } = require("settings")
let { isLoggedIn } = require("%enlSqGlob/login_state.nut")
let { get_kongzhong_fcm } = require("auth")

let showGuidelinesWindow = get_setting_by_blk_path("enableCommunityGuidelinesWindow") ?? false
if (!showGuidelinesWindow)
  return


const WND_UID = "GUIDELINES_WND"

let guidelinesShown = mkWatched(persist, "guidelinesShown", false)
let minWindowShowTime = 3.0

let function showGuidelines() {
  if (guidelinesShown.value)
    return

  guidelinesShown(true)

  let showCloseButton = Watched(false)
  local guidelinesText = loc("community_guidelines")

  let fcm = get_kongzhong_fcm()

  if (fcm == 0) {
    // Juvenile account
    guidelinesText = "\n\n".join([guidelinesText, loc("antiaddiction_guidelines")])
  }

  msgbox.show({
    uid = WND_UID
    text = guidelinesText
    buttons = Computed(@() showCloseButton.value ? [{
      text = loc("Close")
    }] : [])
  },
  msgbox.styling.__merge({
    Root = msgbox.styling.Root.__merge({
      onAttach = @() gui_scene.setTimeout(minWindowShowTime, @() showCloseButton(true))
    })
    closeKeys = ""
    activateKeys = ""
  }))
}

isLoggedIn.subscribe(function(logged) {
  if (logged)
    showGuidelines()
})
