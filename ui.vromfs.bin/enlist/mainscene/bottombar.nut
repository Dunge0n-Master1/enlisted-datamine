from "%enlSqGlob/ui_library.nut" import *


let { colFull, colPart, footerContentHeight } = require("%enlSqGlob/ui/designConst.nut")
let mailboxButton = require("%enlist/mainScene/invitationsLogButton.ui.nut")
let { isContactsEnabled } = require("%enlist/contacts/contactsState.nut")
let showContactsListWnd = require("%enlist/contacts/contactsListWindow.nut")
let mkContactsButton = require("%enlist/contacts/contactsButton.ui.nut")
let { enabledSquad } = require("%enlist/squad/squadState.nut")
let squadWidget = require("%enlist/squad/squadBlockUi.nut")
let { hasMainSectionOpened } = require("%enlist/mainMenu/sectionsState.nut")
let userLogButton = require("%enlist/userLog/userLogButton.ui.nut")
let usermailButton = require("%enlist/usermail/usermailButton.ui.nut")


let buttons = [mailboxButton]
if (isContactsEnabled)
  buttons.append(mkContactsButton(showContactsListWnd))

buttons.append(userLogButton)
buttons.append(usermailButton)


let function rightButtons() {
  let children = []
  if (hasMainSectionOpened.value) {
    if (enabledSquad.value)
      children.append(squadWidget)
    if (buttons.len() > 0)
      children.extend(buttons)
  }
  return {
    watch = [hasMainSectionOpened, enabledSquad]
    size = [colFull(5), footerContentHeight]
    minWidth = SIZE_TO_CONTENT
    halign = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    gap = colPart(0.1842)
    hplace = ALIGN_RIGHT
    children
  }
}


return rightButtons
