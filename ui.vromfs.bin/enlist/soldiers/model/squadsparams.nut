from "%enlSqGlob/ui_library.nut" import *

let { tablesCombine } = require("%sqstd/underscore.nut")
let { squadsCfgById } = require("config/squadsConfig.nut")
let armyEffects = require("armyEffects.nut")

let function calcSquadParams(effects, squadId, squad) {
  let size = squad.size + (effects?.squad_size[squadId] ?? 0)
  return {
    size = size
    maxClasses = tablesCombine(squad?.maxClasses ?? {},
      effects?.squad_class_limit[squadId] ?? {},
      @(a, b) min(a + b, size),
      0)
  }
}

let squadsParams = Computed(function() {
  let effects = armyEffects.value
  return squadsCfgById.value.map(
    @(armySquads, armyId) armySquads.map(
      @(squad, squadId) calcSquadParams(effects?[armyId], squadId, squad)))
})

return squadsParams