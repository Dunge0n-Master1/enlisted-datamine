from "%enlSqGlob/ui_library.nut" import *

let auth  = require("auth")

let function status_cb(cb) {
  return function(result) {
    if (result?.status != auth.YU2_OK)
      result.error <- auth.status_string_full(result.status)
    cb(result)
  }
}

return {
  status_cb = status_cb
}

