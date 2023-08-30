from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor } = require("%enlSqGlob/ui/designConst.nut")
let { isUsermailWndOpend, hasUnseenLetters } = require("%enlist/usermail/usermailState.nut")
let { hasUsermail } = require("%enlist/featureFlags.nut")
let { blinkUnseenIcon } = require("%ui/components/unseenSignal.nut")
let { FAFlatButton } = require("%ui/components/txtButton.nut")
let { navBottomBarHeight } = require("%enlist/mainMenu/mainmenu.style.nut")


let unseenIcon = blinkUnseenIcon(1).__update({ hplace = ALIGN_RIGHT })

let hintTxtStyle = { color = defTxtColor }.__update(fontSub)

let hoverHint = {
  rendObj = ROBJ_TEXT
  text = loc("mail/mailTab")
}.__update(hintTxtStyle)


return @() {
  watch = [hasUsermail, hasUnseenLetters]
  children = !hasUsermail.value ? null
    : [
      FAFlatButton("envelope", @() isUsermailWndOpend(true), {
          hint = hoverHint
          btnWidth = navBottomBarHeight
          btnHeight = navBottomBarHeight
        })
        hasUnseenLetters.value ? unseenIcon : null
      ]
}