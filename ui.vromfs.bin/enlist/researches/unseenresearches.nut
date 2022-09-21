from "%enlSqGlob/ui_library.nut" import *

let { allResearchStatus, CAN_RESEARCH, RESEARCHED } = require("researchesState.nut")
let { settings } = require("%enlist/options/onlineSettings.nut")

const SEEN_ID = "seen/researches"

enum SeenMarks {
  NOT_SEEN = 0
  OPENED = 1
  SEEN = 2
}

let getSeenStatus = @(val) val == true || val == SeenMarks.SEEN ? SeenMarks.SEEN
  : val == SeenMarks.OPENED ? SeenMarks.OPENED
  : SeenMarks.NOT_SEEN

let seenResearches = Computed(function() {
  let seen = {}
  let opened = {}
  foreach(armyId, armySeen in settings.value?[SEEN_ID] ?? {})
    foreach(key, seenData in armySeen) {
      if (getSeenStatus(seenData) != SeenMarks.NOT_SEEN) {
        if (armyId not in opened)
          opened[armyId] <- {}
        opened[armyId][key] <- true
      }
      if (getSeenStatus(seenData) == SeenMarks.SEEN) {
        if (armyId not in seen)
          seen[armyId] <- {}
        seen[armyId][key] <- true
      }
    }
  let allResearches = allResearchStatus.value
  let unseen = allResearches
    .map(@(armyResearches, armyId) armyResearches
      .filter(@(status, id) status == CAN_RESEARCH && !(seen?[armyId][id] ?? false)))
  let unopened = allResearches
    .map(@(armyResearches, armyId) armyResearches
      .filter(@(status, id) status == CAN_RESEARCH && !(opened?[armyId][id] ?? false)))

  return { seen, opened, unseen, unopened }
})

let function markSeen(armyId, researchesList, isOpened = false) {
  let filtered = researchesList.filter(@(id) id in seenResearches.value?.unseen[armyId])
  if (filtered.len() == 0)
    return

  let mark = isOpened ? SeenMarks.OPENED : SeenMarks.SEEN
  let saved = settings.value?[SEEN_ID] ?? {}
  let armySaved = saved?[armyId] ?? {}
  //clear all researched from seen in profile
  let armyNewData = armySaved.filter(@(_, id)
    (allResearchStatus.value?[armyId][id] ?? RESEARCHED) != RESEARCHED)
  foreach (id in filtered)
    armyNewData[id] <- mark
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
  markSeen
  seenResearches
}
