from "%enlSqGlob/ui_library.nut" import *


let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let colors = require("%ui/style/colors.nut")
let { bigPadding, titleTxtColor, defTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let textInput = require("%ui/components/textInput.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let fontIconButton = require("%ui/components/fontIconButton.nut")
let txt = require("%ui/components/text.nut").dtext
let userInfo = require("%enlSqGlob/userInfo.nut")
let { popupBlockStyle, defPopupBlockPos } = require("%enlist/popup/popupBlock.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let { INVITE_TO_PSN_FRIENDS, CANCEL_INVITE, APPROVE_INVITE, ADD_TO_BLACKLIST, INVITE_TO_FRIENDS,
  INVITE_TO_SQUAD, REMOVE_FROM_BLACKLIST, COMPARE_ACHIEVEMENTS, INVITE_TO_ROOM, REVOKE_INVITE,
  REJECT_INVITE, REMOVE_FROM_SQUAD, REMOVE_FROM_FRIENDS, PROMOTE_TO_LEADER, SHOW_USER_LIVE_PROFILE,
  REMOVE_FROM_BLACKLIST_PSN, REMOVE_FROM_BLACKLIST_XBOX
} = require("contactActions.nut")
let contactBlock = require("contactBlock.nut")
let { Contact, getContactNick } = require("contact.nut")
let { approvedUids, psnApprovedUids, xboxApprovedUids, friendsOnlineUids, requestsToMeUids,
  myRequestsUids, rejectedByMeUids, blockedUids, isInternalContactsAllowed
} = require("%enlist/contacts/contactsWatchLists.nut")
let { searchContacts, isContactsManagementEnabled, isContactsEnabled,
  isOnlineContactsSearchEnabled, searchContactsResults } = require("contactsState.nut")
let buildContactsButton = require("buildContactsButton.nut")
let buildCounter = require("buildCounter.nut")
let {safeAreaBorders} = require("%enlist/options/safeAreaState.nut")
let { is_sony } = require("%dngscripts/platform.nut")
let locByPlatform = require("%enlSqGlob/locByPlatform.nut")
let { onlineStatus, isContactOnline } = require("contactPresence.nut")
let JB = require("%ui/control/gui_buttons.nut")

const CONTACTLIST_MODAL_UID = "contactsListWnd_modalUid"
let contactListWidth = hdpx(300)
let defTxtStyle = { color = defTxtColor }.__update(sub_txt)
let headerTxtStyle = { color = titleTxtColor }.__update(body_txt)


const APPROVED_TAB = "approved"
const SEARCH_RESULT_TAB = "search_results"
const INVITES_TAB = "invites"
const BLACKLIST_TAB = "myBlacklist"

let display = Watched(APPROVED_TAB)
let windowPadding = fsh(2)
let searchPlayer = Watched("")


let headerTxt = @(text) txt(text, {
  padding = [hdpx(2), fsh(1)]
  behavior = [Behaviors.Marquee,Behaviors.Button]
  size = [flex(), SIZE_TO_CONTENT]
  speed = hdpx(100)
  scrollOnHover = true
}.__update(defTxtStyle))


let closeWnd = @() modalPopupWnd.remove(CONTACTLIST_MODAL_UID)


let function resetSearch() {
  display(APPROVED_TAB)
  searchPlayer("")
  searchContactsResults({})
}

let closeButton = fontIconButton("close", {
  onClick = function() {
    resetSearch()
    closeWnd()
  }
})


let header = @() {
  watch = userInfo
  size = [flex(), fsh(4)]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  valign = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  padding = [bigPadding, bigPadding, bigPadding, windowPadding]
  color = colors.WindowHeader
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXT
      color = colors.Inactive
      text = userInfo.value?.nameorig == null
        ? loc("contactsHdr")
        : userInfo.value.nameorig
      clipChildren = true
      behavior = [Behaviors.Marquee, Behaviors.Button]
      scrollOnHover = true
    }.__update(headerTxtStyle)
    closeButton
  ]
}

let function searchCallback() {
  if (searchPlayer.value.len() > 0)
    display(SEARCH_RESULT_TAB)
}

let function doSearch(nick) {
  if (nick.len() == 0)
    resetSearch()
  else
    searchContacts(nick, searchCallback)
}

display.subscribe(function(val) {
  if (val == SEARCH_RESULT_TAB)
    return
  searchPlayer("")
  searchContactsResults({})
})

let exitSearchButton = fontIconButton("close", {
  onClick = resetSearch
  validateStaticText = false
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  margin = [0, fsh(0.5)]
})

let function clearOrExitWnd() {
  if (searchPlayer.value == "")
    closeWnd()
  else
    resetSearch()
}

