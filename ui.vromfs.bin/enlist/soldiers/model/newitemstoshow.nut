from "%enlSqGlob/ui_library.nut" import *

let { mark_as_seen } = require("%enlist/meta/clientApi.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { prepareItems, preferenceSort } = require("items_list_lib.nut")
let { curArmy } = require("state.nut")
let { soldiers, items } = require("%enlist/meta/servProfile.nut")
let { itemsByArmies, soldiersByArmies, commonArmy } = require("%enlist/meta/profile.nut")
let { collectSoldierData } = require("%enlist/soldiers/model/curSoldiersState.nut")
let { hasModalWindows } = require("%ui/components/modalWindows.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")


let justPurchasedItems = mkWatched(persist, "justPurchasedItems", [])

let newItems = Computed(function() {
  let res = itemsByArmies.value.map(@(armyItems)
    armyItems.filter(@(item) !(item?.wasSeen ?? true)))
  return res
})

let newSoldiers = Computed(function() {
  let res = soldiersByArmies.value.map(@(armySoldiers)
    armySoldiers.filter(@(soldier) !(soldier?.wasSeen ?? true)))
  return res
})

let newItemsToShow = Computed(function() {
  let { campaignByArmyId = null } = gameProfile.value
  if (campaignByArmyId == null || "items_templates" not in configs.value)
    return null

  let commonArmyId = commonArmy.value
  let curArmyId = curArmy.value

  let armyByGuid = {}
  let itemsObjects = {}
  foreach (armyId, armyItems in newItems.value) {
    if (armyId != curArmyId && armyId != commonArmyId)
      foreach (guid, _ in armyItems)
        armyByGuid[guid] <- armyId
    itemsObjects.__update(armyItems)
  }
  let joinedItems = prepareItems(itemsObjects.keys(), itemsObjects)

  local soldiersObjects = {}
  foreach (armyId, armySoldiers in newSoldiers.value) {
    if (armyId != curArmyId && armyId != commonArmyId)
      continue // FIXME temporary do not show soldiers from other companies because of data access limits
    /*
      foreach (guid, _ in armySoldiers)
        armyByGuid[guid] <- armyId
    */
    soldiersObjects.__update(armySoldiers)
  }
  soldiersObjects = soldiersObjects.map(collectSoldierData)

  let allItems = [].extend(
    joinedItems.sort(preferenceSort),
    soldiersObjects.values().sort(preferenceSort))
  return allItems.len() > 0
    ? {
        header = loc("battleRewardTitle")
        allItems
        itemsGuids = itemsObjects.keys()
        soldiersGuids = soldiersObjects.keys()
        armyByGuid
      }
    : null
})

let function markSeenGuids(objs, guids) {
  let res = clone objs
  foreach (guid in guids)
    if (guid in objs)
      res[guid] <- objs[guid].__merge({ wasSeen = true })
  return res
}

let isMarkSeenInProgress = Watched(false) //to ignore duplicate changes
let function markNewItemsSeen() {
  if (isMarkSeenInProgress.value || newItemsToShow.value == null)
    return

  let { itemsGuids, soldiersGuids } = newItemsToShow.value
  isMarkSeenInProgress(true)
  mark_as_seen(itemsGuids, soldiersGuids, @(_) isMarkSeenInProgress(false))

  //no need to wait for server answer to close this window
  let newSoldiersData = markSeenGuids(soldiers.value, soldiersGuids)
  soldiers.update(newSoldiersData)

  let newItemsData = markSeenGuids(items.value, itemsGuids)
  items.update(newItemsData)
}

return {
  needNewItemsWindow = Computed(@() newItemsToShow.value != null && !hasModalWindows.value)
  newItemsToShow
  markNewItemsSeen
  justPurchasedItems
}
