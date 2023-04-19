from "%enlSqGlob/ui_library.nut" import *

let {
  defTxtColor, commonBorderRadius, leftAppearanceAnim, disabledBgColor, smallPadding,
  defLockedSlotBgColor, columnGap
} = require("%enlSqGlob/ui/designConst.nut")
let mkItemWithModuls = require("mkItemWithModuls.nut")
let soldierSlotsCount = require("model/soldierSlotsCount.nut")
let mkSpinner = require("%ui/components/mkSpinner.nut")

let { Bordered } = require("%ui/components/txtButton.nut")
let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { slotTypeToEquipGroup } = require("model/config/equipGroups.nut")
let { campItemsByLink } = require("%enlist/meta/profile.nut")
let { curArmy, objInfoByGuid, squadsByArmy } = require("model/state.nut")
let { getLinkedArmyName, getLinkedSquadGuid } = require("%enlSqGlob/ui/metalink.nut")
let { classSlotLocksByArmy } = require("%enlist/researches/researchesSummary.nut")
let { curUnseenAvailableUpgrades, isUpgradeUsed } = require("model/unseenUpgrades.nut")
let { unseenSoldiersWeaponry } = require("model/unseenWeaponry.nut")
let { getItemName, getErrorSlots } = require("%enlSqGlob/ui/itemsInfo.nut")
let { mkLockedBlock } = require("components/itemSlotComp.nut")
let { isItemActionInProgress } = require("model/itemActions.nut")
let { openSelectItem, mkNewItemAlerts } = require("model/selectItemState.nut")
let { equipSlotRows, slotOffset, miniOffset } = require("model/config/equipSlots.nut")
let { getItemSlotsWithPreset } = require("%enlist/preset/presetEquipUtils.nut")
let { mkPresetEquipBlock, previewPreset } = require("%enlist/preset/presetEquipUi.nut")
let { unblinkUnseen } = require("%ui/components/unseenComponents.nut")

let defTxtStyle = { color = defTxtColor }.__update(fontSmall)

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

let function mkFakeSlot(slotSize, isDisabled = false) {
  let fillColor = isDisabled ? disabledBgColor : defLockedSlotBgColor
  return {
    size = slotSize
    rendObj = ROBJ_BOX
    fillColor
    borderRadius = commonBorderRadius
    children = mkLockedBlock(fillColor)
  }
}

let mkParatrooperSlot = @(slotSize, headerText) {
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
    {
      size = slotSize
      rendObj = ROBJ_BOX
      fillColor = 0x40052060
      borderRadius = commonBorderRadius

      children = {
        rendObj = ROBJ_TEXT
        text = loc("slot/equipInBattle")
        margin = smallPadding
        color = defTxtColor
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_LEFT
        opacity = 0.5
      }.__update(defTxtStyle)
    }
  ]
}


let unseenSign = unblinkUnseen.__merge({ hplace = ALIGN_LEFT })

let function mkSlot(rowIdx, slotData, guid, hasNew) {
  let { slotSize, slotCtor = null, scheme = null } = slotData
  let key = $"slot_{guid}_{rowIdx}"

  if (slotData?.isParatrooperSlot)
    return mkParatrooperSlot(slotSize, loc(slotData.headerLocId))
      .__update({ key }, leftAppearanceAnim(0.05 * rowIdx))
  if (scheme == null)
    return mkFakeSlot(slotSize, true).__update({ key }, leftAppearanceAnim(0.05 * rowIdx))
  if (slotCtor == null)
    return mkFakeSlot(slotSize).__update({ key }, leftAppearanceAnim(0.05 * rowIdx))

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
      {
        children = [
          slotCtor(slotData)
          hasNew ? unseenSign : null
        ]
      }
    ]
  }.__update(leftAppearanceAnim(0.05 * rowIdx))
}


let function mkSlotsList(slotData, soldier, canManage, slotsCount,
  slotCtor, objectsByGuid, itemsByLink, previewPresetVal) {
  let { slotType, slotSize, slotImg, itemSize = null, hasName = false,
    hasTypeIcon = false, headerLocId = "" } = slotData

  let soldierGuid = soldier.guid
  let { equipScheme = {} } = soldier
  let slotsItems = getItemSlotsWithPreset(soldier,
    itemsByLink, previewPresetVal)
  let errorSlotTypes = getErrorSlots(slotsItems, equipScheme)

  let availableType = slotType in equipScheme
    ? slotType
    : equipScheme.findindex(@(v) v?.ingameWeaponSlot == slotType)

  let curSlotsCount = slotsCount?[availableType] ?? 0
  let scheme = equipScheme?[availableType]
  let { isDisabled = false } = scheme
  let hasWarning = errorSlotTypes?[availableType] ?? false

  local isParatrooperSlot = false
  if (slotType == "secondary"){
    let squadGuid = getLinkedSquadGuid(soldier)
    let soldierSquad = squadsByArmy.value?[curArmy.value].findvalue(@(v) v.guid == squadGuid)
    isParatrooperSlot = soldierSquad?.isParatroopers ?? false
  }

  let slotsList = collectSlots(availableType, curSlotsCount, slotsItems, soldierGuid)
  slotsList.each(@(s) s.__update({
    scheme, isDisabled, hasWarning, canManage, soldierGuid,
    slotSize, slotCtor, hasName, hasTypeIcon, headerLocId, slotImg, isParatrooperSlot
    itemSize = itemSize ?? slotSize
    item = objectsByGuid?[s.item?.guid] ?? s.item
    isUnseen = Computed(function() {
      let hasUnseenUpgradesMark = s?.item.basetpl in curUnseenAvailableUpgrades.value
        && !(isUpgradeUsed.value ?? false)
      return hasUnseenUpgradesMark
        || (unseenSoldiersWeaponry.value?[soldierGuid][availableType] ?? false)
    })
  }))
  return slotsList
}


