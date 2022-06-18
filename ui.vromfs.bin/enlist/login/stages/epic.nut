from "%enlSqGlob/ui_library.nut" import *

let auth  = require("auth")
let ah = require("auth_helpers.nut")
let eventbus = require("eventbus")

const id = "auth_epic"

return {
  id
  function action(_state, cb) {
    eventbus.subscribe_onehit(id, ah.status_cb(cb))
    auth.login_epic(id)
  }
}
