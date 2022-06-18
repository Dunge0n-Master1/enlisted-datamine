from "%enlSqGlob/ui_library.nut" import *

let auth  = require("auth")
let { get_arg_value_by_name } = require("dagor.system")
let eventbus = require("eventbus")

let function status_cb(cb) {
  return function(result) {
    if (result.status != auth.YU2_OK) {
      if (result.status == auth.YU2_NOT_FOUND) {
        result.error <- "dmmError/notRegistered"
        result.quitBtn <- true
      }
      else
        result.error <- auth.status_string_full(result.status)
    }
    cb(result)
  }
}

const id = "auth_dmm"

return {
  id
  function action(_state, cb) {
    eventbus.subscribe_onehit(id, status_cb(cb))
    auth.login_dmm({
      dmm_user_id = get_arg_value_by_name("dmm_user_id")
      dmm_token = get_arg_value_by_name("dmm_token")
    }, id)
  }
}
