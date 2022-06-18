import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let loginState = require("%enlSqGlob/login_state.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let {removeAllMsgboxes} = require("components/msgbox.nut")
let app = require("app")
let {EventUserLoggedIn, EventUserLoggedOut} = require("gameevents")

require("unlogingHandler.nut")
require("state/customRooms.nut")
require("squad/commonExtData.nut")
require("registerConsoleCmds.nut")

gui_scene.setShutdownHandler(function() {
  removeAllMsgboxes()
})

let delayedLogout = persist("delayedLogout", @() { need = false })

let function on_login() {
  app.switch_scene("") // "" is default scene which is used for menu
  ecs.g_entity_mgr.broadcastEvent(EventUserLoggedIn(userInfo.value.userId))
}

let function on_logout() {
  app.switch_scene("content/common/gamedata/scenes/empty.blk")
  ecs.g_entity_mgr.broadcastEvent(EventUserLoggedOut())
}

// if matching client forced client to logout do not interrupt current game session
// perform logout after session is finished
isInBattleState.subscribe(
  function (active) {
    if (!active && delayedLogout.need) {
      on_logout()
      delayedLogout.need = false
    }
  }
)

loginState.isLoggedIn.subscribe(function (state) {
  if (state) {
    on_login()
  }
  else {
    if (!isInBattleState.value) {
      on_logout()
    }
    else {
      delayedLogout.need = true
    }
  }
})
