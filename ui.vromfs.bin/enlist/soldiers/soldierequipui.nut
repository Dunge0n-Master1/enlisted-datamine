from "%enlSqGlob/ui_library.nut" import *

let { defTxtColor, commonBorderRadius, lockedItemIdleBgColor, leftAppearanceAnim
} = require("%enlSqGlob/ui/designConst.nut")
let mkItemWithModuls = require("mkItemWithModuls.nut")
let soldierSlotsCount = require("model/soldierSlotsCount.nut")
let mkSpinner = require("%ui/components/mkSpinner.nut")

let { Bordered } = require("%ui/components/txtButton.nut")
let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { slotTypeToEquipGroup } = require("model/config/equipGroups.nut")
let { campItemsByLink } = require("%enlist/meta/profile.nut")
let { curArmy, objInfoByGuid, getSoldierItemSlots } = require("model/state.nut")
let { getLinkedArmyName, getLinkedSquadGuid } = require("%enlSqGlob/ui/metalink.nut")
let { classSlotLocksByArmy } = require("%enlist/researches/researchesSummary.nut")
let { curUnseenAvailableUpgrades, isUpgradeUsed } = require("model/unseenUpgrades.nut")
let { unseenSoldiersWeaponry } = require("model/unseenWeaponry.nut")
let { reserveSoldiers } = require("model/chooseSoldiersState.nut")
let { getItemName, getErrorSlots } = require("%enlSqGlob/ui/itemsInfo.nut")
let { mkLockedBlock } = require("components/itemSlotComp.nut")
let { equipByList, isItemActionInProgress } = require("model/itemActions.nut")
let {
  openSelectItem, getPossibleUnequipList, getAlternativeEquipList, getWorseItem,
  getPossibleEquipList, getBetterItem
} = require("model/selectItemState.nut")
let { equipSlotRows, slotOffset, miniOffset } = require("model/config/equipSlots.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
local animIdx = 0

let function collectSlots(slotType, totalSlots, slotsItems, sGuid) {
  let soldierData = objInfoByGuid.value?[sGuid]
  local isAvailable = true
  if (soldierData && slotType) {
    let armyId = getLinkedArmyName(soldierData)
    let sClass = soldierData?.sClass ?? "unknown"
    isAvailable = (classSlotLocksByArmy.value?[armyId][sClass] ?? []).indexof(slotType) == null
  }

  let emptySlot = { item = null, slotType = slotType, slotId = -1, isLocked = !isAvailable }
  let slots = slotsItems.filter(@(s) s.slotType == slotType)
    .map(@(s) emptySlot.__merge(s))
  if (totalSlots <= 0)
    return slots.len() > 0 ? slots : [emptySlot]

  let slotsMap = {}
  slots.each(@(s) slotsMap[s.slotId] <- s)
  return array(totalSlots).map(@(_, slotId) slotId < totalSlots
    ? slotsMap?[slotId] ?? emptySlot.__merge({ slotId = slotId })
    : emptySlot.__merge({ slotId = slotId, isLocked = true }))
}


let mkItem = @(slotData) mkItemWithModuls(slotData.__merge({
  onClickCb = @(p) openSelectItem({
    armyId = curArmy.value
    ownerGuid = p?.soldierGuid
    slotType = p?.slotType
    slotId = p?.slotId
  })
}))


let mkFakeSlot = @(slotSize) {
  size = slotSize
  rendObj = ROBJ_BOX
  fillColor = lockedItemIdleBgColor
  borderRadius = commonBorderRadius
  children = mkLockedBlock(lockedItemIdleBgColor)
}


let function mkSlot(slotData, guid) {
  animIdx++
  let { slotSize, slotCtor = null } = slotData
  let key = $"slot_{guid}_{animIdx}"
  if (slotCtor == null)
    return mkFakeSlot(slotSize).__update({ key }, leftAppearanceAnim(0.07 * animIdx))

  let { item, hasName, headerLocId } = slotData
  let headerText = item != null && hasName ? getItemName(item)
    : headerLocId != "" ? loc(headerLocId)
    : ""

  return {
    key
    flow = FLOW_VERTICAL
    children = [
      headerText == "" ? null
        : {
            size = [flex(), SIZE_TO_CONTENT]
            children = {
              rendObj = ROBJ_TEXT
              text = headerText
            }.__update(defTxtStyle)
          }
      slotCtor(slotData)
    ]
  }.__update(leftAppearanceAnim(0.07 * animIdx))
}


let function mkSlotsList(slotData, soldier, canManage, slotsCount, slotCtor) {
  let { slotType, slotSize, slotImg, itemSize = null, hasName = false,
    hasTypeIcon = false, headerLocId = "" } = slotData

  let soldierGuid = soldier.guid
  let { equipScheme = {} } = soldier
  let slotsItems = getSoldierItemSlots(soldierGuid, campItemsByLink.value)
  let errorSlotTypes = getErrorSlots(slotsItems, equipScheme)

  let curSlotsCount = slotsCount?[slotType] ?? 0
  let scheme = equipScheme?[slotType]
  let { isDisabled = false } = scheme
  let hasWarning = errorSlotTypes?[slotType] ?? false

  let slotsList = collectSlots(slotType, curSlotsCount, slotsItems, soldierGuid)
  slotsList.each(@(s) s.__update({
    scheme, isDisabled, hasWarning, canManage, soldierGuid,
    slotSize, slotCtor, hasName, hasTypeIcon, headerLocId, slotImg,
    itemSize = itemSize ?? slotSize
    item = objInfoByGuid.value?[s.item?.guid]
    isUnseen = Computed(function() {
      let hasUnseenUpgradesMark = s?.item.basetpl in curUnseenAvailableUpgrades.value
        && !(isUpgradeUsed.value ?? false)
      return hasUnseenUpgradesMark
        || (unseenSoldiersWeaponry.value?[soldierGuid][slotType] ?? false)
    })
  }))
  return slotsList
}


let function mkChapter(slotData, soldier, canManage, slotsCount, slotCtor) {
  let { slotType } = slotData
  if (slotType not in slotTypeToEquipGroup)
    return null

  let { guid } = soldier
  let slotsList = mkSlotsList(slotData, soldier, canManage, slotsCount, slotCtor)
  return {
    watch = [objInfoByGuid, campItemsByLink]
    valign = ALIGN_BOTTOM
    children = slotsList.map(@(s) mkSlot(s, guid))
  }
}


let function mkUnitedChapter(slotData, soldier, canManage, slotsCount, slotCtor) {
  let { slotSize, unitedSlots = [], rowsAmount = 1, minSlotsAmount = 0 } = slotData
  let slotsList = []
  foreach (sData in unitedSlots)
    slotsList.extend(
      mkSlotsList(sData, soldier, canManage, slotsCount, slotCtor)
    )
  while (slotsList.len() < minSlotsAmount)
    slotsList.append({ slotSize })

  let { guid } = soldier
  return {
    watch = [objInfoByGuid, campItemsByLink]
    size = flex()
    children = slotsList.map(function(s, idx) {
      let [ xSize, ySize ] = slotSize
      let col = idx / rowsAmount
      let row = idx % rowsAmount
      let pos = [xSize * col + slotOffset * col, ySize * row + miniOffset * row]
      return mkSlot(s, guid).__update({ pos })
    })
  }
}


let mkEquipRow = @(equipRow, soldier, canManage, slotsCount, slotCtor) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = slotOffset
  valign = ALIGN_BOTTOM
  children = equipRow.map(@(slotData) "slotType" in slotData
    ? mkChapter(slotData, soldier, canManage, slotsCount, slotCtor)
    : mkUnitedChapter(slotData, soldier, canManage, slotsCount, slotCtor)
  )
}


