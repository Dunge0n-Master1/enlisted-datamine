from "%enlSqGlob/ui_library.nut" import *

let currentLogin = {comp = null}
let loginUiVersion = mkWatched(persist, "loginUiVersion", 0)

let getCurrentLoginUi = @() currentLogin.comp
let function setCurrentLoginUi(comp) {
  loginUiVersion(loginUiVersion.value+1)
  currentLogin.comp = comp
}

return { getCurrentLoginUi, loginUiVersion, setCurrentLoginUi, currentLogin }