from "%enlSqGlob/ui_library.nut" import *

let { curArmy, getSoldierItemSlots, objInfoByGuid } = require("%enlist/soldiers/model/state.nut")
let { curSoldierInfo } = require("%enlist/soldiers/model/curSoldiersState.nut")
let { campItemsByLink, curCampSoldiers } = require("%enlist/meta/profile.nut")
let { getLinkedArmyName, getLinkedSquadGuid } = require("%enlSqGlob/ui/metalink.nut")
let sClassesCfg = require("%enlist/soldiers/model/config/sClassesConfig.nut")
let { equipByList } = require("%enlist/soldiers/model/itemActions.nut")
let { presetEquipList, resetEquipmentPreset } = require("presetEquipCfg.nut")
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { allItemTemplates, findItemTemplate
} = require("%enlist/soldiers/model/all_items_templates.nut")
let { mkShopItem } = require("%enlist/soldiers/model/items_list_lib.nut")
let { classSlotLocksByArmy } = require("%enlist/researches/researchesSummary.nut")

let notFoundItems = Watched({})

enum PreviewState {
  OK = "replace"
  ERROR = "noReplace"
  NONE = "none"
}

let shopItemByTemplateData = function(itemTpl) {
  let templateId = trimUpgradeSuffix(itemTpl)
  let template = findItemTemplate(allItemTemplates, curArmy.value, templateId)
  return mkShopItem(templateId, template, curArmy.value)
}

let canEquip = @(slotData)
  !(slotData?.shopItem != null || (slotData?.item.isFixed ?? false))

let expandedSlotTypes = ["inventory", "grenade"]

let isLocked = @(lockedSlots, slotData, needRemoveExpanded)
  lockedSlots.contains(slotData.slotType)
    || (needRemoveExpanded && expandedSlotTypes.contains(slotData.slotType) && slotData.slotId > 0)

let makePreviewList = function(soldier, slotsItems, changeEquipList) {
  if (changeEquipList.len() == 0)
    return slotsItems

  let lockedSlots = classSlotLocksByArmy.value?[getLinkedArmyName(soldier)][soldier.sClass] ?? []
  let removeExpanded = lockedSlots.contains("backpack")

  foreach(slotData in changeEquipList) {
    // existing autoequip functions forms a list with guids
    // and do not assign item and previewState
    if (slotData?.item == null) {
      let item = slotData?.shopItem == null
        ? slotData?.guid == null ? null : objInfoByGuid.value?[slotData.guid]
        : shopItemByTemplateData(slotData.shopItem)
      slotData.item <- item
    }
    // end actions to adapt for existing functions

    slotData.previewState <- canEquip(slotData) && !isLocked(lockedSlots, slotData, removeExpanded)
      ? PreviewState.OK : PreviewState.ERROR

    let equippedItem = slotsItems.findvalue(@(i)
      i.slotType == slotData.slotType && i.slotId == slotData.slotId)

    if (equippedItem == null)
      slotsItems.append(slotData)
    else
      equippedItem.__update(slotData)
  }

  return slotsItems
}

let getItemSlotsWithPreset = function(soldier, campItemsByLinkVal, presetCfg) {
  let usedItems = {}
  let changeEquipList = presetCfg?.fnApply(soldier, campItemsByLinkVal, usedItems, notFoundItems) ?? []
  let slotsItems = getSoldierItemSlots(soldier.guid, campItemsByLinkVal)
  return makePreviewList(soldier, slotsItems, changeEquipList)
}

let applyEquipmentToSoldier = function(presetCfg, soldier, usedItemsTbl, notFoundItemsWatch) {

  let changeEquipList = presetCfg?.fnApply(soldier, campItemsByLink.value,
    usedItemsTbl, notFoundItemsWatch) ?? []

  if (changeEquipList.len() > 0) {
    let lockedSlots = classSlotLocksByArmy.value?[getLinkedArmyName(soldier)][soldier.sClass] ?? []
    let removeExpanded = lockedSlots.contains("backpack")

    equipByList(soldier.guid, changeEquipList
      .filter(@(slotData) canEquip(slotData) && !isLocked(lockedSlots, slotData, removeExpanded))
      .map(@(i) {
        guid = i?.guid ?? (i?.item.guid ?? "")
        slotType = i.slotType
        slotId = i.slotId
      }
    ))
  }
}

enum PresetTarget {
  SOLDIER = "soldier"
  SQUAD = "squad"
  ALL = "all"
}

let getSoldierKind = @(sClass) sClassesCfg.value?[sClass].kind ?? sClass

let targetFilters = {
  [PresetTarget.SOLDIER] = @(soldier, guid, _sKind, _squad) soldier.guid == guid,
  [PresetTarget.SQUAD] = @(soldier, _guid, sKind, squad) getLinkedSquadGuid(soldier) == squad
    && getSoldierKind(soldier.sClass) == sKind,
  [PresetTarget.ALL] = @(soldier, _guid, sKind, _squad) getSoldierKind(soldier.sClass) == sKind
}

let applyEquipmentPreset = function(presetCfg, target) {
  let checkFn = targetFilters?[target] ?? targetFilters[PresetTarget.SOLDIER]

  let { guid = null, sKind = null } = curSoldierInfo.value
  let squadId = getLinkedSquadGuid(curSoldierInfo.value)
  let usedItems = {}
  foreach (soldier in curCampSoldiers.value) {
    if (checkFn(soldier, guid, sKind, squadId))
      applyEquipmentToSoldier(presetCfg, soldier, usedItems, notFoundItems)
  }
}

let saveEquipmentPreset = function(presetCfg) {
  return presetCfg?.fnSave(curSoldierInfo.value, campItemsByLink.value) ?? false
}

let renameEquipmentPreset = function(presetCfg, newName) {
  return presetCfg?.fnRename(curSoldierInfo.value, newName) ?? false
}

console_register_command(function(slot) {
    if (curSoldierInfo.value == null)
      log("Soldier not selected")
    saveEquipmentPreset(presetEquipList.value?[slot])
  }, "meta.saveEquipPreset")

console_register_command(function(slot, target) {
    applyEquipmentPreset(presetEquipList.value?[slot], target)
  },
  "meta.applyEquipPreset")

console_register_command(resetEquipmentPreset, "meta.resetEquipPreset")

return {
  applyEquipmentPreset
  saveEquipmentPreset
  renameEquipmentPreset
  PresetTarget
  presetEquipList
  notFoundPresetItems = notFoundItems
  getItemSlotsWithPreset
  shopItemByTemplateData
  PreviewState
}
