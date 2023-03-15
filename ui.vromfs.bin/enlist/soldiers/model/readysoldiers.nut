from "%enlSqGlob/ui_library.nut" import *

let { debounce } = require("%sqstd/timers.nut")
let {
  curSquad, curSquadSoldiersInfo, soldiersBySquad, vehicleBySquad, objInfoByGuid,
  curCampSquads, curCampItems
} = require("state.nut")
let { getLinkedArmyName, getLinkedSlotData } = require("%enlSqGlob/ui/metalink.nut")
let squadsParams = require("squadsParams.nut")
let readyStatus = require("%enlSqGlob/readyStatus.nut")
let { READY, OUT_OF_VEHICLE, TOO_MUCH_CLASS, OUT_OF_SQUAD_SIZE, NOT_READY_BY_EQUIP } = readyStatus
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let sClassesConfig = require("config/sClassesConfig.nut")
let { curCampSoldiers } = require("%enlist/meta/profile.nut")

let invalidEquipSoldiers = mkWatched(persist, "invalidEquipSoldiers")

let function updateInvalidSoldiers() {
  let equippedItems = {}
  foreach (item in curCampItems.value) {
    let sd = getLinkedSlotData(item)
    if (sd == null)
      continue
    let { linkTgt, linkSlot } = sd
    if (linkTgt not in equippedItems)
      equippedItems[linkTgt] <- {}
    equippedItems[linkTgt][linkSlot] <- item
  }

  let invalid = curCampSoldiers.value
    .filter(function(soldier) {
      if (soldier?.hasVerified == false)
        return true

      let { equipScheme = null } = soldier
      if (equipScheme == null)
        return false //mostly happen on login when configs not received yet

      let slotsData = {}
      foreach (slotType, slot in equipScheme) {
        let { atLeastOne = "" } = slot
        if (atLeastOne == "" || slotsData?[atLeastOne] == true)
          continue

        let item = equippedItems?[soldier.guid][slotType]
        slotsData[atLeastOne] <- item != null
        if (item == null)
          continue

        local { basetpl, itemtype } = item
        basetpl = trimUpgradeSuffix(basetpl)
        let { items = [], itemTypes = [] } = slot
        if ((itemTypes.len() != 0 || items.len() != 0)
            && itemTypes.indexof(itemtype) == null
            && items.indexof(basetpl) == null)
          return true
      }
      return slotsData.findindex(@(s) !s) != null
    })
    .map(@(_) true)

  if (!isEqual(invalid, invalidEquipSoldiers.value))
    invalidEquipSoldiers(invalid)
}
if (invalidEquipSoldiers.value == null)
  updateInvalidSoldiers()
let updateInvalidSoldiersDebounced = debounce(updateInvalidSoldiers, 0.01)
curCampItems.subscribe(@(_) updateInvalidSoldiersDebounced())
curCampSoldiers.subscribe(@(_) updateInvalidSoldiersDebounced())

let getSoldiersBattleReady = kwarg(
  function(squadSize, maxClasses, soldiers, vehicle, invalidSoldiers, classesCfg) {
    let res = {}
    let vehicleSize = vehicle?.crew ?? squadSize
    local totalReady = 0
    let usedClasses = {}
    foreach (soldier in soldiers) {
      local state = READY
      let sKind = soldier?.sKind ?? classesCfg?[soldier.sClass].kind
      if (soldier.guid in invalidSoldiers)
        state = state | NOT_READY_BY_EQUIP
      else if (totalReady >= squadSize)
        state = state | OUT_OF_SQUAD_SIZE
      else if ((usedClasses?[sKind] ?? 0) >= (maxClasses?[sKind] ?? 0))
        state = state | TOO_MUCH_CLASS
      else {
        if (totalReady >= vehicleSize)
          state = state | OUT_OF_VEHICLE
        totalReady++
        usedClasses[sKind] <- (usedClasses?[sKind] ?? 0) + 1
      }

      res[soldier.guid] <- state
    }

    return res
  })

let soldiersStatuses = Computed(function() {
  let res = {}
  let sqParams = squadsParams.value
  foreach (squad in curCampSquads.value) {
    let armyId = getLinkedArmyName(squad)
    let params = sqParams?[armyId][squad.squadId]
    if (params == null)
      continue

    let vehicleGuid = vehicleBySquad.value?[squad.guid].guid
    res.__update(getSoldiersBattleReady({
      squadSize = params?.size ?? 0
      maxClasses = params?.maxClasses ?? {}
      soldiers = (soldiersBySquad.value?[squad.guid] ?? [])
        .map(@(soldier) objInfoByGuid.value?[soldier.guid] ?? soldier)
      vehicle = vehicleGuid ? objInfoByGuid.value?[vehicleGuid] : null
      invalidSoldiers = invalidEquipSoldiers.value
      classesCfg = sClassesConfig.value
    }))
  }
  return res
})

let curSquadSoldiersStatus = Computed(function() {
  let res = {}
  foreach (soldier in soldiersBySquad.value?[curSquad.value?.guid] ?? [])
    res[soldier.guid] <- soldiersStatuses.value?[soldier.guid] ?? OUT_OF_SQUAD_SIZE
  return res
})

let curSquadSoldiersReady = Computed(@() curSquadSoldiersInfo.value.filter(@(soldier)
  curSquadSoldiersStatus.value?[soldier?.guid] == READY))

return {
  soldiersStatuses = soldiersStatuses
  curSquadSoldiersStatus = curSquadSoldiersStatus
  curSquadSoldiersReady = curSquadSoldiersReady
  invalidEquipSoldiers = invalidEquipSoldiers
}.__update(readyStatus)
