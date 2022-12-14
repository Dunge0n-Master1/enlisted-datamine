from "%enlSqGlob/ui_library.nut" import *

let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { curCampaign, curArmy } = require("%enlist/soldiers/model/state.nut")
let debriefingState = require("%enlist/debriefing/debriefingStateInMenu.nut")
let { lastGame } = require("%enlist/gameLauncher.nut")
let { defTutorial, getTutorialScene, defTutorialTank, getTutorialTankScene,
  defTutorialEngineer, getTutorialEngineerScene, defTutorialAircraft, getTutorialAircraftScene,
  defPractice, getPracticeScene } = require("%enlist/configs/battleScenes.nut")

let SAVE_FOLDER = "battleTutorial"

let curTutorialGroup = Computed(function() {
  if ("campaigns" not in gameProfile.value) //disable network
    return {
      id = "notlogged"
      version = 1
      tutorialScene = defTutorial
      tutorialTankScene = defTutorialTank
      tutorialEngineerScene = defTutorialEngineer
      tutorialAircraftScene = defTutorialAircraft
      practiceScene = defPractice
    }

  let groupId = gameProfile.value?.campaigns[curCampaign.value].tutorial
  let group = gameProfile.value?.tutorials[groupId]
  if (groupId == null || group == null)
    return null

  return {
    id = groupId
    version = group?.version ?? 1
    tutorialScene = getTutorialScene(curArmy.value)
    tutorialTankScene = getTutorialTankScene(curArmy.value)
    tutorialEngineerScene = getTutorialEngineerScene(curArmy.value)
    tutorialAircraftScene = getTutorialAircraftScene(curArmy.value)
    practiceScene = getPracticeScene(curArmy.value)
  }
})

let curBattleTutorial = Computed(@() curTutorialGroup.value?.tutorialScene)
let curBattleTutorialTank = Computed(@() curTutorialGroup.value?.tutorialTankScene)
let curBattleTutorialEngineer = Computed(@() curTutorialGroup.value?.tutorialEngineerScene)
let curBattleTutorialAircraft = Computed(@() curTutorialGroup.value?.tutorialAircraftScene)
let curPractice = Computed(@() curTutorialGroup.value?.practiceScene)

let curUnfinishedBattleTutorial = Computed(function() {
  if (!onlineSettingUpdated.value)
    return null

  let group = curTutorialGroup.value
  if (group == null)
    return null

  let { version, id } = group
  return (settings.value?[SAVE_FOLDER][id] ?? 0) != version ? group.tutorialScene : null
})

let function markCompleted() {
  let group = curTutorialGroup.value
  if (group == null)
    return

  settings.mutate(function(saved) {
    let saveData = saved?[SAVE_FOLDER] ?? {}
    let { version, id } = group
    saved[SAVE_FOLDER] <- saveData.__merge({ [id] = version })
  })
}

let function resetTutorialsSave() {
  if (SAVE_FOLDER in settings.value)
    settings.mutate(function(saved) { delete saved[SAVE_FOLDER] })
}

let lastGameTutorialId = Computed(function() {
  let lastScene = lastGame.value?.scene
  if (lastScene == null)
    return null
  return lastScene == curTutorialGroup.value?.tutorialScene ? curTutorialGroup.value.id : null
})

debriefingState.data.subscribe(function(debData) {
  let { scene = null } = lastGame.value
  if (debData != null && (scene == curBattleTutorial.value
      || scene == curBattleTutorialTank.value
      || scene == curBattleTutorialEngineer.value
      || scene == curBattleTutorialAircraft.value))
    markCompleted()
})

console_register_command(markCompleted, "tutorial.markCompleted")
console_register_command(@() console_print($"current: {curBattleTutorial.value}",
  $"tank: {curBattleTutorialTank.value}",
  $"engineer: {curBattleTutorialEngineer.value}",
  $"aircraft: {curBattleTutorialAircraft.value}"), "tutorial.curTutorial")
console_register_command(resetTutorialsSave, "tutorial.resetComplete")

return {
  curBattleTutorial
  curBattleTutorialTank
  curBattleTutorialEngineer
  curBattleTutorialAircraft
  curPractice
  curUnfinishedBattleTutorial
  lastGameTutorialId
  markCompleted
}
