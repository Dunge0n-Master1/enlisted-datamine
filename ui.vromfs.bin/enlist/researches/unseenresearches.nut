from "%enlSqGlob/ui_library.nut" import *

let { allResearchStatus, CAN_RESEARCH, RESEARCHED } = require("researchesState.nut")
let { settings } = require("%enlist/options/onlineSettings.nut")

const SEEN_ID = "seen/researches"

let seen = Computed(@() settings.value?[SEEN_ID])

let unseen = Computed(@() allResearchStatus.value
  .map(@(armyResearches, armyId) armyResearches
    .filter(@(status, id) status == CAN_RESEARCH && !(seen.value?[armyId][id] ?? false))))

let function markSeen(armyId, researchesList) {
  let filtered = researchesList.filter(@(id) unseen.value?[armyId][id] ?? false)
  if (filtered.len() == 0)
    return

  let saved = settings.value?[SEEN_ID] ?? {}
  let armySaved = saved?[armyId] ?? {}
  //clear all researched from seen in profile
  let armyNewData = armySaved.filter(@(_, id) (allResearchStatus.value?[armyId][id] ?? RESEARCHED) != RESEARCHED)
  foreach(id in filtered)
    armyNewData[id] <- true
  settings.mutate(function(s) {
    let newSaved = clone saved
    newSaved[armyId] <- armyNewData
    s[SEEN_ID] <- newSaved
  })
}

let function resetSeen() {
  let reseted = (settings.value?[SEEN_ID] ?? []).len()
  if (reseted > 0)
    settings.mutate(@(s) delete s[SEEN_ID])
  return reseted
}

console_register_command(@() console_print("Reseted armies count = {0}".subst(resetSeen())), "meta.resetSeenResearches")

return {
  unseenResearches = unseen
  markSeen = markSeen
}