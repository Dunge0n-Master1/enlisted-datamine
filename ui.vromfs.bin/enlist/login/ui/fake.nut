from "%enlSqGlob/ui_library.nut" import *

let {startLogin} = require("%enlist/login/login_chain.nut")

let function loginRoot() {
  startLogin({})
  return {}
}

return {
  size = flex()
  children = loginRoot
}
