from "%enlSqGlob/ui_library.nut" import *

let auth  = require("auth")
let ah = require("auth_helpers.nut")
let eventbus = require("eventbus")
let { get_circuit } = require("app")

const id = "auth_go"

return {
  id
  function action(state, cb) {
    eventbus.subscribe_onehit(id, ah.status_cb(cb))

    let params = state.params.__merge({
      circuit = get_circuit()
    })
    let loginMethod = params?.two_step_code != null ? auth.login_2step : auth.login
    loginMethod(params, id)
  }
  actionOnReload = @(_state, cb) eventbus.subscribe_onehit(id, ah.status_cb(cb))
}
