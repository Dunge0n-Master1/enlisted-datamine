from "%enlSqGlob/ui_library.nut" import *
from "eventRoomsListFilter.nut" import *
let { platformAlias } = require("%dngscripts/platform.nut")
let { logerr } = require("dagor.debug")
let { debounce } = require("%sqstd/timers.nut")
let math = require("math")
let { matchingCall } = require("%enlist/matchingClient.nut")
let { chooseRandom } = require("%sqstd/rand.nut")
let { getValInTblPath } = require("%sqstd/table.nut")
let { error_string } = require("matching.errors")
let { createEventRoomCfg, allModes, getValuesFromRule, isModsAvailable } = require("createEventRoomCfg.nut")
let {get_setting_by_blk_path} = require("settings")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { crossnetworkPlay, CrossplayState } = require("%enlSqGlob/crossnetwork_state.nut")
let { featuredMods, featuredModsRoomsList } = require("sandbox/customMissionOfferState.nut")
let { nestWatched, globalWatched } = require("%dngscripts/globalState.nut")


let matchingGameName = get_setting_by_blk_path("matchingGameName")

const REFRESH_PERIOD = 5.0

let isDebugMode = mkWatched(persist, "isDebugMode", false)
let isRequestInProgress = Watched(false)
let isRefreshEnabled = mkWatched(persist, "isRefreshEnabled", false)
let { lastResult, lastResultUpdate } = globalWatched("lastResult", @() {})
let roomsListError = Computed(@()
  lastResult.value?.error ? error_string(lastResult.value.error) : null)
let hideFullRooms = optFullRooms.curValue
let hideModsRooms = optModRooms.curValue
let hidePasswordRooms = optPasswordRooms.curValue
let savedRoomId = nestWatched("savedRoomId", null)
let curSorting = Watched({ column = {}, isReverse = false })
let getServerTime = @() serverTime.value

let roomsList = Computed(function() {
  let sortFunc = curSorting.value.column?.sortFunc
  local res = lastResult.value?.digest
  res = res!=null ? clone res : []
  if (!isModsAvailable.value)
    res = res.filter(@(v) v?.scene != null)
  foreach (idx, room in res) {
    if ((room?.sessionLaunchTime ?? -1) > 0)
      res[idx].timeInBattle <- getServerTime() - room.sessionLaunchTime
  }

  if (sortFunc == null)
    return res

  let isReverseSorting = curSorting.value.isReverse ? -1 : 1
  return res.sort(@(a, b) isReverseSorting * sortFunc(a, b))
})

roomsList.subscribe(function(v){
  let featuredModsIds = {}
  featuredMods.value.each(@(v) featuredModsIds[v.id] <- true)
  return featuredModsRoomsList(v.filter(@(mod) (mod?.modId ?? "") in featuredModsIds))
})


let selRoom = Computed(@() roomsList.value.findvalue(@(r) r.roomId == savedRoomId.value)
  ?? roomsList.value?[0])

let mkDebugRooms = @(count) array(count).map(function(_, idx) {
  let room = {
    roomId = 1000 - idx
    membersCnt = 1 + math.rand() % 25
    maxPlayers = 32
    creator = $"WWWWWWWWWWWWWWW{math.rand() % 10}"
    cTime = serverTime.value
    mode = chooseRandom(allModes.value.len() > 0 ? allModes.value : ["SQUADS", "LONE_FIGHTERS"])
    cluster = chooseRandom(optCluster.allValues.value)
  }
  foreach (id, rule in createEventRoomCfg.value?[room.mode].rules ?? {}) {
    let { values, isMultival } = getValuesFromRule(rule)
    if (values.len() == 0)
      continue
    room[id.split("/").top()] <- isMultival ? values.filter(@(_) math.rand() % 2)
      : chooseRandom(values)
  }
  return room
})

/*  "test" variants:
"in" - room value is in filter values array
"intersect" - any value from room values array in filter values array
"eq" - equal
"ne" - not equal
"range" - value is in range
"ge" - greater or equal
"gr" - greater
"le" - lower or equal
"lr" - lower
*/
let fixedFilters = {
  ["gameName"]    = { test = "eq", value = matchingGameName },
}

let function getFiltersByOptions() {
  let res = {}
  let { defaults = {} } = createEventRoomCfg.value?[allModes.value?[0]]
  foreach (opt in [optMode, optDifficulty, optCampaigns, optCluster]) {
    if (opt.optType != OPT_MULTISELECT) {
      logerr("Filter rooms by options support only multiselect options yet")
      continue
    }
    let all = opt.allValues.value?.len()
    let cur = opt.curValues.value.len()
    if (all == null || all == cur || cur == 0)
      continue
    let idPath = opt.id.split("/")
    let vType = type(getValInTblPath(defaults, idPath))
    res[idPath.top()] <- {
      test = vType == "array" ? "intersect" : "in"
      value = opt.curValues.value
    }
  }
  if (hideFullRooms.value)
    res.slotsCnt <- { test = "ne", value = 0 }

  if (hideModsRooms.value)
    res.scene <- { test = "ne", value = null}

  if (hidePasswordRooms.value)
    res.hasPassword <- { test = "ne", value = true}

  let crossplayValues = optCrossplay.allValues.value == null ? [crossnetworkPlay.value]
    : optCrossplay.curValues.value.len() > 0 ? optCrossplay.curValues.value
    : optCrossplay.allValues.value

  if (crossplayValues.len() == 1 && crossplayValues[0] == CrossplayState.OFF) {
    res["crossplay"] <- { test = "eq", value = "off" }
  } else {
    res["crossPlatform"] <- {
      test = "intersect",
      value = crossplayValues.map(@(v) $"{platformAlias}_{v}")
    }
  }

  return res
}

let function updateListRooms() {
  if (isRequestInProgress.value)
    return

  let params = {
    group = "events-lobby"
    cursor = 0
    count = 100
    filter = fixedFilters.__merge(getFiltersByOptions())
  }
  isRequestInProgress(true)
  matchingCall("mrooms.fetch_rooms_digest2",
    function(response) {
      isRequestInProgress(false)
      lastResultUpdate(isDebugMode.value
        ? { digest = mkDebugRooms(math.rand() % 100) }
        : response)
    },
    params)
}

let function updateRefreshTimer() {
  if (isRefreshEnabled.value) {
    updateListRooms()
    gui_scene.setInterval(REFRESH_PERIOD, updateListRooms)
  }
  else
    gui_scene.clearTimer(updateListRooms)
}
updateRefreshTimer()
isRefreshEnabled.subscribe(@(_) updateRefreshTimer())

foreach (opt in [optMode, optDifficulty, optCrossplay, optCampaigns, optCluster, optFullRooms])
  (opt?.curValue ?? opt.curValues).subscribe(debounce(@(_) updateListRooms(), 0.2))

let function toggleDebugMode() {
  isDebugMode(!isDebugMode.value)
  if (isDebugMode.value)
    updateListRooms()
}

console_register_command(toggleDebugMode, "eventRooms.toggleDebugMode")

return {
  roomsList
  roomsListError
  isRequestInProgress
  isRefreshEnabled
  selRoom
  selectRoom = @(roomId) savedRoomId(roomId)
  curSorting
}
