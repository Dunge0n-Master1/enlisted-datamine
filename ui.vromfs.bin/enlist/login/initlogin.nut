from "%enlSqGlob/ui_library.nut" import *

let platform = require("%dngscripts/platform.nut")
let { getCurrentLoginUi, setCurrentLoginUi } = require("%enlist/login/currentLoginUi.nut")
let { disableNetwork, linkSteamAccount } = require("%enlSqGlob/login_state.nut")
let { get_arg_value_by_name } = require("dagor.system")
let isDmmDistr = require("%enlSqGlob/dmm_distr.nut")
let { isKZVersion } = require("chineseKongZhongVersion.nut")


if (getCurrentLoginUi() == null) { //when not set by game before
  if (disableNetwork)
    setCurrentLoginUi(require("%enlist/login/ui/fake.nut"))
  else if (platform.is_xbox)
    setCurrentLoginUi(require("%enlist/login/ui/xbox.nut"))
  else if (platform.is_sony)
    setCurrentLoginUi(require("%enlist/login/ui/ps4.nut"))
  else {
    let steam = require("steam")
    let epic = require("epic")
    let wegame = require("wegame")
    let isDMMLogin = get_arg_value_by_name("dmm_user_id") != null

    let updatePcComp = function() {
      if (isDmmDistr && !isDMMLogin)
        setCurrentLoginUi(require("%enlist/login/ui/dmmRequire.nut"))
      else if (isDMMLogin)
        setCurrentLoginUi(require("%enlist/login/ui/dmm.nut"))
      else if (steam.is_running() && !linkSteamAccount.value)
        setCurrentLoginUi(require("%enlist/login/ui/steam.nut"))
      else if (epic.is_running())
        setCurrentLoginUi(require("%enlist/login/ui/epic.nut"))
      else if (wegame.is_running())
        setCurrentLoginUi(require("%enlist/login/ui/wegame.nut"))
      else if (isKZVersion)
        setCurrentLoginUi(require("%enlist/login/ui/kzLoginBrowser.nut"))
      else
        setCurrentLoginUi(require("%enlist/login/ui/go.nut"))
    }

    if (steam.is_running())
      linkSteamAccount.subscribe(@(_) updatePcComp())
    updatePcComp()
  }
}
