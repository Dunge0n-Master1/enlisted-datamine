from "%enlSqGlob/ui_library.nut" import *

let {receivedFiles, requestedFiles, requestFilesByHashes} = require("modFiles.nut")
let {sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {showCreateRoom} = require("mpRoom/showCreateRoom.nut")
let roomsListState = require("roomsListState.nut")
let roomState = require("state/roomState.nut")
let textButton = require("%ui/components/textButton.nut")
let textInput = require("%ui/components/textInput.nut")
let centeredText = require("components/centeredText.nut")
let checkBox = require("%ui/components/checkbox.nut")
let msgbox = require("%ui/components/msgbox.nut")
let {rand} = require("math")
let scrollbar = require("%ui/components/scrollbar.nut")
let createRoom = require("createRoom.nut")
let {Inactive, SelectedItemBg, HoverItemBg} = require("%ui/style/colors.nut")
let {tostring_any} = require("%sqstd/string.nut")
let matching_errors = require("matching.errors")
let {squadId} = require("%enlist/squad/squadState.nut")
let { gameLanguage } = require("%enlSqGlob/clientState.nut")
let { soundActive } = textButton
let { remap_others } = require("%enlSqGlob/remap_nick.nut")

let selectedRoom = Watched(null)
let { strip } = require("string")

let scrollHandler = ScrollHandler()

let function tryToJoin(roomInfo, cb, password="" ){
  let params = { roomId = roomInfo.roomId.tointeger() }
  if (squadId.value != null)
    params.member <- { public = {squadId = squadId.value} }
  if (roomInfo?.hasPassword)
    params.password <- strip(password)
  roomState.joinRoom(params, true, cb)
}

let function mkFindSomeMatch(cb) {
  return function(){
    let candidates = []
    foreach (room in roomsListState.list.value) {
      if (room?.hasPassword)
        continue
      if (room.membersCnt >= (room?.maxPlayers ?? 0) || !room.membersCnt)
        continue
      candidates.append(room)
    }

    if (!candidates.len()) {
      msgbox.show({
        text = loc("Cannot find existing game. Create one?")
        buttons = [
          { text = loc("Yes"), action = @() showCreateRoom.update(true) }
          { text = loc("No")}
        ]
      })
    }
    else {
      let room = candidates[rand() % candidates.len()]
      tryToJoin(room, cb, "")
    }
  }
}

let function fullRoomMsgBox(action) {
  msgbox.show({
    text = loc("msgboxtext/roomIsFull")
    buttons = [
      { text = loc("Yes"), action = action }
      { text = loc("No")}
    ]
  })
}

let function joinCb(response) {
  if (response.error != matching_errors.OK){
    if (response.error == matching_errors.SERVER_ERROR_ROOM_FULL) {
      fullRoomMsgBox(mkFindSomeMatch(joinCb))
      return
    }

    msgbox.show({
      text = loc("msgbox/failedJoinRoom", "Failed to join room: {error}", {error=matching_errors.error_string(response.error)})
    })
  } else {
    selectedRoom.update(null)
  }
}
let findSomeMatch = mkFindSomeMatch(joinCb)

let doesCurrentRoomHasAllFiles = Computed(function(){
  local {modFiles="", mod=""} = selectedRoom.value
  if (mod == "" || modFiles == "")
    return true
  let received = receivedFiles.value
  modFiles = modFiles.split(";")
  foreach (hash in modFiles){
    if (hash not in received)
      return false
  }
  return true
})

let areCurrentRoomFilesAreDownloading = Computed(function(){
  local {modFiles="", mod=""} = selectedRoom.value
  if (mod=="" || modFiles == "")
    return false
  modFiles = modFiles.split(";")
  foreach (hash in modFiles){
    if (hash in requestedFiles.value)
      return true
  }
  return false
})

let function doJoin() {
  let roomPassword = Watched("")
  let roomInfo = selectedRoom.value
  if (roomInfo==null) {
    msgbox.show({text=loc("msgbox/noRoomTOJoin", "No room selected")})
    return
  }

  if (!doesCurrentRoomHasAllFiles.value) {
    //if (!areCurrentRoomFilesAreDownloading.value)
    requestFilesByHashes(roomInfo.modFiles.split(";"))
    return
  }
  if (roomInfo && roomInfo?.hasPassword){
    let function passwordInput() {
      local input = null

      if (roomInfo && roomInfo?.hasPassword) {
        input = textInput(roomPassword, {
          placeholder="password"
        })
      }

      return {
        key = "room-password"
        size = [sw(20), SIZE_TO_CONTENT]
        children = input
      }
    }

    msgbox.show({
      text = loc("This room requires password to join")
      children = passwordInput
      buttons = [
        { text = loc("Proceed"), action = function() {tryToJoin(roomInfo, joinCb, roomPassword.value)} }
        { text = loc("Cancel") }
      ]
    })
  }
  else
    tryToJoin(roomInfo, joinCb)
}


let function itemText(text, options={}) {
  return {
    rendObj = ROBJ_TEXT
    text
    margin = fsh(1)
    size = ("pw" in options) ? [flex(options.pw), SIZE_TO_CONTENT] : SIZE_TO_CONTENT
  }.__update(sub_txt)
}


let colWidths = [25, 35, 12, 8, 25]

let function listItem(roomInfo) {
  let stateFlags = Watched(0)

  local roomName = roomInfo?.roomName ?? tostring_any(roomInfo.roomId)
  if (roomInfo?.hasPassword)
    roomName = $"{roomName}*"

  return function() {
    local color
    if (selectedRoom.value && (roomInfo.roomId == selectedRoom.value.roomId))
      color = SelectedItemBg
    else
      color = (stateFlags.value & S_HOVER) ? HoverItemBg : Color(0,0,0,0)

    let modTitle = roomInfo?.modTitles?[gameLanguage]
      ?? roomInfo?.modTitles.title ?? roomInfo?.mod ?? ""
    local { creator = "" } = roomInfo
    creator = creator != "" ? remap_others(creator) : loc("creator/auto")

    return {
      rendObj = ROBJ_SOLID
      color = color
      size = [flex(), SIZE_TO_CONTENT]

      behavior = Behaviors.Button
      onClick = @() selectedRoom.update(roomInfo)
      onDoubleClick = doJoin
      onElemState = @(sf) stateFlags.update(sf)
      watch = [selectedRoom, stateFlags]
      key = roomInfo.roomId

      sound = soundActive

      flow = FLOW_HORIZONTAL
      children = [
        itemText(roomName, {pw=colWidths[0]})
        itemText(modTitle, {pw=colWidths[1]})
        itemText(loc(roomInfo?.sessionState ?? "no_session"), {pw=colWidths[2]})
        itemText(tostring_any(roomInfo.membersCnt), {pw=colWidths[3]})
        itemText(creator, {pw=colWidths[4]})
      ]
    }
  }
}


let function listHeader() {
  return {
    hplace = ALIGN_CENTER
    size = [flex(), SIZE_TO_CONTENT]
    pos = [0, sh(11)]
    children = {
      size = [flex(), SIZE_TO_CONTENT]
      margin = [0, fsh(1), 0, 0]
      flow = FLOW_HORIZONTAL
      children = [
        itemText(loc("Name"), {pw=colWidths[0]})
        itemText(loc("Mod"), {pw=colWidths[1]})
        itemText(loc("Status"), {pw=colWidths[2]})
        itemText(loc("Players"), {pw=colWidths[3]})
        itemText(loc("Creator"), {pw=colWidths[4]})
      ]
    }
  }
}


let nameFilter = mkWatched(persist, "nameFilter", "")

let roomsListW = roomsListState.list
let filteredList = Computed(function() {
  let flt = nameFilter.value.tolower()
  if (flt.len() == 0)
    return clone roomsListW.value
  return roomsListW.value.filter(function(room) {
    let roomName = room.public?.roomName || tostring_any(room.roomId)
    return (roomName.tolower().indexof(flt)!=null)
  })
})

let function listContent() {
  return {
    size = [flex(), SIZE_TO_CONTENT]
    watch = filteredList
    flow = FLOW_VERTICAL
    children = filteredList.value.map(@(roomInfo) listItem(roomInfo))
  }
}


let function roomsListComp() {
  return {
    size = [flex(), sh(60)]
    hplace = ALIGN_CENTER
    pos = [0, sh(15)]

    rendObj = ROBJ_FRAME
    color = Inactive
    borderWidth = [2, 0]

    key = "rooms-list"

    valign = ALIGN_CENTER

    children = scrollbar.makeVertScroll(listContent, {
      scrollHandler = scrollHandler
      rootBase = class {
        size = flex()
        margin = [2, 0]
      }
    })
  }
}


let function roomFilter() {
  return {
    size = [flex(), fsh(6)]

    vplace = ALIGN_BOTTOM
    halign = ALIGN_RIGHT

    flow = FLOW_HORIZONTAL
    onDetach = @() nameFilter.update("")
    onAttach = @() nameFilter.update("")
    children = [
      {
        size = [pw(colWidths[0] * 1.5), SIZE_TO_CONTENT]
        margin = [0, hdpx(10), 0, 0]
        children = textInput.Underlined(nameFilter,
          {
            placeholder=loc("search by name")
            onEscape = @() nameFilter("")
          }.__update(sub_txt))
      }
    ]
  }
}

let function actionButtons() {
  local joinBtn
  if (selectedRoom.value) {
    joinBtn = function(){
      let joinBtnTxt = doesCurrentRoomHasAllFiles.value
        ? loc("Join")
        : areCurrentRoomFilesAreDownloading.value
          ? loc("Downloading...")
          : loc("Download")
      return {
        watch = [areCurrentRoomFilesAreDownloading, doesCurrentRoomHasAllFiles]
        children = textButton(joinBtnTxt, doJoin, {hotkeys = [["^Enter"]]})
      }
    }
  }
  return {
    size = [SIZE_TO_CONTENT, fsh(6.5)] //FIX ME: need button height here
    watch = [selectedRoom]

    vplace = ALIGN_BOTTOM
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL

    children = [
      textButton(loc("Find custom game"), findSomeMatch, {hotkeys=[["^J:Y"]]})
      textButton(loc("Create game"), @() showCreateRoom.update(true), {hotkeys=[["^J:X | Enter"]]})
      checkBox(roomsListState.showForeignGames, loc("Show foreign games"))
      joinBtn
    ]
  }
}
let areThereRooms = Computed(@() roomsListW.value.len()>0)

let function roomsListScreen() {
  local children = null

  if (roomsListState.error.value) {
    children = [centeredText(loc("error/{0}".subst(roomsListState.error.value)))]
  }
  else if (!areThereRooms.value) {
    children = [centeredText(loc("No custom games found")) actionButtons]
  }
  else {
    children = [
      listHeader
      @(){
        watch = roomsListW
        children = roomsListComp
        size = flex()
      }
      {
        flow = FLOW_HORIZONTAL
        size = flex()
        children = [actionButtons, roomFilter]
      }
    ]
  }

  return {
    children
    size = flex()
    onAttach = @() roomsListState.refreshEnabled(true)
    onDetach = @() roomsListState.refreshEnabled(false)

    watch = [
      roomsListState.error
      roomsListState.isRequestInProgress
      areThereRooms
    ]
  }
}

let function root() {
  let children = showCreateRoom.value ?  createRoom : roomsListScreen
  return {
    size = [sw(80), flex()]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = Color(100,100,100,255)
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    padding = hdpx(5)
    key = "rooms-list"

    children = children
    watch = showCreateRoom
  }
}

return root
