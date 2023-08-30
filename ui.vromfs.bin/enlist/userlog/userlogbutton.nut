from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor } = require("%enlSqGlob/ui/designConst.nut")
let userLogScene = require("userLogScene.nut")
let { hasUserLogs } = require("%enlist/featureFlags.nut")
let { FAFlatButton } = require("%ui/components/txtButton.nut")
let { navBottomBarHeight } = require("%enlist/mainMenu/mainmenu.style.nut")


let hintTxtStyle = { color = defTxtColor }.__update(fontSub)

let hoverHint = {
  rendObj = ROBJ_TEXT
  text = loc("tooltips/userLogs")
}.__update(hintTxtStyle)

return @() {
  watch = hasUserLogs
  children = !hasUserLogs.value ? null
    : FAFlatButton("bell", @() userLogScene(), {
      hint = hoverHint
      btnWidth = navBottomBarHeight
      btnHeight = navBottomBarHeight
    })
}
