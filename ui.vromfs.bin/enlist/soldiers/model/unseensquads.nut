from "%enlSqGlob/ui_library.nut" import *

let { armySquadsById } = require("state.nut")
let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { squadsCfgById } = require("config/squadsConfig.nut")

const SEEN_ID = "seen/squads"

let seen = Computed(@() settings.value?[SEEN_ID])

let squadsToCheck = Computed(@() squadsCfgById.value.map(@(squadsList, armyId)
  squadsList
    .filter(@(s) (s?.unlockCost ?? 0) > 0)
    .map(@(_, squadId) armySquadsById.value?[armyId][squadId])))

let unseenSquads = Computed(@() onlineSettingUpdated.value
  ? squadsToCheck.value
      .map(@(squadsList, armyId) squadsList
        .map(@(squad, squadId) squad != null && !(squadId in seen.value?[armyId])))
  : {})

let function resetSeen() {
  settings.mutate(@(v) delete v[SEEN_ID])
}

let function markSeenSquads(armyId, squadIdsList) {
  let filtered = squadIdsList.filter(@(squadId) unseenSquads.value?[armyId][squadId] ?? false)
  if (filtered.len() == 0)
    return
  settings.mutate(function(set) {
    let saved = clone (set?[SEEN_ID] ?? {})
    let armySaved = clone (saved?[armyId] ?? {})
    filtered.each(@(squadId) armySaved[squadId] <- true)
    saved[armyId] <- armySaved
    set[SEEN_ID] <- saved
  })
}

console_register_command(resetSeen, "meta.resetSeenSquads")

return {
  unseenSquads
  markSeenSquads
}
