from "%enlSqGlob/ui_library.nut" import *

let { sub_txt, tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let spinner = require("%ui/components/spinner.nut")
let { Flat } = require("%ui/components/textButton.nut")
let {
  smallPadding, bigPadding, soldierWndWidth, unitSize, slotBaseSize, defTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { note } = require("%enlSqGlob/ui/defcomps.nut")
let { curArmy, objInfoByGuid, squadsByArmy } = require("model/state.nut")
let { classSlotLocksByArmy } = require("%enlist/researches/researchesSummary.nut")
let { equipGroups, slotTypeToEquipGroup } = require("model/config/equipGroups.nut")
let { openSelectItem } = require("model/selectItemState.nut")
let { curUnseenAvailableUpgrades, isUpgradeUsed } = require("model/unseenUpgrades.nut")
let mkItemWithMods = require("mkItemWithMods.nut")
let soldierSlotsCount = require("model/soldierSlotsCount.nut")
let { getLinkedArmyName, getLinkedSquadGuid } = require("%enlSqGlob/ui/metalink.nut")
let { unseenSoldiersWeaponry } = require("model/unseenWeaponry.nut")
let { campItemsByLink } = require("%enlist/meta/profile.nut")
let { getErrorSlots } = require("%enlSqGlob/ui/itemsInfo.nut")
let { isItemActionInProgress } = require("model/itemActions.nut")
let { getItemSlotsWithPreset } = require("%enlist/preset/presetEquipUtils.nut")
let { mkPresetEquipBlock, previewPreset, previewHighlightColor
} = require("%enlist/preset/presetEquipUi.nut")


const opacityForDisabledItems = 0.3
const MAX_ITEMS_IN_ROW = 4
const MAX_SLOT_TYPES_IN_ROW = 3
let waitingSpinner = spinner(hdpx(25))

let function openEquipMenu(p /*onClick params from mkItem*/) {
  openSelectItem({
    armyId = curArmy.value
    ownerGuid = p?.soldierGuid
    slotType = p?.slotType
    slotId = p?.slotId
  })
}

let mkItem = function(params) {
  return {
    rendObj = ROBJ_FRAME
    borderWidth = params?.previewState == null ? null : hdpx(2)
    color = previewHighlightColor(params?.previewState)
    children = mkItemWithMods((params ?? {}).__merge({
      onClickCb = openEquipMenu
    }))
  }
}

let soldierWndInnerWidth = soldierWndWidth - 2 * bigPadding

let function collectSlots(slotType, totalSlots, slotsItems, soldierGuid) {
  let soldierData = objInfoByGuid.value?[soldierGuid]
  local isAvailable = true
  if (soldierData && slotType) {
    let armyId = getLinkedArmyName(soldierData)
    let { sClass = "unknown" } = soldierData
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

let mkItemsBlock = kwarg(function(
  soldierGuid, canManage, slots = [], itemCtor = mkItem, numInRow = MAX_ITEMS_IN_ROW,
  gap = smallPadding
) {
  let itemsNum = min(slots.len(), numInRow)
  if (itemsNum == 0)
    return null

  let itemWidth = (soldierWndInnerWidth - gap * (itemsNum - 1)) / itemsNum
  let itemSize = [itemWidth, min(itemWidth, unitSize * 2)]
  return wrap(
    slots.map(@(slot) itemCtor(
      slot.__merge({
        soldierGuid = soldierGuid
        itemSize = itemSize
        isInteractive = canManage
        hasUnseenSign = slot.isUnseen
        hasWarningSign = slot.hasWarning
        canDrag = true
      }))),
    { width = soldierWndInnerWidth, hGap = gap, vGap = gap, hplace = ALIGN_CENTER }
  )
})

let dropCrateSlotCtor = @(_){
  rendObj = ROBJ_SOLID
  color = 0x40052060
  size = [soldierWndWidth - bigPadding * 2, unitSize * 2]
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("slot/empty_secondary")
      margin = smallPadding
      color = defTxtColor
      vplace = ALIGN_TOP
      hplace = ALIGN_RIGHT
      opacity = 0.5
    }.__update(tiny_txt)
    {
      rendObj = ROBJ_TEXT
      text = loc("slot/equipInBattle")
      margin = bigPadding
      color = defTxtColor
      vplace = ALIGN_BOTTOM
      hplace = ALIGN_LEFT
      opacity = 0.5
    }.__update(tiny_txt)
  ]
}

let mkItemsChapter = kwarg(function mkItemsChapterImpl(
  equipGroup, soldier, canManage, slotsCount, itemCtor = mkItem
) {
  let header = "locId" in equipGroup ? note(loc(equipGroup.locId)) : null
  let { equipScheme = {} } = soldier
  let groupSchemes = equipScheme
    .filter(@(_, slotType) slotTypeToEquipGroup?[slotType] == equipGroup)
    .map(@(scheme, slotType) scheme.__merge({ slotType }))
    .values()
  if (groupSchemes.len() == 0)
    return null

  groupSchemes.sort(@(a, b) (a?.uiOrder ?? 0) <=> (b?.uiOrder ?? 0))
  let soldierGuid = soldier.guid

  return function() {
    let slotsItems = getItemSlotsWithPreset(soldier,
      campItemsByLink.value, previewPreset.value)
    let errorSlotTypes = getErrorSlots(slotsItems, equipScheme)

    let rowsData = []
    local lastRow = null
    local isPrimaryGroup = false
    foreach (scheme in groupSchemes) {
      let { slotType, isPrimary = false, isDisabled = false } = scheme
      let currentSlotsCount = slotsCount.value?[slotType] ?? 0
      let slotsList = collectSlots(slotType, currentSlotsCount, slotsItems, soldierGuid)
      slotsList.each(@(s) s.__update({
        item = objInfoByGuid.value?[s.item?.guid] ?? s.item
        scheme = scheme
        hasWarning = errorSlotTypes?[slotType] ?? false
        isDisabled = isDisabled
        isUnseen = Computed(function() {
          let hasUnseenUpgradesMark = s?.item.basetpl in curUnseenAvailableUpgrades.value
            && !(isUpgradeUsed.value ?? false)
          return hasUnseenUpgradesMark
            || (unseenSoldiersWeaponry.value?[soldierGuid][slotType] ?? false)
        })
      }))

      if (!isPrimary && lastRow != null
        && lastRow.slots.len() < (equipGroup?.maxSlotTypesInRow ?? MAX_SLOT_TYPES_IN_ROW)) {
        lastRow.slots.extend(slotsList)
        continue
      }

      rowsData.append({
        slots = slotsList
        soldierGuid
        canManage
        itemCtor
        numInRow = isPrimary ? 1 : (equipGroup?.maxSlotInRow ?? MAX_ITEMS_IN_ROW)
      })
      lastRow = isPrimary ? null : rowsData.top()

      isPrimaryGroup = isPrimaryGroup || isPrimary
    }

    if (isPrimaryGroup) {
      let squadGuid = getLinkedSquadGuid(soldier)
      let { isParatroopers = false } = squadsByArmy.value?[curArmy.value]
        .findvalue(@(v) v.guid == squadGuid)
      if (isParatroopers) {
        let dropCrateSlot = {
          itemCtor = dropCrateSlotCtor
          numInRow = 1
          soldierGuid = soldier.guid
          slots = [
            {
              isLocked = true
              isDisabled = true
              isUnseen = false
              hasWarning = false
            }
          ]
          canManage = false
        }
        rowsData.insert(1, dropCrateSlot)
      }
    }

    return {
      watch = [slotsCount, objInfoByGuid, campItemsByLink, previewPreset]
      size = [soldierWndInnerWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = [ header ]
        .extend(rowsData.map(@(s) mkItemsBlock(s)))
    }
  }
})

let mkEquipPresetBtn = @() {
  watch = isItemActionInProgress
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  children = isItemActionInProgress.value
    ? waitingSpinner
    : {
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        children = Flat(loc("preset/equip/open"), mkPresetEquipBlock, {
          minWidth = slotBaseSize[0]
          margin = 0
          textParams = sub_txt
      })
    }
}

let soldierEquip = @(soldier, canManage = true, selectedKeyWatch = Watched(null),
  onDoubleClickCb = null, onResearchClickCb = null, dropExceptionCb = null
) function() {
    let itemCtor = @(p) mkItem(p.__merge({
      selectedKey = selectedKeyWatch
      onDoubleClickCb = onDoubleClickCb
      onDropExceptionCb = dropExceptionCb
      onResearchClickCb = onResearchClickCb
    }))

    let sGuid = soldier.value.guid
    let groupParams = {
      soldier = soldier.value
      canManage
      itemCtor
      slotsCount = soldierSlotsCount(sGuid,
        soldier.value?.equipScheme ?? {}, previewPreset.value?.slotsIncrease)
    }

    let children = equipGroups.map(@(equipGroup)
      mkItemsChapter(groupParams.__merge({ equipGroup })))

    children.append(mkEquipPresetBtn)

    return {
      watch = [soldier, previewPreset]
      flow = FLOW_VERTICAL
      gap = bigPadding
      size = SIZE_TO_CONTENT
      children = children
    }
}

return kwarg(soldierEquip)