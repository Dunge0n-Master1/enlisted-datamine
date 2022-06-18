from "%enlSqGlob/ui_library.nut" import *

let {local_storage} = require("app")

return {
  id = "save_login_data"
  function action(state, cb) {
    let params = state.params
    local_storage.hidden.set_value("login",
      (params?.saveLogin && params.login_id.len()) ? params.login_id : null)
    local_storage.hidden.set_value("password", params?.savePassword ? params.password : null)
    cb({})
  }
}
