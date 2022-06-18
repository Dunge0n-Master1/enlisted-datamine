from "%enlSqGlob/ui_library.nut" import *

let { sub_txt, fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let colors = require("%ui/style/colors.nut")
let {buttonSound} = require("%ui/style/sounds.nut")
let fa = require("%darg/components/fontawesome.map.nut")

let { squadMembers, isInvitedToSquad, enabledSquad } = require("%enlist/squad/squadState.nut")
let { getContactNick } = require("contact.nut")
let { approvedUids } = require("%enlist/contacts/contactsWatchLists.nut")
let { mkContactOnlineStatus } = require("contactPresence.nut")
let contactContextMenu = require("contactContextMenu.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let textButton = require("%ui/components/textButton.nut")
let locByPlatform = require("%enlSqGlob/locByPlatform.nut")


// FIXME: Need to devide contact view between games
let contactBlock = kwarg(function contactBlock_impl(contact, inContactActions = [],
  contextMenuActions = [], style = {}, bottomLineChild = null, hasStatusBlock = true,
  memberAvatarCtor = null /*@(uid)*/, namePrefixCtr = null /*@(contact)*/
) {
  let group = ElemGroup()
  let { userId } = contact.value
  let status = mkContactOnlineStatus(userId)
  let presenceIcon = @() {
    watch = [contact, status]
    size = [fontH(100), SIZE_TO_CONTENT]
    rendObj = ROBJ_INSCRIPTION
    validateStaticText = false
    font = fontawesome.font
    color = status.value == null ? Color(104, 86, 86)
      : status.value ? Color(31, 205, 39)
      : Color(154, 26, 26)
    text = status.value != null ? fa["circle"] : fa["circle-o"]
    fontSize = hdpx(10)
  }

  let stateFlags = Watched(0)
  let function statusBlock() {
    local iconParams = null
    local textParams = null
    let watch = [enabledSquad, squadMembers, isInvitedToSquad,
      contact, status, approvedUids]
    let squadMember = enabledSquad.value && squadMembers.value?[contact.value.uid]
    let isOnline = status.value == true

    if (squadMember) {
      if (squadMember.state.value?.inBattle) {
        iconParams = { color = colors.ContactInBattle, text = fa["gamepad"] }
        textParams = { text = loc("contact/inBattle") }
      }
      else if (squadMember.isLeader.value) {
        iconParams = { color = colors.ContactLeader, text = fa["star"] }
        textParams = { text = loc("squad/Chief") }
      }
      else if (!isOnline) {
        iconParams = { color = colors.ContactOffline, text = fa["times"] }
        textParams = { text = loc("contact/Offline") }
      }
      else if (squadMember.state.value?.ready) {
        iconParams = { color = colors.ContactReady, text = fa["check"] }
        textParams = { text = loc("contact/Ready") }
      }
      else {
        iconParams = { color = colors.ContactNotReady, text = fa["times"] }
        textParams = { text = loc("contact/notReady") }
      }
      watch.append(squadMember.isLeader, squadMember.state)
    }
    else if (isInvitedToSquad.value?[contact.value.uid]) {
      iconParams = {
        size = [fontH(100), SIZE_TO_CONTENT]
        margin = [0, fontH(10), 0, 0]
        key = userId
        color = colors.ContactOffline
        text = fa["spinner"]
        transform = {}
        animations = [
          { prop=AnimProp.rotate, from = 0, to = 360, duration = 1, play = true, loop = true, easing = Discrete8 }
        ]
      }
      textParams = { text = loc("contact/Invited") }
    }
    else if (userId in approvedUids.value)
      textParams = { text = status.value == true ? loc("contact/Online")
        : status.value == null ? loc("contact/Unknown")
        : loc("contact/Offline") }

    let children = []
    if (iconParams)
      children.append({
        size = SIZE_TO_CONTENT
        rendObj = ROBJ_INSCRIPTION
        validateStaticText = false
      }.__update(fontawesome, iconParams))
    if (textParams)
      children.append({
        size = SIZE_TO_CONTENT
        rendObj = ROBJ_TEXT
        color = colors.ContactOffline
      }.__update(sub_txt, textParams))
    return {
      size = [flex(), SIZE_TO_CONTENT]
      watch = watch
      flow = FLOW_HORIZONTAL
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          gap = hdpx(5)
          flow = FLOW_HORIZONTAL
          halign = ALIGN_LEFT
          valign = ALIGN_CENTER
          children
        }
        squadMember && (bottomLineChild != null) ? bottomLineChild(squadMember) : null
      ]
    }
  }

  let function contactActionButton(action) {
    let isVisible = action.mkIsVisible(userId)
    return @() {
      watch = [isVisible, stateFlags]
      group = group
      margin = [0,0,hdpx(2), 0]
      skipDirPadNav = true
      children = (isVisible.value && (stateFlags.value & S_HOVER))
        ? textButton.Small(locByPlatform(action.locId), @() action.action(userId), { key = userId, skipDirPadNav = true })
        : null
    }
  }

  let actionsButtons = {
    flow = FLOW_HORIZONTAL
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    children = inContactActions.map(contactActionButton)
  }

  let function onContactClick(event) {
    if (event.button >= 0 && event.button <= 2)
      contactContextMenu.open(contact.value, event, contextMenuActions)
  }

  let userNickname = @() {
    watch = [contact, status]
    size = [flex(), fontH(120)]
    behavior = Behaviors.Marquee
    clipChildren = true
    scrollOnHover = true
    rendObj = ROBJ_TEXT
    group = group
    text = getContactNick(contact)
    color = contact.value.uid == userInfo.value?.userId ? colors.UserNameColor
              : status.value == true ? colors.Active
              : colors.Inactive
  }.__update(sub_txt)
  let memberAvatar = memberAvatarCtor?(contact.value.uid)

  let namePrefix = namePrefixCtr?(contact)

  return @() {
    size = flex()
    rendObj = style?.rendObj ?? ROBJ_SOLID
    color = (stateFlags.value & S_HOVER) ? (style?.hoverColor ?? colors.BtnBgNormal) : (style?.bgColor ?? colors.statusIconBg)
    minHeight = hdpx(62)
    padding = hdpx(4)
    gap = hdpx(4)
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      memberAvatar
      {
        size = flex()
        flow = FLOW_VERTICAL
        gap = hdpx(4)
        valign = ALIGN_CENTER
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_HORIZONTAL
            gap = hdpx(4)
            valign = ALIGN_CENTER
            children = [presenceIcon, namePrefix, userNickname]
          }
          hasStatusBlock
            ? {
                size = flex()
                valign = ALIGN_BOTTOM
                children = [
                  statusBlock
                  !isGamepad.value ? actionsButtons : null
                ]
              }
            : null
        ]
      }
    ]
    behavior = Behaviors.Button
    stopHover = true
    group = group
    onClick = onContactClick
    onElemState = @(sf) stateFlags.update(sf)
    watch = [ stateFlags, contact, isGamepad ]
    sound = buttonSound
  }
})

return contactBlock
