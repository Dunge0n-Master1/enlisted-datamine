from "%enlSqGlob/ui_library.nut" import *


let { fontMedium, fontSmall, fontXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { bigPadding, titleTxtColor, defTxtColor, topWndBgColor, bottomWndBgColor, sidePadding,
  panelBgColor, hoverPanelBgColor, colPart, commonBtnHeight, accentColor, colFull, smallPadding,
  darkTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let { mkColoredGradientY } = require("%enlSqGlob/ui/gradients.nut")
let textInput = require("%ui/components/textInput.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let fontIconButton = require("%ui/components/fontIconButton.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { popupBlockStyle, defPopupBlockPos } = require("%enlist/popup/popupBlock.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let { INVITE_TO_PSN_FRIENDS, CANCEL_INVITE, APPROVE_INVITE, ADD_TO_BLACKLIST, INVITE_TO_FRIENDS,
  INVITE_TO_SQUAD, REMOVE_FROM_BLACKLIST, COMPARE_ACHIEVEMENTS, INVITE_TO_ROOM, REVOKE_INVITE,
  REJECT_INVITE, REMOVE_FROM_SQUAD, REMOVE_FROM_FRIENDS, PROMOTE_TO_LEADER, SHOW_USER_LIVE_PROFILE,
  REMOVE_FROM_BLACKLIST_PSN, REMOVE_FROM_BLACKLIST_XBOX
} = require("contactActions.nut")
let { contactBtn } = require("contactBtn.nut")
let { Contact, getContactNick } = require("contact.nut")
let { approvedUids, psnApprovedUids, xboxApprovedUids, friendsOnlineUids, requestsToMeUids,
  myRequestsUids, rejectedByMeUids, blockedUids, isInternalContactsAllowed
} = require("%enlist/contacts/contactsWatchLists.nut")
let { searchContacts, isContactsManagementEnabled, isContactsEnabled,
  isOnlineContactsSearchEnabled, searchContactsResults } = require("contactsState.nut")
let {safeAreaBorders} = require("%enlist/options/safeAreaState.nut")
let { is_sony } = require("%dngscripts/platform.nut")
let { onlineStatus, isContactOnline } = require("contactPresence.nut")
let JB = require("%ui/control/gui_buttons.nut")
let locByPlatform = require("%enlSqGlob/locByPlatform.nut")
let mkCheckbox = require("%ui/components/mkCheckbox.nut")
let hasFriendOnlineNotification = require("%enlist/contacts/onlineNotifications.nut")


const CONTACTLIST_MODAL_UID = "contactsListWnd_modalUid"
let contactListWidth = colFull(6)
let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let bigActiveTxtStyle = { color = darkTxtColor }.__update(fontMedium)
let bigHoverTxtStyle = { color = titleTxtColor }.__update(fontMedium)
let bigCommonTxtStyle = { color = defTxtColor }.__update(fontMedium)
let nickTxtStyle = { color = titleTxtColor }.__update(fontXLarge)
let wndGradient = mkColoredGradientY(topWndBgColor, bottomWndBgColor)
let contactBtnHeight = colFull(1)
let invitesCount = Computed(@() {}.__update(requestsToMeUids.value,
  myRequestsUids.value, rejectedByMeUids.value))


const APPROVED_TAB = "approved"
const SEARCH_RESULT_TAB = "search_results"
const INVITES_TAB = "invites"
const BLACKLIST_TAB = "myBlacklist"


let curTab = Watched(APPROVED_TAB)
let searchPlayer = Watched("")
let contactTabs = [
  {
    header = loc("contacts/contacts")
    id = APPROVED_TAB
    action = @() curTab(APPROVED_TAB)
    countWatched = friendsOnlineUids
  }
  {
    header = loc("contacts/requests")
    id = INVITES_TAB
    action = @() curTab(INVITES_TAB)
    countWatched = invitesCount
  }
  {
    header = loc("contacts/myBlacklist")
    id = BLACKLIST_TAB
    action = @() curTab(BLACKLIST_TAB)
    countWatched = blockedUids
  }
]


let mkTabContactsCounter = @(countWatched) function() {
  let count = countWatched.value.len()
  return {
    watch = countWatched
    rendObj = ROBJ_TEXT
    padding = [0, smallPadding]
    hplace = ALIGN_RIGHT
    vplace = ALIGN_TOP
    text = count <= 0 ? "" : count
  }.__update(defTxtStyle)
}


let mkContactTab = @(tab) watchElemState(function(sf) {
  let { header, action, countWatched, id } = tab
  let isSelected = curTab.value == id
  return {
    watch = curTab
    size = [flex(), commonBtnHeight]
    rendObj = ROBJ_SOLID
    color = isSelected ? accentColor
      : sf & S_HOVER ? hoverPanelBgColor
      : panelBgColor
    behavior = Behaviors.Button
    onClick = action
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      mkTabContactsCounter(countWatched)
      {
        rendObj = ROBJ_TEXT
        text = header
      }.__update(isSelected || (sf & S_ACTIVE) != 0 ? bigActiveTxtStyle
        : sf & S_HOVER ? bigHoverTxtStyle
        : bigCommonTxtStyle)
    ]
  }
})


let closeWnd = @() modalPopupWnd.remove(CONTACTLIST_MODAL_UID)


let function resetSearch() {
  curTab(APPROVED_TAB)
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
  size = [flex(), contactBtnHeight]
  padding = bigPadding
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXT
      text = userInfo.value?.nameorig == null
        ? loc("contactsHdr")
        : userInfo.value.nameorig
    }.__update(nickTxtStyle)
    closeButton
  ]
}

