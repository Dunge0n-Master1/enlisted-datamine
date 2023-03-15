from "%enlSqGlob/ui_library.nut" import *

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { columnGap, defTxtColor, colFull, colPart, midPadding } = require("%enlSqGlob/ui/designConst.nut")
let { squadMembers, squadLen, isInvitedToSquad, enabledSquad, canInviteToSquad, leaveSquad
} = require("%enlist/squad/squadManager.nut")
let { currentGameMode } = require("%enlist/gameModes/gameModeState.nut")
let { Contact } = require("%enlist/contacts/contact.nut")
let { smallContactBtn } = require("%enlist/contacts/contactBtn.nut")
let { isNewDesign } = require("%enlSqGlob/designState.nut")
let showContactsListWnd = isNewDesign.value
  ? require("%enlist/contacts/contactsListWindow.nut")
  : require("%enlist/contacts/contactsListWnd.nut")
let { FAButton } = require("%ui/components/txtButton.nut")
let { INVITE_TO_FRIENDS, REMOVE_FROM_SQUAD, PROMOTE_TO_LEADER, REVOKE_INVITE,
  SHOW_USER_LIVE_PROFILE, INVITE_TO_PSN_FRIENDS
} = require("%enlist/contacts/contactActions.nut")
let { roomIsLobby } = require("%enlist/state/roomState.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let smallBtnSize = colPart(0.45) + midPadding
let contextMenuActions = [INVITE_TO_FRIENDS, INVITE_TO_PSN_FRIENDS, REMOVE_FROM_SQUAD,
  PROMOTE_TO_LEADER, REVOKE_INVITE, SHOW_USER_LIVE_PROFILE]
let maxMembers = Computed(@() currentGameMode.value?.queue.maxGroupSize ?? 1)

let mkHint = @(hint) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = colFull(3)
  text = hint
}.__update(defTxtStyle)

let mkAddUserButton = FAButton("user-plus", showContactsListWnd, {
  hint = mkHint(loc("tooltips/addUser"))
  btnWidth = smallBtnSize
  btnHeight = smallBtnSize
})

let leaveButton = FAButton("close", @() leaveSquad(), {
  hint = mkHint(loc("tooltips/disbandSquad"))
  btnWidth = smallBtnSize
  btnHeight = smallBtnSize
})

let squadControls = @() {
  watch = squadLen
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  children = squadLen.value > 0 ? leaveButton : null
}

let horizontalContact = @(contact) smallContactBtn(contact, contextMenuActions)

let function squadMembersUi() {
  let squadList = []
  foreach (member in squadMembers.value)
    if (member.isLeader)
      squadList.insert(0, horizontalContact(Contact(member.userId.tostring())))
    else
      squadList.append(horizontalContact(Contact(member.userId.tostring())))

  foreach (uid, _ in isInvitedToSquad.value)
    squadList.append(horizontalContact(Contact(uid.tostring())))

  if (maxMembers.value > 1 && canInviteToSquad.value)
    for(local i = squadList.len(); i < maxMembers.value; i++)
      squadList.append(mkAddUserButton())

  return {
    watch = [squadMembers, isInvitedToSquad, canInviteToSquad, maxMembers, roomIsLobby]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = columnGap
    children = squadList
  }
}



return @() {
  stopMouse = true
  watch = enabledSquad
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = columnGap
  children = enabledSquad.value
    ? [
        squadControls
        squadMembersUi
      ]
    : null
}
