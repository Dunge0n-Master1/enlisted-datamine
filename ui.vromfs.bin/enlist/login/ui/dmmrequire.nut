from "%enlSqGlob/ui_library.nut" import *

let textButton = require("%ui/components/textButton.nut")
let centeredText = require("%enlist/components/centeredText.nut")
let { exit_game } = require("app")

return {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = [
      centeredText(loc("error/shouldRunFromDMMLauncher"))
      textButton(loc("gamemenu/btnQuit"), exit_game)
    ]
}
