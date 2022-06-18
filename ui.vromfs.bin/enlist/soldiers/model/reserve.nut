from "%enlSqGlob/ui_library.nut" import *

let squadsParams = require("squadsParams.nut")
let { soldiersByArmies } = require("%enlist/meta/profile.nut")
let { unseenSoldiers } = require("unseenSoldiers.nut")
let {
  curArmy, curArmiesList, limitsByArmy, getItemIndex, soldiersBySquad,
  curChoosenSquads
} = require("state.nut")
let { getLinkedSquadGuid } = require("%enlSqGlob/ui/metalink.nut")


let allReserveSoldiers = Computed(function() {
  let res = {}
  foreach (armyId in curArmiesList.value) {
    res[armyId] <- (soldiersByArmies.value?[armyId] ?? {})
      .filter(@(s) getLinkedSquadGuid(s) == null)
      .values()
      .sort(@(a, b) getItemIndex(a) <=> getItemIndex(b))
  }
  return res
})

let curArmyReserve = Computed(@() allReserveSoldiers.value?[curArmy.value] ?? [])

let curArmyReserveCapacity = Computed(@() limitsByArmy.value?[curArmy.value].soldiersReserve ?? 0)

let hasCurArmyReserve = Computed(@() curArmyReserve.value.len() < curArmyReserveCapacity.value)

let needSoldiersManageBySquad = Computed(function() {
  let res = {}
  let curReserve = curArmyReserve.value ?? []
  if (curReserve.len() <= 0)
    return res

  let curUnseen = unseenSoldiers.value
  let armyId = curArmy.value
  foreach (squad in curChoosenSquads.value) {
    let squadParams = squadsParams.value?[armyId][squad?.squadId]
    let squadSoldiers = soldiersBySquad.value?[squad?.guid] ?? []
    if ((squadParams?.size ?? 0) <= squadSoldiers.len())
      continue

    let reqSoldiers = clone (squadParams?.maxClasses ?? {})
    foreach (soldier in squadSoldiers) {
      let sClass = soldier.sClass
      if (sClass in reqSoldiers)
        reqSoldiers[sClass]--
    }
    let soldier = curReserve.findvalue(@(s) (curUnseen?[s.guid] ?? false)
      && (reqSoldiers?[s.sClass] ?? 0) > 0)
    if (soldier != null)
      res[squad.guid] <- true
  }

  return res
})

return {
  allReserveSoldiers
  curArmyReserve
  curArmyReserveCapacity
  hasCurArmyReserve
  needSoldiersManageBySquad
}
