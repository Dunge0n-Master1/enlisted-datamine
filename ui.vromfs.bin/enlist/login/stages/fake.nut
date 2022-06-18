from "%enlSqGlob/ui_library.nut" import *

return {
  id = "auth_result"
  function action(_state, cb) {
    defer(@() cb({
         userId = 0
         userIdStr = "0"
         name = "name"
         token = null
         tags = []
       }))
  }
}
