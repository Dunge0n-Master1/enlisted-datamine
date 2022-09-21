from "%enlSqGlob/ui_library.nut" import *

let {addScene, removeScene} = require("%enlist/navState.nut")
let roomState = require("%enlist/state/roomState.nut")
let {showCreateRoom} = require("showCreateRoom.nut")

let progressText = require("%enlist/components/progressText.nut")
let customRoomLobby = require("customRoomLobby.nut")
let roomsList = require("%enlist/roomsList.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")


let customGamesContent = @() {
  watch = [roomState.room, roomState.roomIsLobby]
  size = flex()
  children = !roomState.room.value ? roomsList
    : roomState.roomIsLobby.value ? customRoomLobby
    : progressText(loc("lobbyStatus/gameIsRunning"))
}


let isCustomGamesOpened = mkWatched(persist, "isCustomGamesOpened", false)
let close = @() isCustomGamesOpened(false)
let closeBtnAction = @() showCreateRoom.value ? showCreateRoom(false) : close()
let closeBtn = closeBtnBase({ onClick = closeBtnAction })

let customGamesScene = @() {
  watch = roomState.room
  size = flex()
  margin = [fsh(5), sw(5)]
  children = [
    customGamesContent
    roomState.room.value ? null : closeBtn
  ]
}

if (isCustomGamesOpened.value)
  addScene(customGamesScene)
isCustomGamesOpened.subscribe(@(val) val
  ? addScene(customGamesScene)
  : removeScene(customGamesScene))


return {
  customGamesScene,
  customGamesOpen = @() isCustomGamesOpened(true),
  customGamesClose = close,
  isCustomGamesOpened
}