let searchBlock = @() {
  watch = display
  size = [flex(), SIZE_TO_CONTENT]
  margin = [hdpx(2), windowPadding]
  children = [
    textInput(searchPlayer, {
      placeholder = loc(isOnlineContactsSearchEnabled
        ? "contacts/friendSearch"
        : "contacts/mailInvite")
      onChange = doSearch
      onReturn = @() doSearch(searchPlayer.value)
      onEscape = clearOrExitWnd
    }.__update(defTxtStyle))
    display.value != SEARCH_RESULT_TAB || searchPlayer.value.len() == 0 ? null : exitSearchButton
  ]
}

let counterText = @(count) count > 0 ? count : null
let placeholder = txt(loc("contacts/list_empty"), {
  color=colors.Inactive,
  margin = [fsh(1), windowPadding]
}.__update(defTxtStyle))

let friendsButton = buildContactsButton({
  symbol = "users"
  onClick = @() display(APPROVED_TAB)
  selected = Computed(@() display.value == APPROVED_TAB)
  children = buildCounter(Computed(@() counterText(friendsOnlineUids.value.len())))
})

let friendsKeys = []
if (isInternalContactsAllowed) {
  friendsKeys.append({
    name = "friends"
    uidsWatch = [approvedUids, xboxApprovedUids]
    placeholder
    inContactActions = [INVITE_TO_SQUAD]
    contextMenuActions = [
      INVITE_TO_PSN_FRIENDS, REMOVE_FROM_SQUAD, REVOKE_INVITE, INVITE_TO_ROOM,
      INVITE_TO_SQUAD, PROMOTE_TO_LEADER,REMOVE_FROM_FRIENDS, COMPARE_ACHIEVEMENTS,
      SHOW_USER_LIVE_PROFILE
    ]
  })
}

if (is_sony)
  friendsKeys.append({
    name = "contacts"
    uidsWatch = psnApprovedUids
    inContactActions = [INVITE_TO_FRIENDS]
    contextMenuActions = [
      INVITE_TO_FRIENDS, ADD_TO_BLACKLIST, REMOVE_FROM_SQUAD, REVOKE_INVITE, INVITE_TO_SQUAD,
      PROMOTE_TO_LEADER, SHOW_USER_LIVE_PROFILE
    ]
  })

let invitationsButton = buildContactsButton({
  symbol = "user-plus"
  onClick = @() display(INVITES_TAB)
  selected = Computed(@() display.value == INVITES_TAB)
  children = buildCounter(Computed(@() counterText(
    requestsToMeUids.value.len() + myRequestsUids.value.len() + rejectedByMeUids.value.len()
  )))
})

let myBlacklist = buildContactsButton({
  symbol = "user-times"
  onClick = @() display(BLACKLIST_TAB)
  selected = Computed(@() display.value ==BLACKLIST_TAB)
  children = buildCounter(Computed(@() counterText( blockedUids.value.len() )))
})


let invitesKeys = [
  { name = "requestsToMe",
    uidsWatch = requestsToMeUids,
    inContactActions = [APPROVE_INVITE],
    contextMenuActions = [APPROVE_INVITE, REJECT_INVITE, INVITE_TO_SQUAD,
      ADD_TO_BLACKLIST, COMPARE_ACHIEVEMENTS]
  }
  { name = "myRequests",
    uidsWatch = myRequestsUids,
    inContactActions = [CANCEL_INVITE],
    contextMenuActions = [CANCEL_INVITE, INVITE_TO_SQUAD, REVOKE_INVITE, ADD_TO_BLACKLIST,
      COMPARE_ACHIEVEMENTS]
  }
  { name = "rejectedByMe",
    uidsWatch = rejectedByMeUids,
    inContactActions = [],
    contextMenuActions = [APPROVE_INVITE, INVITE_TO_FRIENDS, INVITE_TO_SQUAD,
      ADD_TO_BLACKLIST, COMPARE_ACHIEVEMENTS]
  }
]

let nickToLower = memoize(@(v) getContactNick(v).tolower(), null,
  persist("stringsLowerCache", @() {}))
let sortContacts = @(contactsArr, onlineStatusVal) contactsArr.sort(@(a, b)
  isContactOnline(b.value.userId, onlineStatusVal)
    <=> isContactOnline(a.value.userId, onlineStatusVal)
  || nickToLower(a) <=> nickToLower(b)
)

let mkContactsGroupContent = @(groupKeys) function() {
  let children = []
  let watch = [onlineStatus, searchPlayer]
  let searchPlayerVal = searchPlayer.value.tolower()
  foreach (v in groupKeys) {
    let { name, uidsWatch, inContactActions, contextMenuActions } = v
    let watchesList = typeof uidsWatch == "array" ? uidsWatch : [uidsWatch]

    local contactsArr = []
    foreach (w in watchesList)
      contactsArr.extend(w.value.keys().map(@(userId) Contact(userId)))

    if (searchPlayerVal != "")
      contactsArr = contactsArr.filter(@(c)
        c.value.realnick.tolower().indexof(searchPlayerVal) != null)

    contactsArr = sortContacts(contactsArr, onlineStatus.value)
      .map(@(contact) contactBlock(contact, contextMenuActions, inContactActions))

    children.append(headerTxt(locByPlatform($"contacts/{name}")))
    if (contactsArr.len() == 0)
      children.append(placeholder)
    else
      children.extend(contactsArr)

    watch.extend(watchesList)
  }

  return {
    watch
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children
  }
}