let function searchCallback() {
  if (searchPlayer.value.len() > 0)
    curTab(SEARCH_RESULT_TAB)
}

let function doSearch(nick) {
  if (nick.len() == 0)
    resetSearch()
  else
    searchContacts(nick, searchCallback)
}

curTab.subscribe(function(val) {
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
  watch = curTab
  size = [flex(), SIZE_TO_CONTENT]
  padding = [0, bigPadding]
  children = [
    textInput(searchPlayer, {
      placeholder = loc(isOnlineContactsSearchEnabled
        ? "contacts/friendSearch"
        : "contacts/mailInvite")
      textmargin = bigPadding
      onChange = doSearch
      onReturn = @() doSearch(searchPlayer.value)
      onEscape = clearOrExitWnd
    }.__update(defTxtStyle))
    curTab.value != SEARCH_RESULT_TAB || searchPlayer.value.len() == 0 ? null : exitSearchButton
  ]
}


let placeholder = {
  rendObj = ROBJ_SOLID
  color = panelBgColor
  valign = ALIGN_CENTER
  size = [flex(), contactBtnHeight]
  padding = [bigPadding, bigPadding * 2]
  children = {
    rendObj = ROBJ_TEXT
    text = loc("contacts/list_empty")
  }.__update(defTxtStyle)
}


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
      .map(@(contact) contactBtn(contact, contextMenuActions, inContactActions))

    children.append({
      rendObj = ROBJ_TEXT
      text = locByPlatform($"contacts/{name}")
      padding = bigPadding
    }.__update(bigActiveTxtStyle))
    if (contactsArr.len() == 0) {
      children.append(placeholder)
    }
    else
      children.extend(contactsArr)

    watch.extend(watchesList)
  }

  return {
    watch
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = colPart(0.04)
    children
  }
}


let modeSwitcher = !isContactsManagementEnabled ? null
  : {
      size = [flex(), commonBtnHeight]
      flow = FLOW_HORIZONTAL
      children = contactTabs.map(mkContactTab)
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
  uidsWatch = blockedUids
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


let trackFriendsOnline = {
  size = [flex(), SIZE_TO_CONTENT]
  padding = bigPadding
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    mkCheckbox(hasFriendOnlineNotification)
    {
      rendObj = ROBJ_TEXTAREA
      size = [flex(), SIZE_TO_CONTENT]
      behavior = Behaviors.TextArea
      text = loc("contacts/friendNotificaion")
    }
  ]
}


let contactsBlock = @() {
  watch = curTab
  rendObj = ROBJ_SOLID
  color = panelBgColor
  size = [colFull(6), flex()]
  hplace = ALIGN_RIGHT
  stopMouse = true
  key = "contactsBlock"
  onAttach = @() isContactsWndVisible(true)
  onDetach = @() isContactsWndVisible(false)
  hotkeys = [[$"^{JB.B} | Esc", { action = clearOrExitWnd }]]
  flow = FLOW_VERTICAL
  gap = colPart(0.04)
  children = [
    header
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        modeSwitcher
        searchBlock
        trackFriendsOnline
      ]
    }
    makeVertScroll(tabsContent?[curTab.value])
  ]
}


let function changeMode(delta) {
  let tabsCount = contactTabs.len()
  let curIdx = contactTabs.findindex(@(v) v.id == curTab.value)
  if (curIdx != null) {
    let nextIdx = (curIdx + delta + tabsCount) % tabsCount
    curTab(contactTabs[nextIdx].id)
  }
}


let btnContactsNav = {
  children = isContactsManagementEnabled ? {
    hotkeys = [
      ["^J:RB | Tab", {action = @() changeMode(1), description = loc("contacts/next_mode")} ],
      ["^J:LB | L.Shift Tab | R.Shift Tab", { action = @() changeMode(-1),
        description=loc("contacts/prev_mode")} ]
    ]
  } : null
}


let function show(){
  if (!isContactsEnabled)
    return
  let rightOffset = safeAreaBorders.value[0] + sidePadding
  modalPopupWnd.add([sw(100), sh(10)],
  {
    size = [flex(), sh(80)]
    uid = CONTACTLIST_MODAL_UID
    popupFlow = FLOW_VERTICAL
    margin = [0, rightOffset, 0, 0]
    padding = 0
    popupBg = {
      rendObj = ROBJ_IMAGE
      image = wndGradient
    }
    children = [
      contactsBlock
      btnContactsNav
    ]
  })
}

return show
