from "%enlSqGlob/ui_library.nut" import *

let { eventGameModes } = require("gameModeState.nut")
let { userstatStats } = require("%enlSqGlob/userstats/userstat.nut")
let { allModes, isRoomCfgActual, actualizeRoomCfg } = require("createEventRoomCfg.nut")
let { hasCustomGames, showEventsWidget } = require("%enlist/featureFlags.nut")
let { curArmy, curArmiesList} = require("%enlist/soldiers/model/state.nut")
let { loadJson } = require("%sqstd/json.nut")
let squadsPresentation = require("%enlSqGlob/ui/squadsPresentation.nut")
let mkCurSquadsList = require("%enlSqGlob/ui/mkSquadsList.nut")
let isNewbie = require("%enlist/unlocks/isNewbie.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")

let isEventModesOpened = mkWatched(persist, "isEventModesOpened", false)
let customRoomsModeSaved = mkWatched(persist, "customRoomsModeSaved", false)
let hasCustomRooms = Computed(@()
  !isNewbie.value && allModes.value.len() > 0 && hasCustomGames.value)
let isCustomRoomsMode = Computed(@() customRoomsModeSaved.value && hasCustomRooms.value)
let selEventIdByPlayer = mkWatched(persist, "selEventByPlayer", null)
let curEventSquadId = mkWatched(persist, "curEventSquadId")
let eventCurArmyIdx = mkWatched(persist, "eventCurArmyIdx", 0)
let eventsArmiesList = mkWatched(persist, "eventsArmiesList", [])
let hasUniqueArmies = mkWatched(persist, "hasUniqueArmies", false)

let curTab = Watched(null)
curArmy.subscribe(@(_v) eventCurArmyIdx(curArmiesList.value.indexof(curArmy.value)))

let hasBaseEvent = Computed(@() showEventsWidget.value
  && (hasCustomRooms.value || eventGameModes.value.len() > 0))

let inactiveEventsToShow = Computed (@() eventGameModes.value.filter(@(gm)
  (gm?.showWhenInactive ?? false) && !gm.enabled))

let activeEvents = Computed (@() eventGameModes.value.filter(@(gm) gm.enabled))

let promotedEvent = Computed(@()
  activeEvents.value.findvalue(@(gm) gm?.queue.extraParams.isPreviewImage ?? false)
  ?? activeEvents.value?[0])

let selEvent = Computed(@()
  eventGameModes.value.findvalue(@(gm) gm.id == selEventIdByPlayer.value)
    ?? eventGameModes.value?[0])

let selLbMode = Computed(@() selEvent.value?.queue.extraParams.leaderboardTables[0])
let eventCustomProfilePath = Computed(@() selEvent.value?.queue.extraParams.customProfile)

let eventCustomProfile = Computed(@() eventCustomProfilePath.value != null
  ? loadJson($"%{eventCustomProfilePath.value}")
  : null)

let eventCampaigns = Computed(@() selEvent.value?.campaigns ?? [])

let hasChoosedCampaign = Watched(false)

let isCurCampaignAvailable = Computed(@() eventCampaigns.value.contains(curCampaign.value))

let eventCustomSquads = Computed(function(){
  if (eventCustomProfile.value == null)
    return null
  local armyId = curArmy.value
  if (eventCustomProfile.value?[armyId] == null)
    armyId = eventCustomProfile.value.keys()[eventCurArmyIdx.value]

  let squads = eventCustomProfile.value?[armyId].squads ?? []
  if (squads.len() == 0)
    return null
  return squads
    .map(function(squad) {
      let squadId = squad.squadId
      let squadDesc = squadsPresentation?[armyId][squadId]
      let res = {
        squadId = squadId
        icon = squadDesc?.icon
        premIcon = squadDesc?.premIcon
      }
      if ((squad?.battleExpBonus ?? 0) > 0)
        res.premIcon <- armiesPresentation?[armyId].premIcon

      return res.__update({
        name = squad?.locId ? loc(squad.locId) : "---"
        squadType = squad?.squadType ?? "unknown"
        level = squad?.level ?? 0
        squadSize = squad.squad.len()
        vehicle = squad?.curVehicle
        vehicleType = squad?.vehicleType
      })
    })
  }
)

let function updateEvent() {
  let armyList = curArmiesList.value
  if (eventCustomProfile.value != null){
    let squads = eventCustomSquads.value
    let uniqueArmyList = eventCustomProfile.value.keys()
    let armiesOfCurCampaign = []
    foreach (armyId in armyList)
      if (uniqueArmyList.contains(armyId))
        armiesOfCurCampaign.append(armyId)
    hasUniqueArmies(armiesOfCurCampaign.len() <= 1)
    eventsArmiesList(hasUniqueArmies.value ? uniqueArmyList : armiesOfCurCampaign)
    curEventSquadId(squads[0].squadId)
  }
  else {
    eventsArmiesList(armyList)
    hasUniqueArmies(false)
  }
}

let function checkUpdateEvent(_){
  if (isEventModesOpened.value)
    updateEvent()
}

foreach (v in [selEvent, curCampaign, isEventModesOpened])
  v.subscribe(checkUpdateEvent)

isEventModesOpened.subscribe(@(v) v ? null : eventsArmiesList([]))

let eventsSquadList = @(squads) mkCurSquadsList({
  curSquadsList = squads
  curSquadId = curEventSquadId
  setCurSquadId = @(squadId) curEventSquadId(squadId)
})

let selEventEndTime = Computed(function() {
  let time = userstatStats.value?.stats[selLbMode.value]["$endsAt"].tointeger() ?? 0
  return time
})

let needActualizeCfg = keepref(Computed(@() !isRoomCfgActual.value && isEventModesOpened.value))
needActualizeCfg.subscribe(function(v) { if (v) actualizeRoomCfg() })

let function openCustomGameMode() {
  customRoomsModeSaved(true)
  isEventModesOpened(true)
}

let function openEventsGameMode() {
  customRoomsModeSaved(false)
  isEventModesOpened(true)
}

return {
  eventGameModes
  inactiveEventsToShow
  activeEvents
  promotedEvent
  isEventModesOpened
  isCustomRoomsMode
  hasCustomRooms
  customRoomsModeSaved
  selEvent
  selLbMode
  selectEvent = @(eventId) selEventIdByPlayer(eventId)
  openEventModes = @() isEventModesOpened(true)
  openCustomGameMode
  openEventsGameMode
  selEventEndTime
  eventCustomSquads
  eventsSquadList
  eventsArmiesList
  eventCurArmyIdx
  hasBaseEvent
  eventCampaigns
  hasChoosedCampaign
  isCurCampaignAvailable
  eventCustomProfile
  curTab
}