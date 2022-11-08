let scoreSquads = {
  kills = 30
  defenseKills = 15
  attackKills = 15
  tankKills = 100
  planeKills = 175
  captures = 100
  assists = 15
  tankKillAssists = 15
  planeKillAssists = 15
  reviveAssists = 45
  healAssists = 15
  crewKillAssists = 15
  crewTankKillAssists = 50
  crewPlaneKillAssists = 90
  tankKillAssistsAsCrew = 10
  planeKillAssistsAsCrew = 10
  builtStructures = 3
  builtGunKills = 15
  builtGunKillAssists = 5
  builtGunTankKills = 30
  builtGunTankKillAssists = 10
  builtGunPlaneKills = 45
  builtGunPlaneKillAssists = 15
  builtBarbwireActivations = 5
  builtAmmoBoxRefills = 15
  builtMedBoxRefills = 30
  builtCapzoneFortificationActivations = 5
  builtRallyPointUses = 30
  hostedOnSoldierSpawns = 15
  vehicleRepairs = 45
  vehicleExtinguishes = 45
  landings = 100
  barrageBalloonDestructions = 15
  enemyBuiltFortificationDestructions = 5
  enemyBuiltGunDestructions = 45
  enemyBuiltUtilityDestructions = 45

  // penalty
  friendlyHits = -30
  friendlyKills = -70
  friendlyKillsSamePlayer2Add = 0
  friendlyKillsSamePlayer3Add = -70
  friendlyKillsSamePlayer4Add = -140
  friendlyKillsSamePlayer5AndMoreAdd = -280
  friendlyTankHits = -25
  friendlyTankKills = -200
  friendlyPlaneHits = -50
  friendlyPlaneKills = -400

  // gun game
  gunGameLevelup = 1000
}

let expSquads = scoreSquads.__merge({
  killed = 60 //suicide does not count
})

let scoreAlone = scoreSquads.__merge({
  // Crew score is zero in no bots mode
  crewKillAssists = 0
  crewTankKillAssists = 0
  crewPlaneKillAssists = 0
  tankKillAssistsAsCrew = 0
  planeKillAssistsAsCrew = 0
})

let expAlone = scoreAlone.__merge({
  killed = 60 //suicide does not count
  // TODO correct score points needed
})

return {
  expSquads
  expAlone
  scoreSquads
  scoreAlone
}