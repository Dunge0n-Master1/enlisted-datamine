from "%enlSqGlob/ui_library.nut" import *

const defTutorial = "content/enlisted/gamedata/scenes/tutorial/tutorial_training_ground_normandy_allies.blk" //used when profileServer unavaialble
let tutorialSceneByArmy = {
  berlin_axis = "content/enlisted/gamedata/scenes/tutorial/tutorial_training_ground_berlin_axis.blk"
  berlin_allies = "content/enlisted/gamedata/scenes/tutorial/tutorial_training_ground_berlin_allies.blk"
  moscow_axis = "content/enlisted/gamedata/scenes/tutorial/tutorial_training_ground_moscow_axis.blk"
  moscow_allies = "content/enlisted/gamedata/scenes/tutorial/tutorial_training_ground_moscow_allies.blk"
  normandy_axis = "content/enlisted/gamedata/scenes/tutorial/tutorial_training_ground_normandy_axis.blk"
  normandy_allies = "content/enlisted/gamedata/scenes/tutorial/tutorial_training_ground_normandy_allies.blk"
  tunisia_axis = "content/enlisted/gamedata/scenes/tutorial/tutorial_training_ground_tunisia_axis.blk"
  tunisia_allies = "content/enlisted/gamedata/scenes/tutorial/tutorial_training_ground_tunisia_allies.blk"
  stalingrad_axis = "content/enlisted/gamedata/scenes/tutorial/tutorial_training_ground_stalingrad_axis.blk"
  stalingrad_allies = "content/enlisted/gamedata/scenes/tutorial/tutorial_training_ground_stalingrad_allies.blk"
  pacific_axis = "content/enlisted/gamedata/scenes/tutorial/tutorial_training_ground_pacific_axis.blk"
  pacific_allies = "content/enlisted/gamedata/scenes/tutorial/tutorial_training_ground_pacific_allies.blk"
}

const defTutorialTank = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_tank.blk"
let tutorialTankSceneByArmy = {
  // all scenes are equal to default
}

const defTutorialEngineer = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_engineer.blk"
let tutorialEngineerSceneByArmy = {
  // all scenes are equal to default
}

const defTutorialAircraft = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_aircraft.blk"
let tutorialAircraftSceneByArmy = {
  // all scenes are equal to default
}

const defPractice = "content/enlisted/gamedata/scenes/tutorial/_common_training_ground.blk"
let practiceSceneByArmy = {
  berlin_axis = "content/enlisted/gamedata/scenes/tutorial/common_training_ground_berlin_axis.blk"
  berlin_allies = "content/enlisted/gamedata/scenes/tutorial/common_training_ground_berlin_allies.blk"
  moscow_axis = "content/enlisted/gamedata/scenes/tutorial/common_training_ground_moscow_axis.blk"
  moscow_allies = "content/enlisted/gamedata/scenes/tutorial/common_training_ground_moscow_allies.blk"
  normandy_axis = "content/enlisted/gamedata/scenes/tutorial/common_training_ground_normandy_axis.blk"
  normandy_allies = "content/enlisted/gamedata/scenes/tutorial/common_training_ground_normandy_allies.blk"
  tunisia_axis = "content/enlisted/gamedata/scenes/tutorial/common_training_ground_tunisia_axis.blk"
  tunisia_allies = "content/enlisted/gamedata/scenes/tutorial/common_training_ground_tunisia_allies.blk"
  stalingrad_axis = "content/enlisted/gamedata/scenes/tutorial/common_training_ground_stalingrad_axis.blk"
  stalingrad_allies = "content/enlisted/gamedata/scenes/tutorial/common_training_ground_stalingrad_allies.blk"
  pacific_axis = "content/enlisted/gamedata/scenes/tutorial/common_training_ground_pacific_axis.blk"
  pacific_allies = "content/enlisted/gamedata/scenes/tutorial/common_training_ground_pacific_allies.blk"
}

//local defTestDrive = "content/enlisted/gamedata/scenes/volokolamsk_city_assault_solo.blk"
let defTestDrive = defPractice
let testDriveSceneByArmy = practiceSceneByArmy


return {
  defTutorial
  getTutorialScene = @(armyId) tutorialSceneByArmy?[armyId] ?? defTutorial
  defTutorialTank
  getTutorialTankScene = @(armyId) tutorialTankSceneByArmy?[armyId] ?? defTutorialTank
  defTutorialEngineer
  getTutorialEngineerScene = @(armyId) tutorialEngineerSceneByArmy?[armyId] ?? defTutorialEngineer
  defTutorialAircraft
  getTutorialAircraftScene = @(armyId) tutorialAircraftSceneByArmy?[armyId] ?? defTutorialAircraft
  defPractice
  getPracticeScene = @(armyId) practiceSceneByArmy?[armyId] ?? defPractice
  defTestDrive
  getTestDriveScene = @(armyId) testDriveSceneByArmy?[armyId] ?? defTestDrive
}