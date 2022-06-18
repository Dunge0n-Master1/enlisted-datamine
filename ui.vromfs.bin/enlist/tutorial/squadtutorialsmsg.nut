from "%enlSqGlob/ui_library.nut" import *

let msgbox = require("%enlist/components/msgbox.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { squadsByArmy } = require("%enlist/soldiers/model/state.nut")
let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { allGameModesById, TANK_TUTORIAL_ID, AIRCRAFT_TUTORIAL_ID, ENGINEER_TUTORIAL_ID
} = require("%enlist/gameModes/gameModeState.nut")
let { curUnfinishedBattleTutorial } = require("%enlist/tutorial/battleTutorial.nut")
let canDisplayOffers = require("%enlist/canDisplayOffers.nut")
let gameLauncher = require("%enlist/gameLauncher.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")

const WND_UID = "tutorial_available_window"

let TUTORIALS = [
  {
    saveId = "tutorial/tank_tutorial_seen"
    squadType = "tank"
    gameMode = TANK_TUTORIAL_ID
    locId = "tutorial/tank_tutorial_available"
    bigQueryId = "open_tank_tutorial"
  }
  {
    saveId = "tutorial/aircraft_tutorial_seen"
    squadType = "aircraft"
    gameMode = AIRCRAFT_TUTORIAL_ID
    locId = "tutorial/aircraft_tutorial_available"
    bigQueryId = "open_aircraft_tutorial"
  }
  {
    saveId = "tutorial/engineer_tutorial_seen"
    squadType = "engineer"
    gameMode = ENGINEER_TUTORIAL_ID
    locId = "tutorial/engineer_tutorial_available"
    bigQueryId = "open_engineer_tutorial"
  }
]

let needShow = Computed(@() userInfo.value != null
  && !curUnfinishedBattleTutorial.value
  && onlineSettingUpdated.value
  && canDisplayOffers.value)

let needSquadByType = keepref(Computed(function() {
  if (!needShow.value)
    return null

  foreach (tutorial in TUTORIALS) {
    let { squadType, saveId, gameMode } = tutorial
    if (settings.value?[saveId] == true || !allGameModesById.value?[gameMode])
      continue
    foreach (armySquads in squadsByArmy.value)
      if (armySquads.findvalue(@(v) v?.squadType == squadType) != null)
        return tutorial
  }
  return null
}))

let storeShown = @(tutorial) settings.mutate(@(v) v[tutorial.saveId] <- true)

let function launchTutorial(tutorial) {
  let gameMode = allGameModesById.value?[tutorial.gameMode]
  if (!gameMode)
    return

  storeShown(tutorial)
  gameLauncher.startGame({
    game = "enlisted"
    scene = gameMode.scenes[0]
  })
}

let function show(tutorial) {
  sendBigQueryUIEvent(tutorial.bigQueryId)
  msgbox.show({
    uid = WND_UID
    text = loc(tutorial.locId)
    buttons = [
      {
        text = loc("Ok"),
        action = @() launchTutorial(tutorial)
        isCurrent = true
      }
      {
        text = loc("Cancel")
        action = @() storeShown(tutorial)
        isCancel = true
      }
    ]
  })
}

needSquadByType.subscribe(@(tutorial) tutorial ? show(tutorial) : null)

let resetTutorialSeen = @() settings.mutate(function(v) {
  foreach (tutorial in TUTORIALS)
    v[tutorial.saveId] <- false
})
console_register_command(resetTutorialSeen, "tutorial.resetTutorialsSeen")
