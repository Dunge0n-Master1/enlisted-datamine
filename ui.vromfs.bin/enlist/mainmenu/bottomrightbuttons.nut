from "%enlSqGlob/ui_library.nut" import *

let { Inactive } = require("%ui/style/colors.nut")
let { bigGap, gap } = require("%enlSqGlob/ui/viewConst.nut")
let { navBottomBarHeight } = require("%enlist/mainMenu/mainmenu.style.nut")
let { mailboxEnabled } = require("%enlist/mailboxState.nut")
let mailboxButton = require("%enlist/mailboxButton.ui.nut")
let { isContactsEnabled } = require("%enlist/contacts/contactsState.nut")
let mkContactBlock = require("%enlist/contacts/mkContactBlock.nut")
let showContactsListWnd = require("%enlist/contacts/contactsListWnd.nut").show
let mkContactsButton = require("%enlist/contacts/mkContactsButton.nut")
let { enabledSquad } = require("%enlist/squad/squadState.nut")
let squadWidget = require("%enlist/squad/squadWidget.ui.nut")
let { curSection } = require("%enlist/mainMenu/sectionsState.nut")
let userLogButton = require("%enlist/userLog/userLogButton.nut")
let usermailButton = require("%enlist/usermail/usermailButton.nut")


let showSocialBlock = Computed(@() curSection.value == "SOLDIERS")

let buttons = []
if (mailboxEnabled)
  buttons.append(mailboxButton)
if (isContactsEnabled)
  buttons.append(mkContactsButton(@() showContactsListWnd({ mkContactBlock })))

buttons.append(userLogButton)
buttons.append(usermailButton)


let buttonsBlock = {
  size = [SIZE_TO_CONTENT, navBottomBarHeight]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap
  children = buttons
}

let function bottomBar() {
  let children = []
  if (showSocialBlock.value) {
    if (enabledSquad.value)
      children.append(squadWidget)
    if (buttons.len() > 0)
      children.append(buttonsBlock)
  }

  return {
    watch = [showSocialBlock, enabledSquad]
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = {
      size = [hdpx(1), ph(65)]
      rendObj = ROBJ_SOLID
      color = Inactive
      margin = [0, bigGap, 0, bigGap]
    }
    children
  }
}

return bottomBar
