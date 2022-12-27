from "%enlSqGlob/ui_library.nut" import *

let platform = require("%dngscripts/platform.nut")
let { showControlsMenu } = require("%ui/hud/menus/controls_setup.nut")
let { showSettingsMenu } = require("%ui/hud/menus/settings_menu.nut")
let {exitGameMsgBox, logoutMsgBox} = require("%enlist/mainMsgBoxes.nut")
let openUrl = require("%ui/components/openUrl.nut")
let { gaijinSupportUrl, bugReportUrl } = require("%enlSqGlob/supportUrls.nut")
let { get_setting_by_blk_path } = require("settings")
let { isNewDesign, setDesign } = require("%enlSqGlob/designState.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let qrWindow = require("qrWindow.nut")

let SEPARATOR = {}
let GSS_URL = get_setting_by_blk_path("gssUrl") ?? "https://gss.gaijin.net/"
let CBR_URL = get_setting_by_blk_path("cbrUrl") ?? "https://community.gaijin.net/issues/p/enlisted"

let btnOptions = {
  name = loc("gamemenu/btnOptions")
  id = "Options"
  cb = @() showSettingsMenu(true)
}
let btnControls = {
  id = "Controls"
  name = loc("gamemenu/btnBindKeys")
  cb = @() showControlsMenu(true)
}
let btnExit = {
  id = "Exit"
  name = loc("Exit Game")
  cb = exitGameMsgBox
}
let btnLogout = {
  id = "Exit"
  name = loc("Exit Game")
  cb = logoutMsgBox
}
let allowUrl = platform.is_pc || platform.is_nswitch || platform.is_android
let btnGSS = GSS_URL == "" ? null : {
  id = "Gss"
  name = loc("gss")
  cb = @() allowUrl ? openUrl(GSS_URL) : qrWindow({url = GSS_URL, header = loc("gss")})
}
let btnCBR = CBR_URL == "" ? null : {
  id = "Cbr"
  name = loc("cbr")
  cb = @() allowUrl ? openUrl(CBR_URL) : qrWindow({url = CBR_URL, header = loc("cbr")})
}
let btnSupport = gaijinSupportUrl == "" ? null : {
  id = "Support"
  name = loc("support")
  cb = @() allowUrl ? openUrl(gaijinSupportUrl)
    : qrWindow({url = gaijinSupportUrl, header = loc("support")})
}

let btnBugReport = (bugReportUrl == "" || !platform.is_pc) ? null : {
  id = "reportProblem"
  name = loc("gamemenu/btnReportProblem")
  cb = @() openUrl(bugReportUrl)
}

let btnToggleDesign = {
  id = "ToggleDesign"
  name = isNewDesign.value ? loc("gamemenu/btnLegacyDesign") : loc("gamemenu/btnNewDesign")
  cb = function() {
    if (isNewDesign.value)
      setDesign(false)
    else {
      msgbox.show({
        text = loc("gamemenu/hintNewDesign")
        buttons = [
          { text = loc("Cancel"), isCurrent = true }
          { text = loc("Ok"), action = @() setDesign(true) }
        ]
      })
    }
  }
}

return {
  btnControls
  btnOptions
  btnLogout
  btnExit
  btnGSS
  btnCBR
  btnSupport
  btnBugReport
  btnToggleDesign
  SEPARATOR
}