from "%enlSqGlob/ui_library.nut" import *

let { exit_game } = require("app")
let { unlockedCampaigns, lockedCampaigns } = require("%enlist/meta/campaigns.nut")
let debriefingShow = require("%enlist/debriefing/debriefingStateInMenu.nut").show
let { showMsgbox, removeMsgboxByUid } = require("%enlist/components/msgbox.nut")
let { logOut } = require("%enlSqGlob/login_state.nut")
let { is_pc } = require("%dngscripts/platform.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")

const MSG_UID = "update_game_notify"

let needUpdateVersion = Computed(@() unlockedCampaigns.value.len() > 0 ? null
  : lockedCampaigns.value.findvalue(@(c) c?.reqVersion != null)?.reqVersion)
let needForceUpdateGame = keepref(Computed(@() needUpdateVersion.value != null && !debriefingShow.value))

let exitFunc = @() !userInfo.value ? null
  : is_pc ? exit_game()
  : logOut()

let updateMsgBox = @(show)
  !show ? removeMsgboxByUid(MSG_UID)
    : showMsgbox({
        uid = MSG_UID
        text = loc("InvalidVersion")
        buttons = !is_pc ? [] : [{
          text = loc("Exit Game"),
          action = exitFunc
          isCurrent = true
        }]
        onClose = exitFunc
      })

updateMsgBox(needForceUpdateGame.value)
needForceUpdateGame.subscribe(updateMsgBox)
