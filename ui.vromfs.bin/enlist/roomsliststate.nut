from "%enlSqGlob/ui_library.nut" import *

let { matchingCall } = require("matchingClient.nut")
let math = require("math")
let matching_errors = require("matching.errors")
let {get_setting_by_blk_path} = require("settings")
let localSettings = require("options/localSettings.nut")("roomsListState/")

let debugMode = mkWatched(persist, "debugMode", false)
let roomsList = mkWatched(persist, "roomsList", [])
let isRequestInProgress = mkWatched(persist, "isRequestInProgress", false)
let curError = Watched(null)
let showForeignGames = localSettings(false, "showForeignGames")

let matchingGameName = get_setting_by_blk_path("matchingGameName")
log($"matchingGameName in settings.blk {matchingGameName}")

let function listRoomsCb(response) {
  isRequestInProgress.update(false)
  if (debugMode.value)
    return
  if (response.error) {
    curError.update(matching_errors.error_string(response.error))
    roomsList.update([])
  } else {
    curError.update(null)
    roomsList(response.digest)
  }
}

let function updateListRooms(){
  if (isRequestInProgress.value)
    return

  let params = {
    group = "custom-lobby"
    cursor = 0
    count = 100
    filter = {
    }
  }
  if (!showForeignGames.value) {
    params.filter["gameName"] <- {
      test = "eq"
      value = matchingGameName
    }
  }

  isRequestInProgress(true)
  matchingCall("mrooms.fetch_rooms_digest2", listRoomsCb, params)
}

let refreshPeriod = mkWatched(persist, "refreshPeriod", 5.0)
let refreshEnabled = mkWatched(persist, "refreshEnabled", false)

local wasRefreshEnabled = false
let function toggleRefresh(val){
  if (!wasRefreshEnabled && val)
    updateListRooms()
  if (val)
    gui_scene.setInterval(refreshPeriod.value, updateListRooms)
  else
    gui_scene.clearTimer(updateListRooms)
  wasRefreshEnabled = val
}
refreshEnabled.subscribe(toggleRefresh)
toggleRefresh(refreshEnabled.value)
refreshPeriod.subscribe(@(_) toggleRefresh(refreshEnabled.value))

let function switchDebugMode() {
  let function debugRooms() {
    let list = array(100).map(function(_) {
      let rnd = math.rand()
      let creator = $"%Username%{rnd%11}"
      return {
        roomId = rnd
        membersCnt = 2 + rnd % 25
        public = {
          creator
          creatorText = creator
          hasPassword = !(rnd % 3)
        }
      }
    })
    roomsList.update(list)
  }
  debugMode.update(!debugMode.value)
  if (debugMode.value){
    refreshEnabled.update(false)
    debugRooms()
  }
  else{
    refreshEnabled.update(true)
  }
}

console_register_command(switchDebugMode, "rooms.switchDebugMode")

return {
  showForeignGames
  list = roomsList
  error = curError
  isRequestInProgress
  refreshPeriod
  refreshEnabled
  _manualRefresh = updateListRooms
}
