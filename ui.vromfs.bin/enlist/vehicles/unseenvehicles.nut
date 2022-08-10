from "%enlSqGlob/ui_library.nut" import *

let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { curArmiesList } = require("%enlist/meta/profile.nut")
let { chosenSquadsByArmy, armoryByArmy, vehicleBySquad, itemCountByArmy
} = require("%enlist/soldiers/model/state.nut")
let allowedVehicles = require("allowedVehicles.nut")
let { debounce } = require("%sqstd/timers.nut")

const SEEN_ID = "seen/vehicles"

let seen = Computed(@() settings.value?[SEEN_ID]) //<armyId> = { <basetpl> = true }

let unseenArmiesVehicle = Watched({})
let unseenSquadsVehicle = Watched({})

let notEquippedTiers = Computed(function() {
  let res = {}
  foreach (armyId in curArmiesList.value) {
    let itemsList = armoryByArmy.value?[armyId] ?? []
    let armyTpls = {}
    foreach (item in itemsList)
      if (item?.itemtype == "vehicle")
        armyTpls[item.basetpl] <- item?.tier ?? -1
    res[armyId] <- armyTpls
  }
  return res
})

let unseenTiers = Computed(@() !onlineSettingUpdated.value ? {}
  : notEquippedTiers.value.map(function(tiers, armyId) {
    let armySeen = seen.value?[armyId]
    return tiers.filter(@(_, basetpl) basetpl not in armySeen)
  }))

let chosenSquadsTiers = Computed(function() {
  let res = {}
  foreach (armyId in curArmiesList.value) {
    let armyVehicles = {}
    foreach (squad in chosenSquadsByArmy.value?[armyId] ?? []) {
      let { vehicleType = "" } = squad
      if (vehicleType != "")
        armyVehicles[squad.guid] <- {
          tier = vehicleBySquad.value?[squad.guid].tier ?? -1
          squadId = squad.squadId
        }
      }
    res[armyId] <- armyVehicles
  }
  return res
})

let function recalcUnseen() {
  let unseenArmies = {}
  let unseenSquads = {}

  foreach (armyId, tiers in unseenTiers.value) {
    unseenArmies[armyId] <- 0
    foreach (squadGuid, tierData in chosenSquadsTiers.value?[armyId] ?? []) {
      let { squadId, tier } = tierData
      let unseenVehicles = (allowedVehicles.value?[armyId][squadId] ?? {})
        .filter(@(isUsable, vehicleTpl) isUsable && tier < (tiers?[vehicleTpl] ?? -1))

      if (unseenVehicles.len() == 0)
        continue
      unseenSquads[squadGuid] <- unseenVehicles
      unseenArmies[armyId]++
    }
  }

  unseenArmiesVehicle(unseenArmies)
  unseenSquadsVehicle(unseenSquads)
}
recalcUnseen()
let recalcUnseenDebounced = debounce(recalcUnseen, 0.01)
unseenTiers.subscribe(@(_) recalcUnseenDebounced())
chosenSquadsTiers.subscribe(@(_) recalcUnseenDebounced())
allowedVehicles.subscribe(@(_) recalcUnseenDebounced())

let function markVehicleSeen(armyId, basetpl) {
  if (!onlineSettingUpdated.value || (seen.value?[armyId][basetpl] ?? false))
    return

  settings.mutate(function(set) {
    let saved = clone (set?[SEEN_ID] ?? {})
    let armySaved = clone (saved?[armyId] ?? {})
    armySaved[basetpl] <- true
    saved[armyId] <- armySaved
    set[SEEN_ID] <- saved
  })
}

let function markNotFreeVehiclesUnseen() {
  let seenData = seen.value ?? {}
  if (seenData.len() == 0)
    return false

  local hasChanges = false
  let newSeen = clone seenData
  foreach (armyId, curArmySeen in seenData) {
    let counts = itemCountByArmy.value?[armyId] ?? {}
    if (counts.len() == 0)
      continue

    let newArmySeen = curArmySeen.filter(@(_, tpl) tpl in counts)
    if (newArmySeen.len() < curArmySeen.len()) {
      newSeen[armyId] = newArmySeen
      hasChanges = true
    }
  }

  if (hasChanges)
    settings.mutate(@(set) set[SEEN_ID] <- newSeen)
  return hasChanges
}

itemCountByArmy.subscribe(function(_) {
  if (onlineSettingUpdated.value)
    markNotFreeVehiclesUnseen()
})

return {
  unseenArmiesVehicle
  unseenSquadsVehicle

  markVehicleSeen
}
