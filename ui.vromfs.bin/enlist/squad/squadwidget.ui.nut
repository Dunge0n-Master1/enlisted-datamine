from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { navBottomBarHeight } = require("%enlist/mainMenu/mainmenu.style.nut")
let { bigGap } = require("%enlSqGlob/ui/viewConst.nut")
let { isSquadLeader, squadLen, squadMembers, isInvitedToSquad, squadSelfMember,
  enabledSquad, canInviteToSquad, myExtSquadData, leaveSquad
} = require("%enlist/squad/squadManager.nut")
let { currentGameMode } = require("%enlist/gameModes/gameModeState.nut")
let { Contact } = require("%enlist/contacts/contact.nut")
let contactBlock = require("%enlist/contacts/contactBlock.nut")
let showContactsListWnd = require("%enlist/contacts/contactsListWnd.nut")
let squareIconButton = require("%enlist/components/squareIconButton.nut")
let textButton = require("%ui/components/textButton.nut")
let {
  INVITE_TO_FRIENDS, REMOVE_FROM_SQUAD, PROMOTE_TO_LEADER, REVOKE_INVITE,
  SHOW_USER_LIVE_PROFILE, INVITE_TO_PSN_FRIENDS
} = require("%enlist/contacts/contactActions.nut")
let { roomIsLobby } = require("%enlist/state/roomState.nut")
let { showCurNotReadySquadsMsg } = require("%enlist/soldiers/model/notReadySquadsState.nut")


let contextMenuActions = [INVITE_TO_FRIENDS, INVITE_TO_PSN_FRIENDS, REMOVE_FROM_SQUAD,
  PROMOTE_TO_LEADER, REVOKE_INVITE, SHOW_USER_LIVE_PROFILE]
let maxMembers = Computed(@() currentGameMode.value?.queue.maxGroupSize ?? 1)

let mkAddUserButton = @() squareIconButton({
  onClick = showContactsListWnd
  tooltipText = loc("tooltips/addUser")
  iconId = "user-plus"
})

let leaveButton = squareIconButton({
    onClick = @() leaveSquad()
    tooltipText = loc("tooltips/disbandSquad")
    iconId = "close"
  },
  { margin = [hdpx(8), 0, 0, hdpx(1)] })

let squadControls = @() {
  watch = squadLen
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  children = squadLen.value > 0 ? leaveButton : null
}

let horizontalContact = @(contact) {
  size = [(navBottomBarHeight * 4.0).tointeger(), navBottomBarHeight]
  children = contactBlock(contact, contextMenuActions)
}

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
    gap = hdpx(4)
    children = squadList
  }
}

let squadReadyButton = @(ready) textButton(
  ready.value ? loc("Set not ready") : loc("Press when ready"),
  function() {
    if (ready.value)
      ready(false)
    else
      showCurNotReadySquadsMsg(@() ready(true))
  },
  { size = [SIZE_TO_CONTENT, flex()]
    margin = [0, 0, 0, hdpx(5)]
    textParams = { validateStaticText = false, vplace = ALIGN_CENTER }.__update(sub_txt)
    style = !ready.value
      ? { BgNormal   = Color(220, 130, 0, 250), TextNormal = Color(210, 210, 210, 120) }
      : { TextNormal = Color(100, 100, 100, 120) }
  })

let function squadReadyButtonPlace() {
  let res = { watch = [squadSelfMember, isSquadLeader, roomIsLobby] }
  if (squadSelfMember.value && !isSquadLeader.value) {
    res.watch.append(myExtSquadData.ready)
    res.size <- [SIZE_TO_CONTENT, navBottomBarHeight]
    res.children <- roomIsLobby.value ? null
      : squadReadyButton(myExtSquadData.ready)
  }
  return res
}

return @() {
  stopMouse = true
  watch = enabledSquad
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = bigGap
  children = enabledSquad.value
    ? [
        squadControls
        squadReadyButtonPlace
        squadMembersUi
      ]
    : null
}
