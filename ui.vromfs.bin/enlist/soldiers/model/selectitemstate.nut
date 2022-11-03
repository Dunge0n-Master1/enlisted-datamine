from "%enlSqGlob/ui_library.nut" import *

let { equipGroups } = require("config/equipGroups.nut")
let { curCampSoldiers, getEquippedItemGuid, objInfoByGuid, armoryByArmy,
  getScheme, getItemOwnerSoldier, curCampItems, getSoldierItemSlots, getDemandingSlots,
  armies, curArmy, allAvailableArmies
} = require("%enlist/soldiers/model/state.nut")
let { campItemsByLink, soldiersByArmies } = require("%enlist/meta/profile.nut")
let { equipItem } = require("%enlist/soldiers/model/itemActions.nut")
let { classSlotLocksByArmy } = require("%enlist/researches/researchesSummary.nut")
let { allItemTemplates, findItemTemplate
} = require("%enlist/soldiers/model/all_items_templates.nut")
let { prepareItems, addShopItems, itemsSort } = require("%enlist/soldiers/model/items_list_lib.nut")
let { itemTypesInSlots } = require("all_items_templates.nut")
let { soldierClasses } = require("%enlSqGlob/ui/soldierClasses.nut")
let soldierSlotsCount = require("soldierSlotsCount.nut")
let { logerr } = require("dagor.debug")
let { getLinkedArmyName, isObjLinkedToAnyOfObjects
} = require("%enlSqGlob/ui/metalink.nut")
let { getObjectName, trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { curSection } = require("%enlist/mainMenu/sectionsState.nut")
let { unseenTiers } = require("unseenWeaponry.nut")
let { transfer_item } = require("%enlist/meta/clientApi.nut")
let { lockedProgressCampaigns } = require("%enlist/meta/campaigns.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { room, roomIsLobby } = require("%enlist/state/roomState.nut")
let { isObjGuidBelongToRentedSquad } = require("squadInfoState.nut")
let { showRentedSquadLimitsBox } = require("%enlist/soldiers/components/squadsComps.nut")


let selectParamsList = mkWatched(persist, "selectParamsList", [])
let selectParams = Computed(@()
  selectParamsList.value.len() ? selectParamsList.value.top() : null)

let curEquippedItem = Computed(function() {
  let { ownerGuid = null, slotType = null, slotId = null } = selectParams.value
  if (ownerGuid == null || slotType == null)
    return null
  let guid = getEquippedItemGuid(campItemsByLink.value, ownerGuid, slotType, slotId)
  return objInfoByGuid.value?[guid]
})

let curInventoryItem = Watched(null)
curCampItems.subscribe(@(_) curInventoryItem(null))

let viewItem = Computed(@() curInventoryItem.value ?? curEquippedItem.value) // last selected or current item

let function calcItems(params, objInfoByGuidV, armoryByArmyV, curItemV) {
  if (curItemV?.isFixed ?? false)
    return []

  let { armyId = null, filterFunc = @(_tplId, _tpl) true } = params
  if (!armyId)
    return []

  let itemsList = prepareItems((armoryByArmyV?[armyId] ?? [])
    .filter(@(item)
      item && filterFunc(item.basetpl, findItemTemplate(allItemTemplates, armyId, item.basetpl))),
      objInfoByGuidV)
  addShopItems(itemsList, armyId, @(tplId, tpl)
    filterFunc(tplId, tpl) && (tpl?.upgradeIdx ?? 0) == 0)
  itemsList.sort(itemsSort)
  return itemsList
}

let function calcOther(params, armoryByArmyV, itemTypesInSlotsV, curItemV) {
  if (curItemV?.isFixed ?? false)
    return []

  let { slotType = null, armyId = null, filterFunc = @(_tplId, _tpl) true } = params
  if (!armyId)
    return []

  let allTypes = itemTypesInSlotsV?[slotType]
  local otherList = (armoryByArmyV?[armyId] ?? [])
    .filter(@(item) item
      && !filterFunc(item.basetpl, findItemTemplate(allItemTemplates, armyId, item.basetpl))
      && allTypes?[item?.itemtype])

  otherList = prepareItems(otherList, objInfoByGuid.value)
  addShopItems(otherList, armyId, @(tplId, tpl)
    (allTypes?[tpl.itemtype] ?? false) && !filterFunc(tplId, tpl) && (tpl?.upgradeIdx ?? 0) == 0)
  otherList.sort(itemsSort)
  return otherList
}

let slotItems = Computed(@()
  calcItems(selectParams.value, objInfoByGuid.value, armoryByArmy.value, viewItem.value))

let inventoryItems = Computed(function() {
  let res = {}
  foreach (item in slotItems.value)
    if (!(item?.isShopItem ?? false))
      res[item.basetpl] <- item
  return res
})

let otherSlotItems = Computed(@()
  calcOther(selectParams.value, armoryByArmy.value, itemTypesInSlots.value, viewItem.value))

let mkDefaultFilterFunc = function(showItemTypes = [], showItems = []) {
  let isFilterTypes = (showItemTypes?.len() ?? 0) != 0
  return (showItems?.len() ?? 0) != 0
    ? (isFilterTypes
      ? @(tmpl, item) showItems.indexof(trimUpgradeSuffix(tmpl)) != null
          || showItemTypes.indexof(item?.itemtype) != null
      : @(tmpl, _) showItems.indexof(trimUpgradeSuffix(tmpl)) != null)
    : (isFilterTypes
      ? @(_, item) showItemTypes.indexof(item?.itemtype) != null
      : @(_0, _1) true)
}

let paramsForPrevItems = Computed(function() {
  let { soldierGuid = null, ownerGuid = null, armyId = null } = selectParams.value
  if (soldierGuid != null)
    return null

  let ownerItem = objInfoByGuid.value?[ownerGuid]
  if (ownerItem == null)
    return null

  return {
    armyId = armyId
    ownerGuid = ownerGuid
    soldierGuid = soldierGuid
    filterFunc = mkDefaultFilterFunc([ownerItem?.itemtype])
    ownerName = getObjectName(ownerItem)
  }
})

let prevItems = Computed(@()
  calcItems(paramsForPrevItems.value, objInfoByGuid.value, armoryByArmy.value, viewItem.value)
    .filter(@(item) "guid" in item))

let viewSoldierInfo = Computed(@()
  objInfoByGuid.value?[selectParams.value?.soldierGuid])

let function openSelectItem(armyId, ownerGuid, slotType, slotId) {
  if (ownerGuid == null)
    return
  let ownerItem = objInfoByGuid.value?[ownerGuid]
  if (!ownerItem) {
    logerr($"Not found item info to select item {ownerGuid}")
    return
  }
  let scheme = getScheme(ownerItem, slotType)
  if (!scheme) {
    logerr($"Not found scheme for item {ownerGuid} slotType {slotType}")
    return
  }

  let soldierGuid = ownerGuid in curCampSoldiers.value
    ? ownerGuid
    : getItemOwnerSoldier(ownerGuid)?.guid

  let params = {
    armyId
    ownerGuid
    soldierGuid
    slotType
    slotId
    scheme
    filterFunc = mkDefaultFilterFunc(scheme?.itemTypes, scheme?.items)
    ownerName = getObjectName(ownerItem)
  }
  selectParamsList.mutate(function(l) {
    let idx = l.findindex(@(p) p?.soldierGuid == soldierGuid)
    if (idx != null)
      l.resize(idx)
    l.append(params)
  })
  curInventoryItem(null) // clear current selected inventory item on slot item selection
}

let function selectInsideListSlot(dir, doWrap) {
  local { armyId, ownerGuid, slotType, slotId } = selectParams.value
  let curScheme = viewSoldierInfo.value?.equipScheme ?? {}
  let size = soldierSlotsCount(ownerGuid, curScheme).value?[slotType] ?? 0

  if (size <= 1)
    return false
  slotId = slotId + dir
  if (doWrap)
    slotId = (slotId + size) % size
  else if (slotId < 0 || slotId >= size)
    return false

  openSelectItem(armyId, ownerGuid, slotType, slotId)
  return true
}

let function selectSlot(dir) {
  let params = selectParams.value
  if (params == null || selectInsideListSlot(dir, false))
    return

  local { slotType } = params
  let { equipScheme = {} } = viewSoldierInfo.value

  let availableSlotTypes = equipGroups
    .map(@(g) g.slots.filter(@(s) (s in equipScheme) && !equipScheme[s]?.isDisabled))
    .map(@(v) v.sort(@(a, b) (equipScheme[a]?.uiOrder ?? 0) <=> (equipScheme[b]?.uiOrder ?? 0)))
    .reduce(@(a, val) a.extend(val), [])

  local slotIdx = availableSlotTypes.indexof(slotType)
  if (slotIdx == null)
    return

  slotIdx += dir
  if (slotIdx < 0 || slotIdx >= availableSlotTypes.len())
    return

  slotType = availableSlotTypes[slotIdx]
  let subslotsCount = soldierSlotsCount(viewSoldierInfo.value?.guid, equipScheme).value?[slotType] ?? 0
  let slotId = subslotsCount < 1 ? -1
    : dir < 0 ? subslotsCount - 1
    : 0

  let { armyId, ownerGuid } = params
  openSelectItem(armyId, ownerGuid, slotType, slotId)
}

let function itemClear() {
  if (selectParamsList.value.len() > 0)
    selectParamsList.mutate(@(l) l.remove(l.len() - 1))
  if (selectParams.value == null)
    curInventoryItem(null) // clear current item on exit
}

curSection.subscribe(@(_) itemClear())

enum ItemCheckResult {
  NEED_RESEARCH = 0
  WRONG_CLASS = 1
  NEED_LEVEL = 2
  IN_SHOP = 3
}

let function checkSelectItem(item) {
  let { basetpl = null, itemtype = null, isShopItem = false, unlocklevel = 0 } = item
  let soldier = viewSoldierInfo.value
  if (basetpl == null || soldier == null)
    return null

  let trimmed = trimUpgradeSuffix(basetpl)

  let armyId = getLinkedArmyName(soldier)
  let armyLevel = armies.value?[armyId].level ?? 0

  let { sClass = "unknown", equipScheme = {} } = soldier
  let sClassLoc = loc(soldierClasses?[sClass].locId ?? "unknown")

  let { slotType = null,scheme = {} } = selectParams.value
  let slotsLocked = classSlotLocksByArmy.value?[armyId][sClass] ?? []
  if (slotsLocked.indexof(slotType) != null)
    return {
      result = ItemCheckResult.NEED_RESEARCH
      soldierClass = sClassLoc
      soldier
      slotType
    }

  let itemTypes = equipScheme?[slotType].itemTypes ?? []
  let itemList = scheme?.items ?? []
  if ((itemTypes.len() != 0 || itemList.len() != 0)
    && itemTypes.indexof(itemtype) == null
    && itemList.indexof(trimmed) == null)
    return {
      result = ItemCheckResult.WRONG_CLASS
      soldierClass = sClassLoc
    }

  if (isShopItem){
    if (unlocklevel > 0 && unlocklevel > armyLevel)
      return {
        result = ItemCheckResult.NEED_LEVEL
        level = unlocklevel
      }

    return {
      result = ItemCheckResult.IN_SHOP
    }
  }

  return null
}

let function selectItem(item) {
  let { slotType = null, slotId = null, ownerGuid = null } = selectParams.value
  if (ownerGuid != null && isObjGuidBelongToRentedSquad(ownerGuid)) {
    showRentedSquadLimitsBox()
    return
  }

  equipItem(item?.guid, slotType, slotId, ownerGuid)
}

let unseenViewSlotTpls = Computed(function() {
  let { armyId = null } = selectParams.value
  let allUnseen = unseenTiers.value?[armyId].byTpl
  if (allUnseen == null)
    return {}

  let { tier = -1 } = curEquippedItem.value
  return allUnseen.filter(@(tplTier) tplTier > tier)
})

let function getModifyItemGuid(stackedItem, canBeLinked = false) {
  let profileItems = curCampItems.value
  let profileSoldiers = curCampSoldiers.value
  let stackedGuids = stackedItem?.guids ?? [stackedItem?.guid]
  foreach (guid in stackedGuids) {
    let item = profileItems?[guid]
    if (item == null)
      continue

    if (canBeLinked)
      return item.guid

    if (!isObjLinkedToAnyOfObjects(item, profileSoldiers ?? {}) &&
        !isObjLinkedToAnyOfObjects(item, profileItems ?? {}))
      return item.guid
  }
  return null
}

let unwantedTypes = { boltaction_noscope = true }

let function getBetterItem(item1, item2) {
  let isUnwanted1 = item1?.itemtype in unwantedTypes
  let isUnwanted2 = item2?.itemtype in unwantedTypes
  return item2 != null && (isUnwanted2 < isUnwanted1
    || (isUnwanted2 == isUnwanted1 && (item2?.tier ?? 0) > (item1?.tier ?? 0))) ? item2 : item1
}

let getWorseItem = @(item1, item2) item1 == null
  || (item1?.tier ?? 0) <= (item2?.tier ?? 0) ? item1 : item2

let function getAlternativeEquipList(soldier, chooseFunc, excludeSlots = []) {
  let armyId = getLinkedArmyName(soldier)
  let slotsItems = getSoldierItemSlots(soldier.guid, campItemsByLink.value)
    .filter(@(i) !(excludeSlots.findindex(@(v) v.slotType == i.slotType) != null
      && excludeSlots.findindex(@(v) v.slotId == i.slotId) != null))

  let equipList = []
  foreach (slotsItem in slotsItems) {
    let { slotType, slotId } = slotsItem
    let { itemTypes = [], items = [] } = getScheme(soldier, slotType)
    let filterCb = mkDefaultFilterFunc(itemTypes, items)
    local choosenItem = slotsItem?.item
    foreach (item in armoryByArmy.value?[armyId] ?? [])
      if (filterCb(item.basetpl, findItemTemplate(allItemTemplates, armyId, item.basetpl)))
        choosenItem = chooseFunc(choosenItem, item)

    if (choosenItem != null && choosenItem?.guid != slotsItem?.item.guid)
      equipList.append({
        slotType, slotId, guid = choosenItem.guid
      })
  }
  return equipList
}

let curCanUnequipSoldiersList = Computed(function() {
  let res = {}
  let itemsByLink = campItemsByLink.value
  let infoByGuid = objInfoByGuid.value
  let soldiers = soldiersByArmies.value?[curArmy.value] ?? {}
  foreach (guid, _ in soldiers) {
    let slotsItems = getSoldierItemSlots(guid, itemsByLink)
    foreach (slotsItem in slotsItems) {
      let { slotType } = slotsItem
      let demands = getDemandingSlots(guid, slotType, infoByGuid?[guid], itemsByLink)
      if (demands.len() == 0 || demands.filter(@(i) i != null).len() > 1) {
        res[guid] <- true
        break
      }
    }
  }
  return res
})

let defaultSortOrder = {
  explosion_pack = 6
  impact_grenade = 5
  incendiary_grenade = 4
  grenade = 3
  molotov = 2
  antipersonnel_mine = 2
  antitank_mine = 1
  smoke_grenade = 1
  medkits = 1
}
let classSortOrder = {
  tanker = { repair_kit = 2 }
  sniper = { smoke_grenade = 5 }
  assault = { assault_rifle_stl = 4, assault_rifle = 3, submgun = 2, shotgun = 1 }
}

let AUTO_SLOTS = [
  "grenade", "medkits", "mine", "binoculars_usable", "flask_usable"
]

let function cleanByValues(src, val) {
  foreach (key in src.keys())
    if (src[key] == val)
      delete src[key]
}

let function getEmptyNeededSlots(slotsItems, equipScheme) {
  let slotToGroup = {}
  foreach (slotType, slot in equipScheme) {
    let { atLeastOne = "" } = slot
    if (atLeastOne != "")
      slotToGroup[slotType] <- atLeastOne
  }
  foreach (item in slotsItems)
    if (item.slotType in slotToGroup)
      cleanByValues(slotToGroup, slotToGroup[item.slotType])
  return slotToGroup
}

let function getPossibleEquipList(soldier) {
  let { guid = null, equipScheme = {} } = soldier
  let slotsItems = getSoldierItemSlots(guid, campItemsByLink.value)
  let reqItemTypes = AUTO_SLOTS.filter(@(iType) slotsItems.findindex(@(slot)
    slot.item?.itemtype == iType) == null)
  let emptySlotsTypes = getEmptyNeededSlots(slotsItems, equipScheme)

  let equipList = []
  if (reqItemTypes.len() == 0 && emptySlotsTypes.len() == 0)
    return equipList

  let freeSlots = {}
  foreach (slotType, count in soldierSlotsCount(guid, equipScheme).value) {
    freeSlots[slotType] <- {}
    for (local i = 0; i < count; i++)
      freeSlots[slotType][i] <- slotsItems
        .findindex(@(s) s.slotType == slotType && s.slotId == i) == null
  }

  let sortOrder = defaultSortOrder.__merge(classSortOrder?[soldier.sClass] ?? {})
  let sortFunc = @(a, b)
    (sortOrder?[b.itemtype] ?? 0) <=> (sortOrder?[a.itemtype] ?? 0)

  let armyId = getLinkedArmyName(soldier)
  let inventory = armoryByArmy.value?[armyId] ?? []

  foreach (reqItemType in reqItemTypes) {
    let availSlotTypes = equipScheme
      .filter(@(slotData) slotData?.itemTypes.contains(reqItemType))
      .keys()
    if (availSlotTypes.len() == 0)
      continue

    local availSlot = null
    foreach (slotType in availSlotTypes) {
      let slotId = (freeSlots?[slotType] ?? {}).findindex(@(val) val)
      if (slotId != null) {
        availSlot = { slotType, slotId }
        break
      }
    }
    if (availSlot == null)
      continue

    let { itemTypes = [], items = [] } = getScheme(soldier, availSlot.slotType)
    if (itemTypes.len() == 0 && items.len() == 0)
      continue

    let filterCb = mkDefaultFilterFunc(itemTypes, items)
    let availSlotItems = inventory.filter(@(item)
        filterCb(item.basetpl, findItemTemplate(allItemTemplates, armyId, item.basetpl)))
      .sort(sortFunc)

    let choosenItem = availSlotItems.reduce(@(res, item) getBetterItem(res, item))
    if (choosenItem != null)
      equipList.append(availSlot.__update({ guid = choosenItem.guid }))
  }

  // find better weapon for empty slots
  foreach (slotType in emptySlotsTypes.keys()) {
    let { itemTypes = [], items = [] } = getScheme(soldier, slotType)
    if (itemTypes.len() == 0 && items.len() == 0)
      continue

    let filterCb = mkDefaultFilterFunc(itemTypes, items)
    let availSlotItems = inventory.filter(@(item)
        filterCb(item.basetpl, findItemTemplate(allItemTemplates, armyId, item.basetpl)))
      .sort(sortFunc)
    let newItem = availSlotItems.reduce(@(res, item) getBetterItem(res, item))
    if (newItem != null && slotType in emptySlotsTypes) {
      cleanByValues(emptySlotsTypes, emptySlotsTypes[slotType])
      equipList.append({
        slotType
        slotId = -1
        guid = newItem.guid
      })
    }
  }

  return equipList
}

let function getPossibleUnequipList(ownerGuid) {
  let itemsByLink = campItemsByLink.value
  let infoByGuid = objInfoByGuid.value
  let equipList = []
  let unequipped = {}
  let slotsItems = getSoldierItemSlots(ownerGuid, itemsByLink)
  foreach (slotsItem in slotsItems) {
    let { slotType, slotId } = slotsItem
    let listByDemands = getDemandingSlots(ownerGuid, slotType, infoByGuid?[ownerGuid], itemsByLink)
    if (listByDemands.len() > 0)
      if (listByDemands.filter(@(i) i != null && i not in unequipped).len() <= 1)
        continue

    equipList.append({
      slotType, slotId, guid = ""
    })
    unequipped[slotsItem.item.guid] <- true
  }
  return equipList
}

let viewItemMoveVariants = Computed(function() {
  let item = viewItem.value
  if (item == null
      || item.guid == ""
      || item?.isZeroHidden
      || item?.isFixed
      || (item?.sign ?? 0) != 0
      || (item?.unlocklevel ?? -1) < 0)
    return []

  let curArmyId = getLinkedArmyName(item)
  let templates = allItemTemplates.value
  let res = []
  foreach (campaign, campaignArmies in allAvailableArmies.value)
    foreach (armyId in campaignArmies) {
      let template = templates?[armyId][item.basetpl]
      if (armyId == curArmyId || template == null)
        continue

      let { unlocklevel = -1, isZeroHidden = false } = template
      if (unlocklevel < 0 || isZeroHidden)
        continue

      if (item?.equipSchemeId != template?.equipSchemeId)
        continue

      let { tier = 0 } = template
      local transferError = null
      let armyName = loc(armyId)
      let campaignName = loc(gameProfile.value?.campaigns[campaign].title ?? campaign)
      let fullArmyName = $"{armyName} ({campaignName})"
      let armyLevel = armies.value?[armyId].level ?? 0
      if (campaign in lockedProgressCampaigns.value)
        transferError = loc("msg/transferReqUnlockProgress", { fullArmyName, campaignName })
      else if (armyLevel < unlocklevel)
        transferError = loc("msg/transferReqArmyLevel", { armyInfo = fullArmyName, level = unlocklevel })

      res.append({ armyId, armyName, campaignName, fullArmyName, transferError, tier,
        isTransferAllowed = transferError == null
      })
    }
  return res
})

let closeNeeded = keepref(Computed(@() room.value != null && !roomIsLobby.value
  && !(room.value?.gameStarted ?? false)))

closeNeeded.subscribe(@(v) v ? itemClear() : null)

console_register_command(function(armyId) {
  let { guid = "" } = viewItem.value
  if (guid == "")
    return log("Item is not selected")
  transfer_item(guid, armyId)
  log("Move item request sent")
}, "meta.moveItem")

return {
  viewItem
  viewItemMoveVariants
  curInventoryItem
  curEquippedItem
  selectParams
  inventoryItems
  slotItems
  otherSlotItems //items fit to current slot, but not fit to current soldier class
  viewSoldierInfo
  paramsForPrevItems
  prevItems //when choose mod of not equipped item from items list
  unseenViewSlotTpls
  getModifyItemGuid

  openSelectItem = kwarg(openSelectItem)
  trySelectNext = @() selectInsideListSlot(1, true)
  selectNextSlot = @() selectSlot(1)
  selectPreviousSlot = @() selectSlot(-1)
  itemClear
  checkSelectItem
  selectItem
  ItemCheckResult

  curCanUnequipSoldiersList
  getPossibleEquipList
  getPossibleUnequipList
  getAlternativeEquipList
  getBetterItem
  getWorseItem
}
