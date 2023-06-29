from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { gap } = require("%enlSqGlob/ui/viewConst.nut")
let { defTxtColor, colFull } = require("%enlSqGlob/ui/designConst.nut")
let { navBottomBarHeight } = require("%enlist/mainMenu/mainmenu.style.nut")
let { squadLen, squadMembers, isInvitedToSquad, enabledSquad, canInviteToSquad,
  leaveSquad, squadSelfMember, myExtSquadData, isSquadLeader
} = require("%enlist/squad/squadManager.nut")
let { currentGameMode } = require("%enlist/gameModes/gameModeState.nut")
let { getContact } = require("%enlist/contacts/contact.nut")
let mkContactBlock = require("%enlist/contacts/contactBlock.nut")
let showContactsListWnd = require("%enlist/contacts/contactsListWnd.nut")
let {
  INVITE_TO_FRIENDS, REMOVE_FROM_SQUAD, PROMOTE_TO_LEADER, REVOKE_INVITE,
  SHOW_USER_LIVE_PROFILE, INVITE_TO_PSN_FRIENDS
} = require("%enlist/contacts/contactActions.nut")
let { FAFlatButton } = require("%ui/components/txtButton.nut")
let textButton = require("%ui/components/textButton.nut")
let { roomIsLobby } = require("%enlist/state/roomState.nut")
let { showCurNotReadySquadsMsg } = require("%enlist/soldiers/model/notReadySquadsState.nut")

let contextMenuActions = [INVITE_TO_FRIENDS, INVITE_TO_PSN_FRIENDS, REMOVE_FROM_SQUAD,
  PROMOTE_TO_LEADER, REVOKE_INVITE, SHOW_USER_LIVE_PROFILE]
let maxMembers = Computed(@() currentGameMode.value?.queue.maxGroupSize ?? 1)

let hintTxtStyle = { color = defTxtColor }.__update(sub_txt)


let mkHint = @(text) {
  rendObj = ROBJ_TEXT
  text
}.__update(hintTxtStyle)


let addUserButton = FAFlatButton("user-plus", showContactsListWnd, {
  hint = mkHint(loc("tooltips/addUser"))
  btnWidth = navBottomBarHeight
  btnHeight = navBottomBarHeight
})

let leaveButton = FAFlatButton("close", @() leaveSquad(), {
  hint = mkHint(loc("tooltips/disbandSquad"))
  btnWidth = navBottomBarHeight
  btnHeight = navBottomBarHeight
})

let squadControls = @() {
  watch = squadLen
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  children = squadLen.value > 0 ? leaveButton : null
}

let horizontalContact = @(contact) {
  size = [colFull(3), navBottomBarHeight]
  children = mkContactBlock(contact, contextMenuActions)
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
  let res = { watch = [squadSelfMember, isSquadLeader, roomIsLobby, myExtSquadData.ready] }
  if (squadSelfMember.value && !isSquadLeader.value) {
    res.__update({
      size = [SIZE_TO_CONTENT, navBottomBarHeight]
       children = roomIsLobby.value
         ? null
         : squadReadyButton(myExtSquadData.ready)
    })
  }
  return res
}

let function squadMembersUi() {
  let squadList = []
  foreach (member in squadMembers.value)
    if (member.isLeader)
      squadList.insert(0, horizontalContact(getContact(member.userId.tostring())))
    else
      squadList.append(horizontalContact(getContact(member.userId.tostring())))

  foreach (uid, _ in isInvitedToSquad.value)
    squadList.append(horizontalContact(getContact(uid.tostring())))

  if (maxMembers.value > 1 && canInviteToSquad.value)
    for(local i = squadList.len(); i < maxMembers.value; i++)
      squadList.append(addUserButton)

  return {
    watch = [squadMembers, isInvitedToSquad, canInviteToSquad, maxMembers]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap
    children = squadList
  }
}


return @() {
  stopMouse = true
  watch = enabledSquad
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap
  children = enabledSquad.value
    ? [
        squadControls
        squadReadyButtonPlace
        squadMembersUi
      ]
    : null
}