let modesList = [
  { option = APPROVED_TAB, comp = friendsButton },
  { option = INVITES_TAB, comp = invitationsButton},
  { option =BLACKLIST_TAB, comp = myBlacklist}
]

let function modeSwitcher() {
  return isContactsManagementEnabled ?
    {
      size = [flex(), fsh(5)]
      halign = ALIGN_RIGHT
      valign = ALIGN_BOTTOM
      margin = [bigPadding, windowPadding, 0, windowPadding]
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = modesList.map(@(m) m.comp)
    }
  : {}
}

let searchTbl = [{
  uidsWatch = searchContactsResults,
  name = "search_results",
  placeholder,
  inContactActions = [INVITE_TO_FRIENDS],
  contextMenuActions = [
    INVITE_TO_FRIENDS, INVITE_TO_PSN_FRIENDS, REMOVE_FROM_FRIENDS, APPROVE_INVITE,
    INVITE_TO_SQUAD, CANCEL_INVITE, REMOVE_FROM_BLACKLIST, REMOVE_FROM_BLACKLIST_PSN,
    REMOVE_FROM_BLACKLIST_XBOX, ADD_TO_BLACKLIST, SHOW_USER_LIVE_PROFILE,COMPARE_ACHIEVEMENTS
  ]
}]

let myBlackTbl = [{
  uidsWatch = [blockedUids]
  name =BLACKLIST_TAB,
  placeholder,
  inContactActions = [REMOVE_FROM_BLACKLIST, REMOVE_FROM_BLACKLIST_PSN, REMOVE_FROM_BLACKLIST_XBOX],
  contextMenuActions = [REMOVE_FROM_BLACKLIST, REMOVE_FROM_BLACKLIST_PSN,
    REMOVE_FROM_BLACKLIST_XBOX, SHOW_USER_LIVE_PROFILE, COMPARE_ACHIEVEMENTS]
}]

let isContactsWndVisible = Watched(false)
let popupsOffset = [-contactListWidth + defPopupBlockPos[0], defPopupBlockPos[1]]
isContactsWndVisible.subscribe(@(v) popupBlockStyle.mutate(@(style)
  style.pos <- (v ? popupsOffset : defPopupBlockPos)))

let tabsContent = {
  search_results = mkContactsGroupContent(searchTbl)
  myBlacklist    = mkContactsGroupContent(myBlackTbl)
  approved       = mkContactsGroupContent(friendsKeys)
  invites        = mkContactsGroupContent(invitesKeys)
}

let contactsBlock = @() {
  watch = display
  size = [contactListWidth, flex()]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = colors.WindowBlur
  valign = ALIGN_BOTTOM
  stopMouse = true
  key = "contactsBlock"
  onAttach = @() isContactsWndVisible(true)
  onDetach = @() isContactsWndVisible(false)
  hotkeys = [[$"^{JB.B} | Esc", { action = clearOrExitWnd }]]

  children = {
    size = flex()
    rendObj = ROBJ_SOLID
    color = colors.WindowContacts
    flow = FLOW_VERTICAL
    children = [
      header
      {
        flow = FLOW_VERTICAL
        size = flex()
        children = [
          modeSwitcher
          searchBlock
          makeVertScroll(tabsContent?[display.value])
        ]
      }
    ]
  }
}


let curModeIdx = Computed(@() modesList.findindex(@(m) m.option == display.value) ?? -1)
let changeMode = @(delta) display(modesList[(curModeIdx.value + delta + modesList.len())
  % modesList.len()].option)

let btnContactsNav = @() {
  size = SIZE_TO_CONTENT
  children = isContactsManagementEnabled ? {
    hotkeys = [
      ["^J:RB | Tab", {action = @() changeMode(1), description = loc("contacts/next_mode")} ],
      ["^J:LB | L.Shift Tab | R.Shift Tab", { action = @() changeMode(-1),
        description=loc("contacts/prev_mode")} ]
    ]
  } : null
}


let popupBg = { rendObj = ROBJ_WORLD_BLUR_PANEL, fillColor = colors.ModalBgTint }
let function show(){
  if (!isContactsEnabled)
    return
  let bottomOffset = safeAreaBorders.value[2] + bigPadding
  let popupHeight = sh(95) - bottomOffset
  modalPopupWnd.add([sw(100), sh(100) - bottomOffset],
  {
    size = [SIZE_TO_CONTENT, popupHeight]
    uid = CONTACTLIST_MODAL_UID
    fillColor = Color(0,0,0)
    padding = 0
    popupFlow = FLOW_HORIZONTAL
    popupValign = ALIGN_BOTTOM
    popupOffset = 0
    margin = 0
    children = [
      contactsBlock
      btnContactsNav
    ]
    popupBg = popupBg
  })
}

return show
