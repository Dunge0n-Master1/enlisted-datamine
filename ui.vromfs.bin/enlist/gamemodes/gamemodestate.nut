from "%enlSqGlob/ui_library.nut" import *

let { logerr } = require("dagor.debug")
let { doesLocTextExist } = require("dagor.localize")
let { matchingQueues } = require("%enlist/matchingQueues.nut")
let isNewbie = require("%enlist/unlocks/isNewbie.nut")
let {
  curUnfinishedBattleTutorial, curBattleTutorial, curBattleTutorialTank, curBattleTutorialEngineer,
  curBattleTutorialAircraft, curPractice} = require("%enlist/tutorial/battleTutorial.nut")
let localSettings = require("%enlist/options/localSettings.nut")("quickMatch/")
let {
  curCampaign, curArmy, maxCampaignLevel
} = require("%enlist/soldiers/model/state.nut")
let { isInSquad } = require("%enlist/squad/squadState.nut")
let { purchasesExt } = require("%enlist/meta/profile.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let { seenGamemodes } = require("seenGameModes.nut")
let { gameLanguage } = require("%enlSqGlob/clientState.nut")
let { maxVersionStr } = require("%enlSqGlob/client_version.nut")
let { check_version } = require("%sqstd/version_compare.nut")
let { startsWith } = require("%sqstd/string.nut")

let selGameModeIdByCampaign = mkWatched(persist, "curGameMode", {})
let savedGameModeIdByCampaign = localSettings({}, "curGameMode")

const TANK_TUTORIAL_ID = "tutorial_tank"
const ENGINEER_TUTORIAL_ID = "tutorial_engineer"
const AIRCRAFT_TUTORIAL_ID = "tutorial_aircraft"

let function updateGameMode(...) {
  selGameModeIdByCampaign(clone savedGameModeIdByCampaign.value)
}

updateGameMode()
foreach (v in [curCampaign, savedGameModeIdByCampaign])
  v.subscribe(updateGameMode)

let selGameModeId = Computed(@() selGameModeIdByCampaign.value?[curCampaign.value])

let defTutorialImage = "ui/game_mode_moscow_tutorial.avif"
let defTutorialTankImage = "ui/game_mode_tutorial_tank.avif"
let defTutorialEngineerImage = "ui/game_mode_tutorial_engineer.avif"
let defTutorialAircraftImage = "ui/game_mode_tutorial_aircraft.avif"
let defPracticeImage = "ui/game_mode_moscow_practice.avif"

let gameModeDefaults = {
  id = null
  isAvailable = false
  isLocal = false
  minGroupSize = 1
  maxGroupSize = 1
  queue = null
  queueId = null
  isLocked = false
  lockLevel = 0

  locId = null
  descLocId = null
  image = null
  fbImage = null
  scenes = []
  uiOrder = 10000
  needShowCrossplayIcon = false
  reqVersion = null
  isVersionCompatible = true
}

let onlineGameModes = Computed(function() {
  let curLevel = maxCampaignLevel.value
  let res = []
  let used = {}
  foreach (queueIdx, queue in matchingQueues.value) {
    if ((!(queue?.enabled ?? true) || (queue?.disabled ?? false))
      && !(queue?.extraParams.showWhenInactive ?? false))
        continue
    let gameMode = gameModeDefaults.__merge(queue)
      .__update(queue?.extraParams ?? {})
    let id = gameMode.id ?? gameMode.queueId ?? $"#{queueIdx}"
    if (id in used) {
      logerr($"Not unique gameModeId, {id}")
      continue
    }

    let maxVersionValue = maxVersionStr.value
    let isVersionCompatible = queue?.extraParams.reqVersion == null
      || check_version(queue.extraParams.reqVersion, maxVersionValue)
    if (!isVersionCompatible && queue?.extraParams.hideOnIncompatableVersion)
      continue

    used[id] <- true
    gameMode.id = id
    gameMode.queue = queue
    gameMode.locId = gameMode.locId ?? id
    gameMode.image = gameMode?.imageUrl ?? gameMode.image
    gameMode.needShowCrossplayIcon = true
    gameMode.isLocked = (gameMode?.queue.extraParams.minCampaignLevel ?? 0) > curLevel
    gameMode.lockLevel = gameMode?.queue.extraParams.minCampaignLevel ?? 0
    gameMode.isVersionCompatible = isVersionCompatible
    res.append(gameMode)
  }
  res.sort(@(a, b) a.uiOrder <=> b.uiOrder)
  return res
})

let offlineGameModes = Computed(function() {
  if (!curBattleTutorial.value)
    return []

  let armyId = curArmy.value
  return [
    {
      isLocal = true
      id = "tutorial"
      locId = "TUTORIAL"
      descLocId = "tutorial_desc"
      uiOrder = 0
      image = armiesPresentation?[armyId].tutorialImage ?? defTutorialImage
      scenes = [curBattleTutorial.value]
    },
    {
      isLocal = true
      id = TANK_TUTORIAL_ID
      locId = "TUTORIAL_TANK"
      descLocId = "tutorial_tank_desc"
      uiOrder = 1
      image = armiesPresentation?[armyId].tutorialTankImage ?? defTutorialTankImage
      scenes = [curBattleTutorialTank.value]
    },
    {
      isLocal = true
      id = ENGINEER_TUTORIAL_ID
      locId = "TUTORIAL_ENGINEER"
      descLocId = "tutorial_engineer_desc"
      uiOrder = 2
      image = armiesPresentation?[armyId].tutorialEngineerImage ?? defTutorialEngineerImage
      scenes = [curBattleTutorialEngineer.value]
    },
    {
      isLocal = true
      id = AIRCRAFT_TUTORIAL_ID
      locId = "TUTORIAL_AIRCRAFT"
      descLocId = "tutorial_aircraft_desc"
      uiOrder = 3
      image = armiesPresentation?[armyId].tutorialAircraftImage ?? defTutorialAircraftImage
      scenes = [curBattleTutorialAircraft.value]
    },
    {
      isLocal = true
      id = "practice"
      locId = "PRACTICE"
      descLocId = "practice_desc"
      uiOrder = 4
      image = armiesPresentation?[armyId].practiceImage ?? defPracticeImage
      scenes = [curPractice.value]
    }
  ].map(@(v) gameModeDefaults.__merge(v))
})

let allGameModes = Computed(function() {
  let isAllowLocal = !isInSquad.value
  let gameModes = [].extend(offlineGameModes.value, onlineGameModes.value)

  foreach (gMode in gameModes) {
    gMode.isAvailable = !gMode.isLocal || isAllowLocal

    local modeTitle = loc(gMode?.locId, "")
    if (modeTitle == "") {
      let locTable = gMode?.queue.extraParams.locTable ?? {}
      modeTitle = locTable?[gameLanguage] ?? locTable?["English"] ?? ""
    }
    gMode.title <- modeTitle

    let { descLocId = null } = gMode
    if (descLocId != null && doesLocTextExist(descLocId))
      gMode.description <- loc(descLocId)
    else {
      let locTable = gMode?.queue.extraParams.descLocTable ?? {}
      gMode.description <- locTable?[gameLanguage] ?? locTable?["English"] ?? modeTitle
    }
  }
  return gameModes
})

let isEventGm = @(gm) gm.queue?.extraParams.isEventQueue ?? false

let isQueueFitToCampaign = @(queue, campaign)
  (queue?.extraParams.campaigns ?? []).indexof(campaign) != null

let mainGameModes = Computed(function() {
  let campaign = curCampaign.value
  let res = allGameModes.value.filter(@(gm) !isEventGm(gm)
    && (gm.queue == null || isQueueFitToCampaign(gm.queue, campaign)))

  let isNewbieV = isNewbie.value
  let newbieRes = res.filter(@(gm) gm.queue == null || (gm.queue?.extraParams.newbies ?? false) == isNewbieV)
  return newbieRes.findvalue(@(gm) gm.queue != null)
    ? newbieRes //apply newbie gamemodes only if there exist online modes
    : res
})

let tutorialModes = Computed(@() mainGameModes.value
  .filter(@(mode) startsWith(mode.id,"tutorial")))
let mainModes = Computed(@() mainGameModes.value
  .filter(@(mode) !startsWith(mode.id,"tutorial")))

let eventGameModes = Computed(function() {
  let isNewbieV = isNewbie.value
  let boughtGuids = purchasesExt.value
  return allGameModes.value.filter(function(gm) {
    if (!isEventGm(gm))
      return false
    let { requirePurchase = null } = gm?.extraParams
    if ((requirePurchase ?? "") != "")
      return requirePurchase in boughtGuids
    return (gm.queue == null
      || (gm.queue?.extraParams.newbies ?? false) == isNewbieV
      || ((gm.queue?.extraParams.availableForNoobs ?? false) && isNewbieV)
    )
  })
})

let allGameModesById = Computed(function() {
  let res = {}
  foreach (mode in allGameModes.value)
    res[mode.id] <- mode
  return res
})

let hasUnseenGameMode = Computed(@() mainGameModes.value
  .findvalue(@(gMode) gMode.id not in seenGamemodes.value?.seen))

let hasUnopenedGameMode = Computed(@() mainGameModes.value
  .findvalue(@(gMode) gMode.id not in seenGamemodes.value?.opened))

let currentGameMode = Computed(function() {
  let id = selGameModeId.value
  let allGm = mainGameModes.value.filter(@(gm) gm.isAvailable)

  return allGm.findvalue(@(gm) gm.scenes.contains(curUnfinishedBattleTutorial.value))
    ?? allGm.findvalue(@(gm) gm.id == id)
    ?? allGm.findvalue(@(gm) !gm.isLocal)
    ?? allGm?[0]
})

let currentGameModeId = Computed(@() currentGameMode.value?.id)

let function setGameMode(id) {
  let gameMode = mainGameModes.value.findvalue(@(gm) gm.id == id)
  if (gameMode != null) {
    if (onlineGameModes.value.contains(gameMode))
      savedGameModeIdByCampaign.mutate(@(v) v[curCampaign.value] <- id)
    else
      selGameModeIdByCampaign.mutate(@(v) v[curCampaign.value] <- id)
  }
  else
    logerr($"incorrect game mode selected {id}")
}

console_register_command(@() savedGameModeIdByCampaign.mutate({}), "meta.resetSavedGamemodes")

return {
  allGameModes
  allGameModesById
  mainGameModes
  eventGameModes
  currentGameModeId
  currentGameMode
  setGameMode
  hasUnseenGameMode
  hasUnopenedGameMode
  TANK_TUTORIAL_ID
  ENGINEER_TUTORIAL_ID
  AIRCRAFT_TUTORIAL_ID
  tutorialModes
  mainModes
}
