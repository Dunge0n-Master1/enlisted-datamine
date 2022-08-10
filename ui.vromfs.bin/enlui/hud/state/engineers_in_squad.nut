from "%enlSqGlob/ui_library.nut" import *

let {watchedHeroSquadMembers} = require("%ui/hud/state/squad_members.nut")

let function getEngineersCount(list){
  local enginersCount = 0
  foreach (soldier in list){
    if (soldier.isAlive && soldier.weapTemplates.secondary.contains("building_tool"))
      enginersCount++
  }
  return enginersCount
}

let engineersInSquad = Computed(@() getEngineersCount(watchedHeroSquadMembers.value))

return engineersInSquad