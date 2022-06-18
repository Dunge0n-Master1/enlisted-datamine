from "%enlSqGlob/ui_library.nut" import *

let {get_user_info} = require("auth")
let {status_cb} = require("%enlist/login/stages/auth_helpers.nut")

return {
  id = "auth_result"
  function action(_state, cb) {
    status_cb(cb)(get_user_info())
  }
}
