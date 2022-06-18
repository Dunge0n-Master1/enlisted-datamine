from "%enlSqGlob/ui_library.nut" import *

let platform = require("%dngscripts/platform.nut")
let openUrl = require("%ui/components/openUrl.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let {addPopup} = require("%enlist/popup/popupsState.nut")

let popup1 = {
  id = "nda reminder1"
  text = loc("NDA_reminder1", "Alpha version! PLEASE, DO NOT STREAM IT!")
  styleName = "error"
}
let popup2 = {
  id = "nda reminder2"
  text = loc("NDA_reminder2", "Help us improve the game on forum.enlisted.net")
  styleName = "error"
}
let addNdaPopup1 = @() addPopup(popup1)
let addNdaPopup2 = @() addPopup(popup2)
let function ndaPopup() {
  addNdaPopup1()
  addNdaPopup2()
}
gui_scene.setInterval(60*60, ndaPopup)
let showMsgBox = @() msgbox.show(
  {
    UID = "NDA_REMINDER"
    text = loc("NDA_reminder_msgbox", "Remember! This is Alpha version!\n\n Please, DO NOT stream or share it!\n\n\nHelp us improve the game on forum.enlisted.net.\n\nThank you!")
    buttons = [
      { text = loc("Ok"),
        isCurrent = true
      }
      { text = loc("Visit Forum")
        action = @() openUrl("https://forum.enlisted.net", false, true)
      }
    ]

  }
)

userInfo.subscribe(function(v){
  if (v!=null && !platform.is_xbox)
    showMsgBox()
})
