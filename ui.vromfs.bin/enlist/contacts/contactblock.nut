from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let colors = require("%ui/style/colors.nut")
let { buttonSound } = require("%ui/style/sounds.nut")
let { squadMembers, isInvitedToSquad, enabledSquad, squadId
} = require("%enlist/squad/squadState.nut")
let { getContactNick } = require("contact.nut")
let { defTxtColor, titleTxtColor, smallPadding, bigPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { approvedUids } = require("%enlist/contacts/contactsWatchLists.nut")
let { mkContactOnlineStatus } = require("contactPresence.nut")
let contactContextMenu = require("contactContextMenu.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let textButton = require("%ui/components/textButton.nut")
let locByPlatform = require("%enlSqGlob/locByPlatform.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(30) })
let faComp = require("%ui/components/faComp.nut")
let { mkArmyIcon } = require("%enlist/soldiers/components/armyPackage.nut")
let { curArmiesList } = require("%enlist/soldiers/model/state.nut")
let { roomIsLobby } = require("%enlist/state/roomState.nut")


let defNickStyle = { color = defTxtColor }.__update(sub_txt)
let activeNickStyle = { color = titleTxtColor }.__update(sub_txt)
let statusCommonStyle = sub_txt
let iconHgt = hdpxi(32)


let playerStatusesIcons = freeze({
  online = {
    icon = "circle"
    color = 0xFF22CF2B
  }
  offline = {
    icon = "circle"
    color = 0xFF960000
  }
  unknown = {
    icon = "circle-o"
    color = 0xFF9E1D1D
  }
})

let playerSquadStatuses = freeze({
  inBattle = {
    text = loc("contact/inBattle")
    color = colors.ContactInBattle
    icon = "gamepad"
  }
  leader = {
    text = loc("squad/Chief")
    color = colors.ContactLeader
    icon = "star"
  }
  offlineInSquad = {
    text = loc("contact/Offline")
    color = colors.ContactOffline
    icon = "times"
  }
  ready = {
    text = loc("contact/Ready")
    color =  colors.ContactReady
    icon = "check"
  }
  unready = {
    text = loc("contact/notReady")
    color = colors.ContactNotReady
    icon = "times"
  }
  invited = {
    text = loc("contact/Invited")
    color = defTxtColor
  }
  unknown = {
    text = loc("contact/Unknown")
    color = defTxtColor
  }
  online = {
    text = loc("contact/Online")
    color = titleTxtColor
  }
  offline = {
    text = loc("contact/Offline")
    color = defTxtColor
  }
})


let userNickname = @(isPlayerOnline, contact) {
  size = [flex(), SIZE_TO_CONTENT]
  behavior = Behaviors.Marquee
  clipChildren = true
  scrollOnHover = true
  rendObj = ROBJ_TEXT
  text = getContactNick(contact)
}.__update(isPlayerOnline ? activeNickStyle : defNickStyle)


let function statusIcon(isPlayerOnline) {
  let iconToShow = isPlayerOnline == null ? playerStatusesIcons.unknown
    : isPlayerOnline ? playerStatusesIcons.online
    : playerStatusesIcons.offline
  let { icon, color } = iconToShow
  return faComp(icon, { fontSize = hdpx(12), color })
}


let statusBlock = @(isPlayerOnline, contact) function() {
  let watch = [enabledSquad, squadMembers, isInvitedToSquad, approvedUids]
  let squadMember = enabledSquad.value && squadMembers.value?[contact.uid]
  let isInvited = isInvitedToSquad.value?[contact.uid]
  local squadStatusText = null

  if (squadMember != null) {
    watch.append(squadMember.state, squadMember.isLeader)
    squadStatusText = squadMember.state.value?.inBattle ? playerSquadStatuses.inBattle
      : squadMember.isLeader.value ? playerSquadStatuses.leader
      : !isPlayerOnline ? playerSquadStatuses.offlineInSquad
      : squadMember.state.value?.ready ? playerSquadStatuses.ready
      : playerSquadStatuses.unready
  }
  else if (isInvited)
    squadStatusText = playerSquadStatuses.invited
  else if (contact.userId in approvedUids.value)
    squadStatusText = isPlayerOnline == null ? playerSquadStatuses.unknown
      : isPlayerOnline ? playerSquadStatuses.online
      : playerSquadStatuses.offline

  if (squadStatusText == null)
    return null

  let { color, text, icon = null } = squadStatusText
  return {
    watch
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    valign = ALIGN_CENTER
    children = [
      isInvited ? spinner
        : icon != null ? faComp(icon, {
          fontSize = statusCommonStyle.fontSize
          color
        })
        : null
      {
        rendObj = ROBJ_TEXT
        text
        color
      }.__update(statusCommonStyle)
    ]
  }
}


let contactActionButton = @(action, group, userId) function() {
  let isVisible = action.mkIsVisible(userId)
  return {
    watch = isVisible
    group
    margin = [0,0,hdpx(2), 0]
    skipDirPadNav = true
    children = (isVisible.value && (S_HOVER != 0))
      ? textButton.Small(locByPlatform(action.locId), @() action.action(userId),
        { key = userId, skipDirPadNav = true })
      : null
  }
}


let function onContactClick(event, contact, contextMenuActions) {
  if (event.button >= 0 && event.button <= 2)
    contactContextMenu.open(contact, event, contextMenuActions)
}


let diceIcon = {
  rendObj = ROBJ_IMAGE
  image = Picture("!ui/skin#dice_solid.svg:{0}:{0}:K".subst((iconHgt * 3 / 4).tointeger()))
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_CENTER
  pos = [hdpx(1), hdpx(2)]
}


let memberAvatarCtor = @(userId) function() {
  let watch = [enabledSquad, squadMembers, squadId, roomIsLobby]
  let res = { watch }
  if (roomIsLobby.value)
    return res
  let squadLeader = enabledSquad.value && squadId.value == userId
    ? squadMembers.value?[userId]
    : null
  if (squadLeader == null)
    return res
  watch.append(squadLeader.state)
  let randomTeam = squadLeader.state.value?.isTeamRandom ?? false
  let curArmy = squadLeader.state.value?.curArmy
  local icon = null
  if (!randomTeam && curArmy)
    icon = mkArmyIcon(curArmy, iconHgt * 4 / 3)
  else
    icon = curArmiesList.value.map(@(army, idx) {
      pos = [iconHgt * 3.0 / 4 * (idx - 1 / 2.0), - iconHgt / 5]
      children = mkArmyIcon(army, iconHgt)
    })
      .reverse()
      .append(diceIcon)
  return res.__update({
    vplace = ALIGN_BOTTOM
    children = icon
  })
}


let function contactBlock(contact, contextMenuActions = [], inContactActions = []) {
  let group = ElemGroup()
  return watchElemState(function(sf) {
    let { userId } = contact.value
    let isPlayerOnline = mkContactOnlineStatus(userId)
    let actionsButtons = {
      flow = FLOW_HORIZONTAL
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      children = inContactActions.map(@(action) contactActionButton(action, group, userId))
    }

    return {
    watch = [contact, isPlayerOnline]
    size = flex()
    rendObj = ROBJ_SOLID
    color = sf & S_HOVER ? colors.BtnBgNormal : colors.statusIconBg
    minHeight = hdpx(62)
    padding = bigPadding
    gap = bigPadding
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick = @(event) onContactClick(event, contact.value, contextMenuActions)
    stopHover = true
    group
    sound = buttonSound
    children = [
      memberAvatarCtor(userId.tointeger())
      {
        size = flex()
        flow = FLOW_VERTICAL
        gap = hdpx(4)
        valign = ALIGN_CENTER
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_HORIZONTAL
            gap = bigPadding
            valign = ALIGN_CENTER
            children = [
              statusIcon(isPlayerOnline.value)
              userNickname(isPlayerOnline.value, contact.value)
            ]
          }
          @() {
            watch = isGamepad
            size = flex()
            valign = ALIGN_BOTTOM
            children = [
              statusBlock(isPlayerOnline.value, contact.value)
              !isGamepad.value && (sf & S_HOVER) != 0 ? actionsButtons : null
            ]
          }
        ]
      }
    ]
  }})
}

return contactBlock
