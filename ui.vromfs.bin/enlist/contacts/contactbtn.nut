from "%enlSqGlob/ui_library.nut" import *

let { fontSmall, fontLarge, fontXXSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { accentColor, disabledIndicatorColor, enabledIndicatorColor, defTxtColor, titleTxtColor,
  activeBgColor, smallPadding, colPart, midPadding, hoverBgColor, panelBgColor, colFull, bigPadding,
  commonBorderRadius
} = require("%enlSqGlob/ui/designConst.nut")
let { buttonSound } = require("%ui/style/sounds.nut")
let { squadMembers, isInvitedToSquad, enabledSquad, squadId
} = require("%enlist/squad/squadState.nut")
let { getContactNick } = require("contact.nut")
let { approvedUids } = require("%enlist/contacts/contactsWatchLists.nut")
let { mkContactOnlineStatus } = require("contactPresence.nut")
let contactActionsMenu = require("contactActionsMenu.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { FAButton } = require("%ui/components/txtButton.nut")
let mkSpinner = require("%ui/components/mkSpinner.nut")
let faComp = require("%ui/components/faComp.nut")
let { mkArmyIcon } = require("%enlist/soldiers/components/armyPackage.nut")
let { curArmiesList } = require("%enlist/soldiers/model/state.nut")
let { roomIsLobby } = require("%enlist/state/roomState.nut")


let defNickStyle = { color = defTxtColor }.__update(fontLarge)
let activeNickStyle = { color = titleTxtColor }.__update(fontLarge)
let statusCommonStyle = fontSmall
let iconHgt = hdpxi(32)


let playerStatusIcons = freeze({
  online = {
    icon = "circle"
    color = enabledIndicatorColor
  }
  offline = {
    icon = "circle"
    color =  disabledIndicatorColor
  }
  unknown = {
    icon = "circle-o"
    color = defTxtColor
  }
})

let playerStatuses = freeze({
  inBattle = {
    text = loc("contact/inBattle")
    color = titleTxtColor
    icon = "gamepad"
  }
  leader = {
    text = loc("squad/Chief")
    color = accentColor
    icon = "star"
  }
  offlineInSquad = {
    text = loc("contact/Offline")
    color = defTxtColor
    icon = "times"
  }
  ready = {
    text = loc("contact/Ready")
    color =  titleTxtColor
    icon = "check"
  }
  unready = {
    text = loc("contact/notReady")
    color = defTxtColor
    icon = "times"
  }
  invited = {
    text = loc("contact/Invited")
    color = defTxtColor
  }
  offline = {
    text = loc("contact/Offline")
    color = defTxtColor
  }
  online = {
    text = loc("contact/Online")
    color = titleTxtColor
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


let function mkStatusIcon(isPlayerOnline) {
  let iconToShow = isPlayerOnline == null ? playerStatusIcons.unknown
    : isPlayerOnline ? playerStatusIcons.online
    : playerStatusIcons.offline
  let { icon, color } = iconToShow
  return faComp(icon, { fontSize = fontXXSmall.fontSize, color })
}


let function statusBlock(isPlayerOnline, contact) {
  let statusIcon = mkStatusIcon(isPlayerOnline)
  return function() {
    let watch = [enabledSquad, squadMembers, isInvitedToSquad, approvedUids]
    let squadMember = enabledSquad.value && squadMembers.value?[contact.uid]
    let isInvited = isInvitedToSquad.value?[contact.uid]
    local squadStatusText = null
    if (squadMember != null) {
      watch.append(squadMember.state, squadMember.isLeader)
      squadStatusText = squadMember.state.value?.inBattle ? playerStatuses.inBattle
        : squadMember.isLeader.value ? playerStatuses.leader
        : !isPlayerOnline ? playerStatuses.offlineInSquad
        : squadMember.state.value?.ready ? playerStatuses.ready
        : playerStatuses.unready
    }
    else if (isInvited)
      squadStatusText = playerStatuses.invited
    else if (contact.userId in approvedUids.value){
      squadStatusText = isPlayerOnline == null ? null
        : isPlayerOnline ? playerStatuses.online
        : playerStatuses.offline
    }


    let { color = null, text = "" } = squadStatusText
    return {
      watch
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      valign = ALIGN_CENTER
      children = [
        text == "" ? null : {
          rendObj = ROBJ_TEXT
          text
          color
        }.__update(statusCommonStyle)
        isInvited ?  mkSpinner(defNickStyle.fontSize) : statusIcon
      ]
    }
  }}


let contactActionButton = @(action, userId) function() {
  let isVisible = action.mkIsVisible(userId)
  return {
    watch = isVisible
    children = isVisible.value
      ? FAButton("plus", @() action.action(userId),{
          btnWidth = colPart(0.6)
          btnHeight = colPart(0.6)
          key = userId
          skipDirPadNav = true
        })
      : null
  }
}


let function onContactClick(event, contact, contextMenuActions) {
  if (event.button >= 0 && event.button <= 2)
    contactActionsMenu.open(contact, event, contextMenuActions)
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


let contactBtn = @(contact, contextMenuActions = [], inContactActions = [])
  watchElemState(function(sf) {
    let { userId } = contact.value
    let isPlayerOnline = mkContactOnlineStatus(userId)
    let actionsButtons = {
      flow = FLOW_HORIZONTAL
      hplace = ALIGN_RIGHT
      vplace = ALIGN_CENTER
      children = inContactActions.map(@(action) contactActionButton(action, userId))
    }

    return {
      watch = [contact, isPlayerOnline]
      size = [colFull(6), colFull(1)]
      rendObj = ROBJ_SOLID
      color = sf & S_HOVER ? hoverBgColor : panelBgColor
      padding = [midPadding, bigPadding]
      gap = bigPadding
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      behavior = Behaviors.Button
      onClick = @(event) onContactClick(event, contact.value, contextMenuActions)
      stopHover = true
      sound = buttonSound
      children = [
        memberAvatarCtor(userId.tointeger())
        {
          size = flex()
          flow = FLOW_VERTICAL
          gap = { size = flex() }
          valign = ALIGN_CENTER
          children = [
            userNickname(isPlayerOnline.value, contact.value)
            statusBlock(isPlayerOnline.value, contact.value)
          ]
        }
        !isGamepad.value && (sf & S_HOVER) ? actionsButtons : null
      ]
    }
  })


let squadLeaderSign = {
  rendObj = ROBJ_VECTOR_CANVAS
  size = [colPart(0.29), colPart(0.29)]
  color = accentColor
  fillColor = accentColor
  commands =  [[VECTOR_POLY, 0, 100, 100, 0, 0, 0]]
}


let smallContactBtn = @(contact, contextMenuActions) watchElemState(function(sf) {
  let { userId } = contact.value
  let isPlayerOnline = mkContactOnlineStatus(userId)
  let uid = userId.tointeger()
  let squadMember = enabledSquad.value && squadMembers.value?[uid]
  let isReady = squadMember?.state.value.ready ?? false
  let isLeader = enabledSquad.value && squadId.value == uid
  return {
    watch = [contact, isPlayerOnline, enabledSquad, squadId, squadMembers]
    size = [colFull(3), colPart(0.854)]
    rendObj = ROBJ_BOX
    fillColor = sf & S_HOVER ? hoverBgColor : panelBgColor
    borderWidth = 0
    borderRadius = commonBorderRadius
    behavior = Behaviors.Button
    onClick = @(event) onContactClick(event, contact.value, contextMenuActions)
    sound = buttonSound
    clipChildren = true
    children = [
      isLeader ? squadLeaderSign : null
      {
        size = flex()
        flow = FLOW_VERTICAL
        padding = [midPadding, colPart(0.29)]
        gap = { size = flex() }
        valign = ALIGN_CENTER
        children = [
          userNickname(isPlayerOnline.value, contact.value)
          statusBlock(isPlayerOnline.value, contact.value)
        ]
      }
      !isReady ? null : {
        rendObj = ROBJ_SOLID
        color = activeBgColor
        vplace = ALIGN_BOTTOM
        size = [flex(), colPart(0.03)]
      }
    ]
  }
})

return {
  contactBtn
  smallContactBtn
}