let mkEquipBtn = @(soldier, reserveWatch)
  function() {
    let res = {
      watch = [isItemActionInProgress, reserveWatch]
    }
    let { guid } = soldier
    let isInReserve = reserveWatch.value.findindex(@(s) s.guid == guid) != null
    local changeEquipList = []
    local btnTextLocId = ""
    if (isInReserve) {
      btnTextLocId = "removeAllEquipment"
      let toRemoveList = getPossibleUnequipList(guid)
      changeEquipList = getAlternativeEquipList(soldier, getWorseItem, toRemoveList)
        .extend(toRemoveList)
    }
    else if (getLinkedSquadGuid(soldier) != null) {
      btnTextLocId = "autoEquip"
      let toAddList = getPossibleEquipList(soldier)
      changeEquipList = getAlternativeEquipList(soldier, getBetterItem).extend(toAddList)
    }

    if (changeEquipList.len() == 0)
      return res

    return res.__update({
      size = [flex(), SIZE_TO_CONTENT]
      children = isItemActionInProgress.value
        ? mkSpinner()
        : Bordered(loc(btnTextLocId),
            @() equipByList(guid, changeEquipList), { btnWidth = flex() })
    })
  }


let soldierEquipUi = @( soldier, canManage = true, selectedKey = Watched(null),
  onDoubleClickCb = null, onResearchClickCb = null, dropExceptionCb = null
) function() {
    let { guid, equipScheme = {} } = soldier.value
    let slotsCountWatch = soldierSlotsCount(guid, equipScheme)
    let slotCtor = @(p) mkItem(p.__merge({
      selectedKey
      onDoubleClickCb
      onResearchClickCb
      onDropExceptionCb = dropExceptionCb
    }))
    animIdx = 0

    return {
      watch = soldier
      size = flex()
      flow = FLOW_VERTICAL
      gap = { size = flex() }
      children = [
        function() {
          let slotsCount = slotsCountWatch.value
          return {
            watch = slotsCountWatch
            size = flex()
            flow = FLOW_VERTICAL
            gap = miniOffset
            children = equipSlotRows.map(@(equipRow)
              mkEquipRow(equipRow, soldier.value, canManage, slotsCount, slotCtor)
            )
          }
        }
        mkEquipBtn(soldier.value, reserveSoldiers)
      ]
    }
}


return kwarg(soldierEquipUi)
