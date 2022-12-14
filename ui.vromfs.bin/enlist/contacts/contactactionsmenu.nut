from "%enlSqGlob/ui_library.nut" import *

let { addContextMenu } = require("%ui/components/menuObject.nut")
let locByPlatform = require("%enlSqGlob/locByPlatform.nut")
let { uid2console } = require("%enlist/contacts/consoleUidsRemap.nut")
let { searchContactByInternalId } = require("%enlist/contacts/externalIdsManager.nut")
let { consoleCompare } = require("%enlSqGlob/platformUtils.nut")

let function openContextMenu(userId, event, actions) {
  let actionsButtons = (actions ?? []).map(@(action) {
    isVisible = action.mkIsVisible(userId)
    text = locByPlatform(action.locId)
    action = @() action.action(userId)
  })
  if (actionsButtons.len())
    addContextMenu(event.screenX + 1, event.screenY + 1, fsh(30), actionsButtons)
}

let function open(contactValue, event, actions) {
  if (contactValue.userId in uid2console.value) {
    openContextMenu(contactValue.userId, event, actions)
    return
  }

  foreach (data in consoleCompare)
    if (data.isPlatform && data.isFromPlatform(contactValue.realnick)) {
      searchContactByInternalId(contactValue.userId, function() {
        openContextMenu(contactValue.userId, event, actions)
      })
      return
    }

  openContextMenu(contactValue.userId, event, actions)
}



return {
  open = open
}