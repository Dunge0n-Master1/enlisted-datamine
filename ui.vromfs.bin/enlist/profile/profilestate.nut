from "%enlSqGlob/ui_library.nut" import *

let { round_by_value } = require("%sqstd/math.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")


let isProfileOpened = mkWatched(persist, "isProfileOpened", false)

let killsList = [
  "rifle_kills"
  "submachine_gun_kills"
  "machine_gun_kills"
  "grenade_kills"
  "kills_using_tank"
  "kills_using_aircraft"
  "artillery_kills"
  "flamethrower_kills"
  "pistol_kills"
  "mortar_kills"
  "melee_kills"
  "launcher_kills"
  "tank_kills"
  "aircraft_kills"
]

let playerStatsList = [
  {
    statId = "battles"
    calculator = @(stat) stat?.battles ?? 0
  }
  {
    statId = "killsDeaths"
    calculator = @(stat) $"{stat?.kills ?? 0}/{stat?.deaths ?? 0}"
  }
  {
    statId = "winRate"
    unitSign = "%"
    calculator = function(stat) {
      let { victories = 0, defeats = 0 } = stat
      let battles = victories + defeats
      return battles <= 0 ? 0
        : round_by_value(100.0 * victories / battles, 0.01)
    }
  }
  {
    statId = "battleTime"
    calculator = @(stat) secondsToHoursLoc(stat?.battle_time ?? 0)
  }
]

return {
  isProfileOpened
  playerStatsList
  killsList
}
