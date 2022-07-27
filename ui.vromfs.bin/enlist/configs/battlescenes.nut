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
}

const defTutorialTank = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_tank.blk"
let tutorialTankSceneByArmy = {
  berlin_axis = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_tank.blk"
  berlin_allies = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_tank.blk"
  moscow_axis = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_tank.blk"
  moscow_allies = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_tank.blk"
  normandy_axis = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_tank.blk"
  normandy_allies = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_tank.blk"
  tunisia_axis = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_tank.blk"
  tunisia_allies = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_tank.blk"
  stalingrad_axis = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_tank.blk"
  stalingrad_allies = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_tank.blk"
}

const defTutorialEngineer = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_engineer.blk"
let tutorialEngineerSceneByArmy = {
  berlin_axis = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_engineer.blk"
  berlin_allies = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_engineer.blk"
  moscow_axis = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_engineer.blk"
  moscow_allies = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_engineer.blk"
  normandy_axis = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_engineer.blk"
  normandy_allies = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_engineer.blk"
  tunisia_axis = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_engineer.blk"
  tunisia_allies = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_engineer.blk"
  stalingrad_axis = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_engineer.blk"
  stalingrad_allies = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_engineer.blk"
}

const defTutorialAircraft = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_aircraft.blk"
let tutorialAircraftSceneByArmy = {
  berlin_axis = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_aircraft.blk"
  berlin_allies = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_aircraft.blk"
  moscow_axis = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_aircraft.blk"
  moscow_allies = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_aircraft.blk"
  normandy_axis = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_aircraft.blk"
  normandy_allies = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_aircraft.blk"
  tunisia_axis = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_aircraft.blk"
  tunisia_allies = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_aircraft.blk"
  stalingrad_axis = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_aircraft.blk"
  stalingrad_allies = "content/enlisted/gamedata/scenes/tutorial/_tutorial_training_ground_aircraft.blk"
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
}

//local defTestDrive = "content/enlisted/gamedata/scenes/volokolamsk_city_assault_solo.blk"
let defTestDrive = defPractice
let testDriveSceneByArmy = practiceSceneByArmy


return {
  defTutorial
  tutorialSceneByArmy
  defTutorialTank
  tutorialTankSceneByArmy
  defTutorialEngineer
  tutorialEngineerSceneByArmy
  defTutorialAircraft
  tutorialAircraftSceneByArmy
  defPractice
  practiceSceneByArmy
  defTestDrive
  testDriveSceneByArmy
}