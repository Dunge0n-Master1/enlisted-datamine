from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { blinkUnseenIcon } = require("%ui/components/unseenSignal.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(50) })
let { Flat } = require("%ui/components/textButton.nut")
let { smallPadding, bigPadding, soldierWndWidth, unitSize, msgHighlightedTxtColor, slotBaseSize
} = require("%enlSqGlob/ui/viewConst.nut")
let { note } = require("%enlSqGlob/ui/defcomps.nut")
let { curArmy, objInfoByGuid, getSoldierItemSlots } = require("model/state.nut")
let { classSlotLocksByArmy } = require("%enlist/researches/researchesSummary.nut")
let { equipGroups, slotTypeToEquipGroup } = require("model/config/equipGroups.nut")
let { openSelectItem, getPossibleUnequipList, getAlternativeEquipList, getBetterItem,
  getWorseItem, getPossibleEquipList
} = require("model/selectItemState.nut")
let { curUnseenAvailableUpgrades, isUpgradeUsed } = require("model/unseenUpgrades.nut")
let mkItemWithMods = require("mkItemWithMods.nut")
let soldierSlotsCount = require("model/soldierSlotsCount.nut")
let { getLinkedArmyName, getLinkedSquadGuid } = require("%enlSqGlob/ui/metalink.nut")
let { unseenSoldiersWeaponry } = require("model/unseenWeaponry.nut")
let { equipByList, isItemActionInProgress } = require("model/itemActions.nut")
let { reserveSoldiers } = require("model/chooseSoldiersState.nut")
let { campItemsByLink } = require("%enlist/meta/profile.nut")
let { textMargin } = require("%ui/components/textButton.style.nut")
let { getErrorSlots } = require("%enlSqGlob/ui/itemsInfo.nut")


const opacityForDisabledItems = 0.3
const MAX_ITEMS_IN_ROW = 4
const MAX_SLOT_TYPES_IN_ROW = 3

let function openEquipMenu(p /*onClick params from mkItem*/) {
  openSelectItem({
    armyId = curArmy.value
    ownerGuid = p?.soldierGuid
    slotType = p?.slotType
    slotId = p?.slotId
  })
}

let mkItem = function(params) {
  return mkItemWithMods((params ?? {}).__merge({
    onClickCb = openEquipMenu
  }))
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
    let slotsItems = getSoldierItemSlots(soldierGuid, campItemsByLink.value)
    let errorSlotTypes = getErrorSlots(slotsItems, equipScheme)

    let rowsData = []
    local lastRow = null
    foreach (scheme in groupSchemes) {
      let { slotType, isPrimary = false, isDisabled = false } = scheme
      let currentSlotsCount = slotsCount.value?[slotType] ?? 0
      let slotsList = collectSlots(slotType, currentSlotsCount, slotsItems, soldierGuid)
      slotsList.each(@(s) s.__update({
        item = objInfoByGuid.value?[s.item?.guid]
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
    }

    return {
      watch = [slotsCount, objInfoByGuid, campItemsByLink]
      size = [soldierWndInnerWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = [ header ]
        .extend(rowsData.map(@(s) mkItemsBlock(s)))
    }
  }
})

let unequipUnseenIcon = blinkUnseenIcon(0.9, msgHighlightedTxtColor, "th-large")

let mkEquipBtn = @(soldier, objInfoByGuidWatched, reserveSoldiersWatch)
  function() {
    let res = {
      watch = [objInfoByGuidWatched, isItemActionInProgress, reserveSoldiersWatch]
    }
    let sGuid = soldier.guid
    let isInReserve = reserveSoldiersWatch.value.findindex(@(s) s.guid == sGuid) != null
    local changeEquipList = []
    local btnTextLocId = ""
    local unequipIcon = null
    if (isInReserve) {
      btnTextLocId = "removeAllEquipment"
      unequipIcon = unequipUnseenIcon
      let toRemoveEquipList = getPossibleUnequipList(sGuid)
      changeEquipList = getAlternativeEquipList(soldier, getWorseItem, toRemoveEquipList)
        .extend(toRemoveEquipList)
    }
    else if (getLinkedSquadGuid(soldier) != null) {
      btnTextLocId = "autoEquip"
      let toAddEquipList = getPossibleEquipList(soldier)
      changeEquipList = getAlternativeEquipList(soldier, getBetterItem)
        .extend(toAddEquipList)
    }

    if (changeEquipList.len() == 0)
      return res

    return res.__update({
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      children = isItemActionInProgress.value
        ? spinner
        : {
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_CENTER
            children = Flat(loc(btnTextLocId),
              @() equipByList(sGuid, changeEquipList),
              {
                margin = 0
                flow = FLOW_HORIZONTAL
                fgChild = unequipIcon
                minWidth = slotBaseSize[0]
                textParams = {
                  margin = [textMargin[0], hdpx(10), textMargin[0], textMargin[1]]
                }.__update(sub_txt)
              })
          }
    })
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
      slotsCount = soldierSlotsCount(sGuid, soldier.value?.equipScheme ?? {})
    }

    let children = equipGroups.map(@(equipGroup)
      mkItemsChapter(groupParams.__merge({ equipGroup })))

    children.append(mkEquipBtn(soldier.value, objInfoByGuid, reserveSoldiers))

    return {
      watch = soldier
      flow = FLOW_VERTICAL
      gap = bigPadding
      size = SIZE_TO_CONTENT
      children = children
    }
}

return kwarg(soldierEquip)