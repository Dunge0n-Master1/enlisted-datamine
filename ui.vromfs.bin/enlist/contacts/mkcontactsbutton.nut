from "%enlSqGlob/ui_library.nut" import *

let { Alert } = require("%ui/style/colors.nut")
let { friendsOnlineUids, requestsToMeUids } = require("%enlist/contacts/contactsWatchLists.nut")
let { isContactsVisible } = require("contactsState.nut")
let buildCounter = require("buildCounter.nut")
let squareIconButton = require("%enlist/components/squareIconButton.nut")

let counterText = @(count) count > 0 ? count : null

let onlineFriendsCounter = buildCounter(
  Computed(@() counterText(friendsOnlineUids.value.len())),
  { pos = [-hdpx(3), hdpx(4)] })

let invitationsCounter = buildCounter(
  Computed(@() counterText(requestsToMeUids.value.len())),
  {
    pos = [-hdpx(3), -hdpx(4)]
    vplace = ALIGN_BOTTOM
    color = Alert
  })

let contactsButton = @(onClick) @() {
  watch = isContactsVisible
  children = [
    squareIconButton({
      onClick
      tooltipText = loc("tooltips/contactsButton")
      iconId = "users"
      selected = isContactsVisible
    })
    onlineFriendsCounter
    invitationsCounter
  ]
}

return contactsButton
