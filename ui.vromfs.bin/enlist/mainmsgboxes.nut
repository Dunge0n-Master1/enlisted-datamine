from "%enlSqGlob/ui_library.nut" import *

let {exit_game} = require("app")
let msgbox = require("%enlist/components/msgbox.nut")
let login = require("%enlSqGlob/login_state.nut")

let function exitGameMsgBox () {
  msgbox.show({
    text = loc("msgboxtext/exitGame")
    buttons = [
      { text = loc("Yes"), action = exit_game}
      { text = loc("No"), isCurrent = true }
    ]
  })
}
let function logoutMsgBox(){
  msgbox.show({
    text = loc("msgboxtext/logout")
    buttons = [
      { text = loc("Cancel"), isCurrent = true }
      { text = loc("Signout"), action = function() {
        login.logOut()
      }}
    ]
  })
}
return {
  exitGameMsgBox = exitGameMsgBox
  logoutMsgBox = logoutMsgBox
}
