from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { statusIconBg } = require("%ui/style/colors.nut")
let { navBottomBarHeight } = require("%enlist/mainMenu/mainmenu.style.nut")
let { bigGap } = require("%enlSqGlob/ui/viewConst.nut")
let { isSquadLeader, squadMembers, isInvitedToSquad, squadSelfMember,
  enabledSquad, canInviteToSquad, myExtSquadData, leaveSquad } = require("%enlist/squad/squadManager.nut")
let { currentGameMode } = require("%enlist/gameModes/gameModeState.nut")
let { Contact } = require("%enlist/contacts/contact.nut")
let mkContactBlock = require("%enlist/contacts/mkContactBlock.nut")
let showContactsListWnd = require("%enlist/contacts/contactsListWnd.nut").show
let squareIconButton = require("%enlist/components/squareIconButton.nut")
let textButton = require("%ui/components/textButton.nut")
let {
  INVITE_TO_FRIENDS, REMOVE_FROM_SQUAD, PROMOTE_TO_LEADER, REVOKE_INVITE,
  SHOW_USER_LIVE_PROFILE, INVITE_TO_PSN_FRIENDS
} = require("%enlist/contacts/contactActions.nut")
let { roomIsLobby } = require("%enlist/state/roomState.nut")


let contextMenuActions = [INVITE_TO_FRIENDS, INVITE_TO_PSN_FRIENDS, REMOVE_FROM_SQUAD, PROMOTE_TO_LEADER, REVOKE_INVITE, SHOW_USER_LIVE_PROFILE]
let maxMembers = Computed(@() currentGameMode.value?.queue.maxGroupSize ?? 1)

let mkAddUserButton = @() squareIconButton({
  onClick = @() showContactsListWnd({ mkContactBlock })
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
  watch = squadMembers
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  children = squadMembers.value.len() > 0 ? leaveButton : null
}

let horizontalContact = @(contact, hasStatusBlock) {
  size = [(navBottomBarHeight * 4.0).tointeger(), navBottomBarHeight]
  children = mkContactBlock({
    contact
    hasStatusBlock
    contextMenuActions
    style = {
      rendObj = ROBJ_WORLD_BLUR_PANEL
      bgColor = Color(255, 255, 255, 255)
      hoverColor = statusIconBg
    }
  })
}

let function squadMembersUi() {
  let hasStatusBlock = !roomIsLobby.value
  let squadList = []
  foreach (member in squadMembers.value)
    if (member.isLeader.value)
      squadList.insert(0, horizontalContact(member.contact, hasStatusBlock))
    else
      squadList.append(horizontalContact(member.contact, hasStatusBlock))

  foreach(uid, _ in isInvitedToSquad.value)
    squadList.append(horizontalContact(Contact(uid.tostring()), hasStatusBlock))

  if (maxMembers.value > 1 && canInviteToSquad.value)
    for(local i = squadList.len(); i < maxMembers.value-1; i++)
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
  @() ready(!ready.value),
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
