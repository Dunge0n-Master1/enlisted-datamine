from "%enlSqGlob/ui_library.nut" import *

let loginActions = {}

let function setLoginActions(actionsTable){
  loginActions.__update(actionsTable)
}

let getLoginActions = @() freeze(clone loginActions)

return {getLoginActions, setLoginActions}