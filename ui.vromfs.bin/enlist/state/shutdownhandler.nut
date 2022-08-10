from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")

let list = []

eventbus.subscribe("app.shutdown", function(...) {
  foreach (func in list)
    func()
})

return {
  add = @(func) list.append(func)
  remove = function(func) {
    let idx = list.indexof(func)
    if (idx != null)
      list.remove(idx)
  }
}
