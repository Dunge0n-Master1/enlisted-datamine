from "%enlSqGlob/ui_library.nut" import *

let go_login = require("go.nut")
let auth  = require("auth")
let ah = require("auth_helpers.nut")
let { linkSteamAccount } = require("%enlSqGlob/login_state.nut")
let eventbus = require("eventbus")

const AUTH_STEAM = "auth_steam"
const STEAM_LINK = "steam_link"

return [
  {
    id = AUTH_STEAM
    function action(state, cb) {
      if (!linkSteamAccount.value) {
        eventbus.subscribe_onehit(AUTH_STEAM, ah.status_cb(cb))
        auth.login_steam(state.params.onlyKnown, AUTH_STEAM)
      }
      else
        cb({})
    }
    actionOnReload = @(_state, cb) eventbus.subscribe_onehit(AUTH_STEAM, ah.status_cb(cb))
  }
  {
    id = go_login.id
    function action(params, cb){
      if (linkSteamAccount.value)
        go_login.action(params, cb)
      else
        cb({})
    }
    actionOnReload = @(state, cb) linkSteamAccount.value ? go_login.actionOnReload(state, cb) : null
  }
  {
    id = STEAM_LINK
    function action(_params, cb) {
      if (linkSteamAccount.value) {
        eventbus.subscribe_onehit(STEAM_LINK, ah.status_cb(cb))
        auth.login_steam(false, STEAM_LINK)
      }
      else
        cb({})
    }
    actionOnReload = @(_state, cb) eventbus.subscribe_onehit(STEAM_LINK, ah.status_cb(cb))
  }
]
