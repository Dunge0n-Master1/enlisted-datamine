from "%enlSqGlob/ui_library.nut" import *

let { READY } = require("%enlSqGlob/readyStatus.nut")

let mkSClassLimitsComp = @(squad, squadParams, soldiersList, soldiersStatuses) Computed(function() {
  let res = []
  let { maxClasses = {} } = squadParams.value
  if (maxClasses.len() == 0)
    return res

  let soldierStatus = soldiersStatuses.value
  let usedClasses = {}
  foreach (soldier in soldiersList.value) {
    if (soldierStatus?[soldier.guid] != READY)
      continue
    let { sKind = "" } = soldier
    usedClasses[sKind] <- (usedClasses?[sKind] ?? 0) + 1
  }

  let fillerClass = squad.value?.fillerClass
  foreach (sKind, total in maxClasses)
    res.append({
      sKind = sKind
      total = total
      used = usedClasses?[sKind] ?? 0
      isFiller = sKind == fillerClass
    })
  res.sort(@(a, b) a.isFiller <=> b.isFiller || b.total <=> a.total || a.sKind <=> b.sKind)
  return res
})

return mkSClassLimitsComp
