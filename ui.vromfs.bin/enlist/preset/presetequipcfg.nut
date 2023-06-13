from "%enlSqGlob/ui_library.nut" import *

let { mkOnlineSaveData } = require("%enlSqGlob/mkOnlineSaveData.nut")
let { hasPremium } = require("%enlist/currency/premium.nut")
let premiumWnd = require("%enlist/currency/premiumWnd.nut")
let { getKindCfg } = require("%enlSqGlob/ui/soldierClasses.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")
let { curArmy, armoryByArmy, getSoldierItemSlots
} = require("%enlist/soldiers/model/state.nut")
let { curSoldierInfo } = require("%enlist/soldiers/model/curSoldiersState.nut")
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { getPossibleUnequipList, getAlternativeEquipList, getPossibleEquipList,
  getBetterItem, getWorseItem
} = require("%enlist/soldiers/model/selectItemState.nut")

let { configs } = require("%enlist/meta/configs.nut")

// equipment presets = {
//  moscow_allies = {
//      tanker = [
//         {
//            name = "Preset 1 for Tanker"
//            items = [ {slotType = ..., slotId = ..., itemTpl = ...}, ... ]
//         }
//         {
//            name = "Preset 2 for Tanker"
//            items = [ {slotType = ..., slotId = ..., itemTpl = ...}, ... ]
//         }
//      }
//      sniper = [ ... ]
//   }
// }

let equipmentPresetsStorage = mkOnlineSaveData("presetEquipment", @() {})
let setEquipmentPreset = equipmentPresetsStorage.setValue
let equipmentPresetWatch = equipmentPresetsStorage.watch

const SLOT_COUNT = 2
const SLOT_COUNT_MAX = 3
let slotCount = Computed(@() hasPremium.value ? SLOT_COUNT_MAX : SLOT_COUNT)

let mkGuidsTbl = @(list)
  list.reduce(@(tbl, i) i.guid != "" ? tbl.rawset(i.guid, true) : tbl, {}) //warning disable: -unwanted-modification


let minimumEquipList = function(soldier, _items, usedItems, notFoundItemsWatch) {
  let unequipList = getPossibleUnequipList(soldier.guid)
  let changeEquipList = getAlternativeEquipList(soldier,
    getWorseItem, unequipList, usedItems).extend(unequipList)

  notFoundItemsWatch({})
  usedItems = mkGuidsTbl(changeEquipList) //warning disable: -assigned-never-used
  return changeEquipList
}

let bestEquipList = function(soldier, _items, usedItems, notFoundItemsWatch) {
  let toAddEquipList = getPossibleEquipList(soldier, usedItems)
  let changeEquipList = getAlternativeEquipList(soldier, getBetterItem, [], usedItems)
    .extend(toAddEquipList)

  notFoundItemsWatch({})
  usedItems = mkGuidsTbl(changeEquipList) //warning disable: -assigned-never-used
  return changeEquipList
}


let itemListByTpl = function(itemTpl, usedItems) {
  let inventory = armoryByArmy.value?[curArmy.value] ?? []
  let availableItems = inventory
    .filter(@(item) itemTpl == trimUpgradeSuffix(item.basetpl)
      && item.guid not in usedItems)
    .sort(@(a, b) (b?.tier ?? 0) <=> (a?.tier ?? 0))
  return availableItems
}

let selectedEquipList = function(presetList, slot) {
  let presetVal = presetList?[slot]
  if (presetVal == null)
    return null

  return function(soldier, campItemsByLinkVal, usedItems, notFoundItemsWatch) {
    usedItems = {}
    let presetSlots = {}
    presetVal.items.each(@(slotData) presetSlots[slotData.slotType] <-
      (presetSlots?[slotData.slotType] ?? 0) + 1 )

    let toReplace = []
    let changeEquipList = []
    let slotsItems = getSoldierItemSlots(soldier.guid, campItemsByLinkVal)
    foreach (equippedItem in slotsItems) {
      let { slotType, slotId } = equippedItem
      let presetItem = presetVal.items.findvalue(@(i)
        i.slotType == slotType && i.slotId == slotId)
      if (presetItem == null) {
        changeEquipList.append({
          item = null
          slotType
          slotId
        })
        continue
      }

      presetSlots[slotType] -= 1
      if (trimUpgradeSuffix(equippedItem?.item.basetpl) == presetItem.itemTpl
        || (equippedItem?.item.isFixed ?? false) ) {
          continue
      }
      toReplace.append(slotType)
    }

    slotsItems.each(function(item) {
      if (item.slotType in presetSlots && presetSlots[item.slotType] == 0)
        delete presetSlots[item.slotType]
    })

    let usedGuids = {}
    let notFoundTbl = {}

    foreach (slotType in toReplace.extend(presetSlots.keys())) {
      let presetItems = presetVal.items.filter(@(i) i.slotType == slotType)
        .sort(@(a,b) a.slotId <=> b.slotId) //warning disable: -unwanted-modification
      local availableItems = {}

      foreach (presetItem in presetItems) {
        let { itemTpl } = presetItem
        if (itemTpl not in availableItems) {
          availableItems[itemTpl] <-
            itemListByTpl(presetItem.itemTpl, usedItems)
        }

        let itemData = clone presetItem
        if (availableItems[itemTpl].len() == 0) {
          itemData.shopItem <- itemTpl
          notFoundTbl[itemTpl] <- (notFoundTbl?[itemTpl] ?? 0) + 1
        } else {
          let item = availableItems[itemTpl].pop()
          itemData.item <- item
          usedGuids[item.guid] <- true
        }
        changeEquipList.append(itemData)
      }
    }

    notFoundItemsWatch(notFoundTbl)
    usedItems = usedGuids //warning disable: -assigned-never-used
    return changeEquipList
  }
}

