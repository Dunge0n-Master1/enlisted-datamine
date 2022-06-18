from "%enlSqGlob/ui_library.nut" import *

let {useBigFonts} = require("%enlSqGlob/ui_settings.nut")
let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let colors = require("%ui/style/colors.nut")
let { gap } = require("%enlSqGlob/ui/viewConst.nut")
let textInput = require("%ui/components/textInput.nut")
let {makeVertScroll} = require("%ui/components/scrollbar.nut")
let fontIconButton = require("%ui/components/fontIconButton.nut")
let txt = require("%ui/components/text.nut").dtext
let userInfo = require("%enlSqGlob/userInfo.nut")
let {popupBlockStyle, defPopupBlockPos} = require("%enlist/popup/popupBlock.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let { INVITE_TO_PSN_FRIENDS, CANCEL_INVITE, APPROVE_INVITE, ADD_TO_BLACKLIST, INVITE_TO_FRIENDS,
  INVITE_TO_SQUAD, REMOVE_FROM_BLACKLIST, COMPARE_ACHIEVEMENTS, INVITE_TO_ROOM,
  REVOKE_INVITE, REJECT_INVITE, REMOVE_FROM_SQUAD, REMOVE_FROM_FRIENDS,
  PROMOTE_TO_LEADER, SHOW_USER_LIVE_PROFILE, REMOVE_FROM_BLACKLIST_PSN, REMOVE_FROM_BLACKLIST_XBOX
} = require("contactActions.nut")
let contactBlock = require("contactBlock.nut")
let windowPadding = fsh(2)
let searchPlayer = Watched("")

