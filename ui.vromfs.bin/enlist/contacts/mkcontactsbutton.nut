from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor, brightAccentColor } = require("%enlSqGlob/ui/designConst.nut")
let { friendsOnlineUids, requestsToMeUids } = require("%enlist/contacts/contactsWatchLists.nut")
let { isContactsVisible } = require("contactsState.nut")
let buildCounter = require("buildCounter.nut")
let { FAFlatButton } = require("%ui/components/txtButton.nut")
let { navBottomBarHeight } = require("%enlist/mainMenu/mainmenu.style.nut")

let counterText = @(count) count > 0 ? count : null
let hintTxtStyle = { color = defTxtColor }.__update(fontSub)

let onlineFriendsCounter = buildCounter(
  Computed(@() counterText(friendsOnlineUids.value.len())),
  { pos = [-hdpx(3), hdpx(4)] })

let invitationsCounter = buildCounter(
  Computed(@() counterText(requestsToMeUids.value.len())),
  {
    pos = [-hdpx(3), -hdpx(4)]
    vplace = ALIGN_BOTTOM
    color = brightAccentColor
  })

let hoverHint = {
  rendObj = ROBJ_TEXT
  text = loc("tooltips/contactsButton")
}.__update(hintTxtStyle)

let contactsButton = @(onClick) @() {
  watch = isContactsVisible
  children = [
    FAFlatButton("users", onClick, {
      tooltipText = hoverHint
      btnWidth = navBottomBarHeight
      btnHeight = navBottomBarHeight
    })
    onlineFriendsCounter
    invitationsCounter
  ]
}

return contactsButton