let function mkChapter(rowIdx, slotData, soldier, canManage, slotsCount,
  slotCtor, alertsBySlot
) {
  let { slotType } = slotData
  if (slotType not in slotTypeToEquipGroup)
    return null

  let { guid } = soldier
  return function() {
    let slotsList = mkSlotsList(slotData, soldier, canManage, slotsCount, slotCtor,
      objInfoByGuid.value, campItemsByLink.value, previewPreset.value)
    return {
      watch = [objInfoByGuid, campItemsByLink, previewPreset]
      valign = ALIGN_BOTTOM
      children = slotsList.map(function(s) {
        let hasNew = alertsBySlot?[s.slotType] ?? false
        return mkSlot(rowIdx, s, guid, hasNew)
      })
    }
  }
}


let function mkUnitedChapter(rowIdx, slotData, soldier, canManage, slotsCount,
  slotCtor, alertsBySlot
) {
  let { guid } = soldier
  let { slotSize, unitedSlots = [], rowsAmount = 1, minSlotsAmount = 0 } = slotData

  return function() {
    let slotsList = []
    foreach (sData in unitedSlots)
      slotsList.extend(
        mkSlotsList(sData, soldier, canManage, slotsCount, slotCtor,
          objInfoByGuid.value, campItemsByLink.value, previewPreset.value)
      )
    slotsList.resize(max(slotsList.len(), minSlotsAmount - slotsList.len()), { slotSize })

    return {
      watch = [objInfoByGuid, campItemsByLink, previewPreset]
      size = flex()
      children = slotsList.map(function(s, idx) {
        let [ xSize, ySize ] = slotSize
        let col = idx / rowsAmount
        let row = idx % rowsAmount
        let pos = [xSize * col + slotOffset * col, ySize * row + miniOffset * row]
        let hasNew = alertsBySlot?[s.slotType] ?? false
        return mkSlot(rowIdx, s, guid, hasNew).__update({ pos })
      })
    }
  }
}


let mkEquipRow = @(equipRow, rowIdx, soldier, canManage, slotsCount, slotCtor, alertsBySlot) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = slotOffset
  valign = ALIGN_BOTTOM
  children = equipRow.map(@(slotData) "slotType" in slotData
    ? mkChapter(rowIdx, slotData, soldier, canManage, slotsCount, slotCtor, alertsBySlot)
    : mkUnitedChapter(rowIdx, slotData, soldier, canManage, slotsCount, slotCtor, alertsBySlot)
  )
}

let mkEquipPresetBtn = @() {
  watch = isItemActionInProgress
  size = [flex(), SIZE_TO_CONTENT]
  children = isItemActionInProgress.value
    ? mkSpinner()
    : {
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      children = Bordered(loc("preset/equip/open"), mkPresetEquipBlock, {
        btnWidth = flex()
      })
    }
}

let function soldierEquipUi(soldier, canManage = true, selectedKey = Watched(null),
  onDoubleClickCb = null, onResearchClickCb = null, dropExceptionCb = null,
  isPresetHidden = false
) {
  let newItemAlerts = mkNewItemAlerts(soldier)
  return function() {
    let { guid, equipScheme = {} } = soldier.value
    let slotsCountWatch = soldierSlotsCount(guid, equipScheme,
      previewPreset.value?.slotsIncrease)
    let slotCtor = @(p) mkItem(p.__merge({
      selectedKey
      onDoubleClickCb
      onResearchClickCb
      onDropExceptionCb = dropExceptionCb
    }))
    let alertsBySlot = newItemAlerts.value
    return {
      watch = [soldier, previewPreset, newItemAlerts]
      size = flex()
      flow = FLOW_VERTICAL
      gap = columnGap
      children = [
        isPresetHidden ? null : mkEquipPresetBtn
        function() {
          let slotsCount = slotsCountWatch.value
          return {
            watch = slotsCountWatch
            size = flex()
            flow = FLOW_VERTICAL
            gap = miniOffset
            children =  equipSlotRows.map(@(equipRow, rowIdx) mkEquipRow(equipRow, rowIdx,
              soldier.value, canManage, slotsCount, slotCtor, alertsBySlot))
          }
        }
      ]
    }
  }
}


return kwarg(soldierEquipUi)