let { Contact, getContactNick } = require("contact.nut")
let { approvedUids, psnApprovedUids, xboxApprovedUids, friendsOnlineUids, requestsToMeUids, myRequestsUids,
  rejectedByMeUids, blockedUids, isInternalContactsAllowed
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
let contactListBigWidth = hdpx(300)

let display = Watched("approved")

let hdrTxt = @(text,params={}) {
  padding = [hdpx(2),fsh(1)]
  size = [flex(),SIZE_TO_CONTENT]
  children = txt(text,params.__merge({
    behavior = [Behaviors.Marquee,Behaviors.Button]
    size = [flex(), SIZE_TO_CONTENT]
    speed = hdpx(100)
    scrollOnHover = true
  }, sub_txt))
}

/*
  - split online and offline users and remove presence icon
  - move a search to invitations panel, and make a filter inputbox for contacts and blocklist
*/

let closeWnd = @() modalPopupWnd.remove(CONTACTLIST_MODAL_UID)

let function resetSearch() {
  display("approved")
  searchPlayer("")
  searchContactsResults({})
}

let closeButton = fontIconButton("close", {
  onClick = function() {
    resetSearch()
    closeWnd()
  }
})


let header = @(){
  size = [flex(), fsh(4)]
  watch = userInfo
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  gap = hdpx(8)
  padding = [hdpx(8),hdpx(8),hdpx(8),windowPadding]
  color = colors.WindowHeader
  children = [
    {
      rendObj = ROBJ_TEXT
      text = userInfo.value?.nameorig ?? ""
      size = [flex(), SIZE_TO_CONTENT]
      color = colors.Inactive
      clipChildren = true
      behavior = [Behaviors.Marquee, Behaviors.Button]
      scrollOnHover=true
    }.__update(body_txt)
    {size = [hdpx(8),0]}
    closeButton
  ]
}

let function searchCallback() {
  if (searchPlayer.value.len() > 0)
    display("search_results")
}

let function doSearch(nick) {
  if (nick.len() == 0)
    resetSearch()
  else
    searchContacts(nick, searchCallback)
}
display.subscribe(function(val){
  if (val == "search_results")
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
  margin =[ hdpx(2), windowPadding]
  children = [
    textInput(searchPlayer, {
      placeholder = loc(isOnlineContactsSearchEnabled ? "Search for new friends..." : "Search in friends list...")
      textmargin = hdpx(5)
      onChange = doSearch
      onReturn = @() doSearch(searchPlayer.value)
      onEscape = clearOrExitWnd
    }.__update(sub_txt))
    display.value != "search_results" || searchPlayer.value.len() == 0 ? null : exitSearchButton
  ]
}

let counterText = @(count) count > 0 ? count : null
let placeholder = txt(loc("contacts/list_empty"), {color=colors.Inactive, margin = [fsh(1),windowPadding]}.__update(sub_txt))

let friendsButton = buildContactsButton({
  symbol = "users"
  onClick = @() display("approved")
  selected = Computed(@() display.value == "approved")
  children = buildCounter(Computed(@() counterText(friendsOnlineUids.value.len())))
})

let friendsKeys = []
if (isInternalContactsAllowed) {
  friendsKeys.append({
    name = "friends",
    uidsWatch = [approvedUids, xboxApprovedUids]
    placeholder
    inContactActions = [INVITE_TO_SQUAD],
    contextMenuActions = [
      INVITE_TO_PSN_FRIENDS, REMOVE_FROM_SQUAD, REVOKE_INVITE, INVITE_TO_ROOM,
      INVITE_TO_SQUAD, PROMOTE_TO_LEADER,REMOVE_FROM_FRIENDS, COMPARE_ACHIEVEMENTS,
      SHOW_USER_LIVE_PROFILE
    ]
  })
}

if (is_sony)
  friendsKeys.append({
    name = "contacts",
    uidsWatch = psnApprovedUids,
    inContactActions = [INVITE_TO_FRIENDS],
    contextMenuActions = [
      INVITE_TO_FRIENDS, ADD_TO_BLACKLIST,
      REMOVE_FROM_SQUAD, REVOKE_INVITE, INVITE_TO_SQUAD, PROMOTE_TO_LEADER, SHOW_USER_LIVE_PROFILE
    ]
  })

let invitationsButton = buildContactsButton({
  symbol = "user-plus"
  onClick = @() display("invites")
  selected = Computed(@() display.value == "invites")
  children = buildCounter(Computed(@() counterText(
    requestsToMeUids.value.len() + myRequestsUids.value.len() + rejectedByMeUids.value.len()
  )))
})

let myBlacklist = buildContactsButton({
  symbol = "user-times"
  onClick = @() display("myBlacklist")
  selected = Computed(@() display.value == "myBlacklist")
  children = buildCounter(Computed(@() counterText( blockedUids.value.len() )))
})


let invitesKeys = [
  { name = "requestsToMe",
    uidsWatch = requestsToMeUids,
    inContactActions = [APPROVE_INVITE],
    contextMenuActions = [APPROVE_INVITE, REJECT_INVITE, INVITE_TO_SQUAD, ADD_TO_BLACKLIST, COMPARE_ACHIEVEMENTS]
  }
  { name = "myRequests",
    uidsWatch = myRequestsUids,
    inContactActions = [CANCEL_INVITE],
    contextMenuActions = [CANCEL_INVITE, INVITE_TO_SQUAD, REVOKE_INVITE, ADD_TO_BLACKLIST, COMPARE_ACHIEVEMENTS]
  }
  { name = "rejectedByMe",
    uidsWatch = rejectedByMeUids,
    inContactActions = [],
    contextMenuActions = [APPROVE_INVITE, INVITE_TO_FRIENDS, INVITE_TO_SQUAD, ADD_TO_BLACKLIST, COMPARE_ACHIEVEMENTS]
  }
]

let nickToLower = memoize(@(v) getContactNick(v).tolower(), null, persist("stringsLowerCache", @() {}))
let sortContacts = @(contactsArr, onlineStatusVal) contactsArr.sort(@(a, b)
  isContactOnline(b.value.userId, onlineStatusVal) <=> isContactOnline(a.value.userId, onlineStatusVal) || nickToLower(a) <=> nickToLower(b)
)

let mkContactsGroupContent = @(groupKeys, mkContactBlock) function() {
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
      contactsArr = contactsArr.filter(@(c) c.value.realnick.tolower().indexof(searchPlayerVal) != null)

    contactsArr = sortContacts(contactsArr, onlineStatus.value)
      .map(@(contact) mkContactBlock({ contact, inContactActions, contextMenuActions }))

    children.append(hdrTxt(locByPlatform($"contacts/{name}")))
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
  { option = "approved", comp = friendsButton },
  { option = "invites", comp = invitationsButton},
  { option = "myBlacklist", comp = myBlacklist}
]

let function modeSwitcher() {
  return isContactsManagementEnabled ?
    {
      size = [pw(100), fsh(5)]
      halign = ALIGN_RIGHT
      valign = ALIGN_BOTTOM
      gap = hdpx(10)
      margin = [hdpx(8), windowPadding, hdpx(0), windowPadding]
      flow = FLOW_HORIZONTAL
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
    REMOVE_FROM_BLACKLIST_XBOX, ADD_TO_BLACKLIST, SHOW_USER_LIVE_PROFILE, COMPARE_ACHIEVEMENTS
  ]
}]

let myBlackTbl = [{
  uidsWatch = [blockedUids]
  name = "myBlacklist",
  placeholder,
  inContactActions = [REMOVE_FROM_BLACKLIST, REMOVE_FROM_BLACKLIST_PSN, REMOVE_FROM_BLACKLIST_XBOX],
  contextMenuActions = [REMOVE_FROM_BLACKLIST, REMOVE_FROM_BLACKLIST_PSN,
    REMOVE_FROM_BLACKLIST_XBOX, SHOW_USER_LIVE_PROFILE, COMPARE_ACHIEVEMENTS]
}]

let isContactsWndVisible = Watched(false)
let popupsOffset = @() !useBigFonts.value ? [-contactListWidth+defPopupBlockPos[0], defPopupBlockPos[1]] : [-contactListBigWidth+defPopupBlockPos[0], defPopupBlockPos[1]]
isContactsWndVisible.subscribe(@(v) popupBlockStyle.mutate(@(style) style.pos <- (v ? popupsOffset() : defPopupBlockPos)))

let tabsContent = {
  search_results = @(mkContactBlock) mkContactsGroupContent(searchTbl, mkContactBlock),
  myBlacklist    = @(mkContactBlock) mkContactsGroupContent(myBlackTbl, mkContactBlock),
  approved       = @(mkContactBlock) mkContactsGroupContent(friendsKeys, mkContactBlock),
  invites        = @(mkContactBlock) mkContactsGroupContent(invitesKeys, mkContactBlock)
}

let contactsBlock = @(mkContactBlock) @() {
  watch = [display, useBigFonts]
  size = [useBigFonts.value ? contactListBigWidth : contactListWidth, flex() ]
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
          makeVertScroll(tabsContent?[display.value](mkContactBlock))
        ]
      }
    ]
  }
}


let curModeIdx = Computed(@() modesList.findindex(@(m) m.option == display.value) ?? -1)
let changeMode = @(delta) display(modesList[(curModeIdx.value + delta + modesList.len()) % modesList.len()].option)

let btnContactsNav = @() {
  size = SIZE_TO_CONTENT
  children = isContactsManagementEnabled ? {
    hotkeys = [
      ["^J:RB | Tab", {action = @() changeMode(1), description=loc("contacts/next_mode")} ],
      ["^J:LB | L.Shift Tab | R.Shift Tab", { action = @() changeMode(-1), description=loc("contacts/prev_mode")} ]
    ]
  } : null
}



let popupBg = { rendObj = ROBJ_WORLD_BLUR_PANEL, fillColor = colors.ModalBgTint }
let function show(mkContactBlock = contactBlock, additionalChild = null){
  if (!isContactsEnabled)
    return

  let bottomOffset = safeAreaBorders.value[2] + gap
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
      contactsBlock(mkContactBlock),
      btnContactsNav,
      additionalChild
    ]
    popupBg = popupBg
  })
}

return kwarg(show)