let updateStorage = function(presetTbl, armyId, sKind, slot, newData) {
  local storage = clone presetTbl ?? {}
  let armyStorage = clone storage?[armyId] ?? {}
  storage[armyId] <- armyStorage
  let kindStorage = clone armyStorage?[sKind] ?? array(SLOT_COUNT_MAX)
  armyStorage[sKind] <- kindStorage
  if (kindStorage.len() <= slot)
    kindStorage.resize(SLOT_COUNT_MAX)

  let presetData = kindStorage[slot] ?? {}
  kindStorage[slot] = freeze(presetData.__merge(newData))
  setEquipmentPreset(storage)
}

let savePreset = @(presetTbl, slot) function(soldier, campItemsByLinkVal) {
  if (soldier == null) {
    return false
  }

  let { armyId, sKind } = soldier
  let slotsItems = getSoldierItemSlots(soldier.guid, campItemsByLinkVal)
  let presetData = {
    name = presetTbl?[armyId][sKind][slot].name ?? loc("preset/equip/name",
      { order = getRomanNumeral(slot + 1), kind = loc(getKindCfg(sKind).locId) })
    items = slotsItems.apply(@(equippedItem) {
      slotType = equippedItem.slotType
      slotId = equippedItem.slotId
      itemTpl = trimUpgradeSuffix(equippedItem.item.basetpl)
    })
  }

  updateStorage(presetTbl, armyId, sKind, slot, presetData)
  return true
}

let presetSlotName = @(preset, index)
  preset?.name ?? loc("btn/preset/name", { count = getRomanNumeral(index + 1) })

let slotsIncrease = function(presetList, index) {
  let items = presetList?[index].items ?? []
  let result = {}
  items.each(function(slotData) {
    foreach (slotType, tplsList in configs.value?.equip_slot_increase ?? {})
      if (slotData.itemTpl in tplsList)
        result[slotType] <- tplsList[slotData.itemTpl]
  })
  return items.len() == 0 ? null : result
}

let renamePreset = function(presetTbl, presetList, slot) {
  if (presetList?[slot] == null)
    return null

  return @(soldier, name)
    updateStorage(presetTbl, soldier.armyId, soldier.sKind, slot, { name })
}

let autoPresets = [
  { locId = loc("autoEquip"), fnApply = bestEquipList }
  { locId = loc("removeAllEquipment"), fnApply = minimumEquipList }
]


let mkSlotDesc = @(presetTbl, presetList, i) {
  locId = presetSlotName(presetList?[i], i)
  fnApply = selectedEquipList(presetList, i)
  fnRename = renamePreset(presetTbl, presetList, i)
  fnSave = savePreset(presetTbl, i)
  slotsIncrease = slotsIncrease(presetList, i)
}

let mkSlotPrem = @(presetList, i) {
  locId = presetList?[i].name ?? loc("btn/preset/locked")
  onClick = @() premiumWnd()
  fnApply = selectedEquipList(presetList, i)
  isLockedPrem = true
}

let presetList = Computed(function() {
  let allPresets = clone autoPresets
  let armyId = curArmy.value
  let sKind = curSoldierInfo.value?.sKind
  for (local i = 0; i < SLOT_COUNT_MAX; i++) {
    let idx = i
    allPresets.append(i < slotCount.value
      ? mkSlotDesc(equipmentPresetWatch.value,
          equipmentPresetWatch.value?[armyId][sKind], idx)
      : mkSlotPrem(equipmentPresetWatch.value?[armyId][sKind], idx))
  }
  return allPresets
})

return {
  presetEquipList = presetList
  equipmentPresetWatch
  resetEquipmentPreset = @() setEquipmentPreset({})
}
