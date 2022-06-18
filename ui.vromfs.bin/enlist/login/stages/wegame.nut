from "%enlSqGlob/ui_library.nut" import *

let auth  = require("auth")
let ah = require("auth_helpers.nut")
let eventbus = require("eventbus")
let { get_circuit } = require("app")

const id = "auth_wegame"

return {
  id

  function action(state, cb) {
    eventbus.subscribe_onehit(id, ah.status_cb(cb))
    auth.login_wegame({
      circuit = get_circuit()
    }.__update(state?.params ?? {}), id)
  }
}
