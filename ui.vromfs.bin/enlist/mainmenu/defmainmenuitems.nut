from "%enlSqGlob/ui_library.nut" import *

let platform = require("%dngscripts/platform.nut")
let { showControlsMenu } = require("%ui/hud/menus/controls_setup.nut")
let { showSettingsMenu } = require("%ui/hud/menus/settings_menu.nut")
let {exitGameMsgBox, logoutMsgBox} = require("%enlist/mainMsgBoxes.nut")
let openUrl = require("%ui/components/openUrl.nut")
let {gaijinSupportUrl, bugReportUrl} = require("%enlSqGlob/supportUrls.nut")
let { get_setting_by_blk_path } = require("settings")
let qrWindow = require("qrWindow.nut")

let SEPARATOR = {}
let GSS_URL = get_setting_by_blk_path("gssUrl") ?? "https://gss.gaijin.net/"

let btnOptions = {
  name = loc("gamemenu/btnOptions")
  id = "Options"
  cb = function() {
    showSettingsMenu(true)
  }
}
let btnControls = {
  id = "Controls"
  name = loc("gamemenu/btnBindKeys")
  cb = function() {
    showControlsMenu(true)
  }
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
let allowUrl = platform.is_pc || platform.is_sony || platform.is_nswitch || platform.is_android
let btnGSS = GSS_URL == "" ? null : {
  id = "Gss"
  name = loc("gss")
  cb = @() allowUrl ? openUrl(GSS_URL) : qrWindow(GSS_URL, loc("gss"))
}
let btnSupport = gaijinSupportUrl == "" ? null : {
  id = "Support"
  name = loc("support")
  cb = @() allowUrl ? openUrl(gaijinSupportUrl) : qrWindow(gaijinSupportUrl, loc("support"))
}

let btnBugReport = (bugReportUrl == "" || !platform.is_pc) ? null : {
  id = "reportProblem"
  name = loc("gamemenu/btnReportProblem")
  cb = @() openUrl(bugReportUrl)
}

return {
  btnControls
  btnOptions
  btnLogout  btnExit
  btnGSS
  btnSupport
  btnBugReport
  SEPARATOR
}