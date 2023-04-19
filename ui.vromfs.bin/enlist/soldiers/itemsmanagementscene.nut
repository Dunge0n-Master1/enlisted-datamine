from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let mkItemBadge = require("components/mkItemBadge.nut")
let mkItemWithModuls = require("mkItemWithModuls.nut")
let mkSpinner = require("%ui/components/mkSpinner.nut")
let itemsTransferConfig = require("model/config/itemsTransferConfig.nut")
let itemTransferMsg = require("%enlist/items/itemTransferMsg.nut")
let clickShopItem = require("%enlist/shop/clickShopItem.nut")
let soldierEquipUi = require("soldierEquipUi.nut")
let itemsShopScene = require("%enlist/shop/itemsShopScene.nut")

let { debounce } = require("%sqstd/timers.nut")
let { fontSmall, fontLarge, fontXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { round_by_value } = require("%sqstd/math.nut")
let { showMsgbox } = require("%enlist/components/msgbox.nut")
let { getFirstLinkByType } = require("%enlSqGlob/ui/metalink.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { makeHorizScroll, makeVertScroll, styling } = require("%ui/components/scrollbar.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { mkItemDemands } = require("model/mkItemDemands.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { getItemName, trimUpgradeSuffix, getObjectName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { campItemsByLink } = require("%enlist/meta/profile.nut")
let { isItemActionInProgress } = require("model/itemActions.nut")
let { getShopItemsCmp, itemsToPresent } = require("%enlist/shop/armyShopState.nut")
let { jumpToArmyProgress } = require("%enlist/mainMenu/sectionsState.nut")
let { curArmyData, armoryByArmy } = require("%enlist/soldiers/model/state.nut")
let { mkItemUpgradeData, mkItemDisposeData } = require("model/mkItemModifyData.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { isObjGuidBelongToRentedSquad } = require("%enlist/soldiers/model/squadInfoState.nut")
let { showRentedSquadLimitsBox } = require("%enlist/soldiers/components/squadsComps.nut")
let { openUpgradeItemMsg, openDisposeItemMsg } = require("components/modifyItemComp.nut")
let { unequipBySlot } = require("%enlist/soldiers/unequipItem.nut")
let { curSoldierInfo } = require("%enlist/soldiers/model/curSoldiersState.nut")
let { mkKindIcon } = require("%enlSqGlob/ui/soldiersComps.nut")
let { itemTypeIcon } = require("%enlist/soldiers/components/itemTypesData.nut")
let { statusHintText } = require("%enlSqGlob/ui/itemPkg.nut")
let { isDetailsFull, detailsModeCheckbox } = require("%enlist/items/detailsMode.nut")
let { mkDetailsInfo } = require("components/itemDetailsComp.nut")
let { getSlotParams } = require("model/config/equipSlots.nut")
let { sound_play } = require("%dngscripts/sound_system.nut")
let { unblinkUnseen } = require("%ui/components/unseenComponents.nut")

let {
  mkUpgradeTab, mkSlotCount, mkPurchaseBtn, itemNameHeight, REMOVE_ADDED
} = require("components/itemsManagementPkg.nut")
let {
  focusResearch, findResearchUpgradeUnlock
} = require("%enlist/researches/researchesFocus.nut")
let {
  openSelectItem, selectParams, itemClear, slotItems, curInventoryItem, selectItem,
  curEquippedItem, viewItemMoveVariants, checkSelectItem, mkNewItemAlerts,
  autoSelectTemplate
} = require("model/selectItemState.nut")
let {
  colPart, colFull, columnGap, smallPadding, midPadding,
  defTxtColor, titleTxtColor, leftAppearanceAnim, rightAppearanceAnim
} = require("%enlSqGlob/ui/designConst.nut")
let {
  mkSlotBgOverride, mkSlotTextOverride
} = require("%enlSqGlob/ui/slotPkg.nut")


const TIME_TO_ADDED_ANIM = 3
const TIME_TO_KILL_ADDED = 4

let scrollStyle = styling.__merge({ Bar = styling.Bar(false) })
let headerHeight = colPart(2)
let itemSize = [colFull(4), colPart(1.6)]
let equipSlotSize = [colFull(4), colPart(1.6)]


let titleTxtStyle = { color = titleTxtColor }.__update(fontXLarge)
let headerTxtStyle = { color = defTxtColor }.__update(fontLarge)
let nameTxtStyle = { color = titleTxtColor }.__update(fontLarge)
let defTxtStyle = { color = defTxtColor }.__update(fontSmall)

let spinner = mkSpinner(colPart(0.7))

let curSlotIdx = Watched(-1)
let curHoverSlotIdx = Watched(-1)
let curUpgrIdxBySlot = Watched({})
let isEquipVisible = Watched(false)


let upgrStructure = Computed(@() allItemTemplates.value
  .map(@(armyTemplates) armyTemplates
    .filter(@(_tpl, tplName) tplName == trimUpgradeSuffix(tplName))
    .map(function(_tpl, tplName) {
      let upgrStepsList = []
      local itemTplName = tplName
      while (itemTplName != null) {
        upgrStepsList.append(itemTplName)
        itemTplName = armyTemplates[itemTplName]?.upgradeitem
      }
      return upgrStepsList
    })
  )
)


let sortByDemandsFunc = @(a, b)  (a?.unlocklevel ?? 0) <=> (b?.unlocklevel ?? 0)
  || a.basetpl <=> b.basetpl


let curSlotItems = Computed(function() {
  let { armyId = null } = selectParams.value
  let armyUpgrStructure = upgrStructure.value?[armyId]
  let templates = allItemTemplates.value?[armyId]
  let items = (clone slotItems.value)
    .filter(@(i) (i?.guid ?? "") != "")
    .sort(sortByDemandsFunc)

  let slotList = []
  if (templates == null)
    return []

  foreach (item in items) {
    let { basetpl } = item
    if (trimUpgradeSuffix(basetpl) != basetpl)
      continue

    if (slotList.findvalue(@(s) s[0].basetpl == basetpl) != null)
      continue

    slotList.append((armyUpgrStructure?[basetpl] ?? []).map(function(tpl) {
      let slotItem = items.findvalue(@(i) i.basetpl == tpl)
      return {
        basetpl = tpl
        count = slotItem?.count ?? 0
        item = slotItem ?? templates[tpl].__merge({ basetpl = tpl, guid = "" })
      }
    }))
  }

  return slotList
})


let function updateInvItem(_ = null) {
  let slotIdx = curSlotIdx.value
  let upgrIdx = curUpgrIdxBySlot.value?[slotIdx] ?? 0
  let slotList = curSlotItems.value

  let item = slotIdx < 0 ? null : slotList?[slotIdx][upgrIdx].item
  curInventoryItem(item)
}

let pendingUpdateInvItem = debounce(updateInvItem, 0.05)

armoryByArmy.subscribe(pendingUpdateInvItem)


let mkText = @(text, txtStyle) {
  rendObj = ROBJ_TEXT
  text
}.__update(txtStyle)


let mkUpgradeTabs = @(slotIdx, idxWatch, slotData, presentItems){
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  children = slotData.map(function(upgData, idx) {
    let isSelected = Computed(@() idxWatch.value == idx)
    return function() {
      let added = presentItems?[upgData.basetpl] ?? 0
      return {
        watch = isSelected
        size = [SIZE_TO_CONTENT, flex()]
        children = mkUpgradeTab(upgData, idx, isSelected.value, added, function() {
          curUpgrIdxBySlot.mutate(function(v) {
            v[slotIdx] <- idx
          })
          updateInvItem()
        })
      }.__update(rightAppearanceAnim(idx * 0.03))
    }
  })
}


let function mkUpgPanel(slotIdx, idxWatch, isSelected, slotData, presentItems) {
  let totalCount = slotData.reduce(@(r, v) r + v.count, 0)
  let totalAdded = slotData.reduce(@(r, v) r + (presentItems?[v.basetpl] ?? 0), 0)
  let hasOpenStatus = isSelected || totalAdded > 0
  return {
    size = [flex(), colPart(0.6)]
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    children = [
      hasOpenStatus
        ? null
        : mkSlotCount(totalCount, isSelected)
      hasOpenStatus
        ? mkUpgradeTabs(slotIdx, idxWatch, slotData, presentItems)
        : null
    ]
  }
}


let itemNameStyle = {
  size = [flex(), SIZE_TO_CONTENT]
  behavior = Behaviors.Marquee
}.__update(defTxtStyle)


let function onEquipItemDoubleClick(_) {
  if (curEquippedItem.value != null)
    unequipBySlot(selectParams.value, @(_) sound_play("ui/enlist/button_click"))
}

let function onInvItemDoubleClick(_) {
  let item = curInventoryItem.value
  if (item == null)
    return

  let { guid = "", basetpl = "" } = item
  if (guid != "" && basetpl != "" && checkSelectItem(item) == null) {
    selectItem(item, @(_) sound_play("ui/enlist/button_click"))
    return
  }

  if ("levelLimit" in mkItemDemands(item))
    return

  let shopItem = getShopItemsCmp(basetpl).value?[0]
  if (shopItem == null)
    return

  let armyLevel = curArmyData.value?.level ?? 0
  clickShopItem(shopItem, armyLevel)
}


let curItemsToPresent = Computed(@() itemsToPresent.value?[curArmyData.value?.guid] ?? {})

let function startAddedAnim() {
  anim_start(REMOVE_ADDED)
}

let function clearPresentItems() {
  let { armyId = null } = selectParams.value
  if (armyId == null)
    return

  if (armyId not in itemsToPresent.value)
    return

  itemsToPresent.mutate(function(presentData) {
    let armyData = clone presentData[armyId]
    foreach (slotData in curSlotItems.value)
      foreach (updData in slotData) {
        let { basetpl } = updData.item
        if (basetpl in armyData) {
          delete armyData[basetpl]
        }
      }
    presentData[armyId] <- armyData
  })
}


let function clearAllPresentItems() {
  itemsToPresent.mutate(function(presentData) {
    presentData.clear()
  })
}


let function equipListUi() {
  let slotList = curSlotItems.value
  let presentItems = curItemsToPresent.value
  return {
    watch = [curSlotItems, curItemsToPresent]
    flow = FLOW_HORIZONTAL
    gap = columnGap
    vplace = ALIGN_BOTTOM
    onAttach = function() {
      let autoSelectTpl = autoSelectTemplate.value
      if (autoSelectTpl != null) {
        local hasFound = false
        foreach (groupIdx, group in slotList) {
          if (hasFound)
            break
          foreach (itemIdx, item in group)
            if (item.basetpl == autoSelectTpl) {
              curSlotIdx(groupIdx)
              curUpgrIdxBySlot.mutate(function(v) {
                v[groupIdx] <- itemIdx
              })
              updateInvItem()
              hasFound = true
              break
            }
        }
      }
      gui_scene.resetTimeout(TIME_TO_ADDED_ANIM, startAddedAnim)
      gui_scene.resetTimeout(TIME_TO_KILL_ADDED, clearPresentItems)
    }
    onDetach = function() {
      gui_scene.clearTimer(startAddedAnim)
      gui_scene.clearTimer(clearPresentItems)
    }
    children = slotList.map(function(slotData, idx) {
      let isSelected = Computed(@() curSlotIdx.value == idx)
      let hasMenu    = Computed(@() curSlotIdx.value == idx || curHoverSlotIdx.value == idx)
      let curUpgrIdx = Computed(@() curUpgrIdxBySlot.value?[idx] ?? 0)
      let curItem = Computed(@() slotData[curUpgrIdx.value].item)
      let onClickCb = function(_) {
        curSlotIdx(idx)
        updateInvItem()
      }
      return {
        children = [
          {
            flow = FLOW_VERTICAL
            gap = smallPadding
            children = [
              function() {
                let item = curItem.value
                return {
                  watch = [isSelected, curItem]
                  flow = FLOW_VERTICAL
                  children = [
                    {
                      size = [flex(), itemNameHeight]
                      valign = ALIGN_CENTER
                      children = mkText(getItemName(item), itemNameStyle)
                    }
                    mkItemBadge({
                      item
                      itemSize
                      isAvailable = true
                      hasTypeIcon = true
                      isTierHidden = true
                      selectKey = item.basetpl
                      selectedKey = Watched(isSelected.value ? item.basetpl : "")
                      onDoubleClickCb = onInvItemDoubleClick
                    })
                  ]
                }.__update(leftAppearanceAnim(idx * 0.03))
              }
              @() {
                watch = hasMenu
                children = mkUpgPanel(idx, curUpgrIdx, hasMenu.value, slotData, presentItems)
              }
            ]
          }
          {
            size = flex()
            behavior = Behaviors.Button
            eventPassThrough = true
            onHover = function(on) {
              if (!isSelected.value)
                curHoverSlotIdx(on ? idx : -1)
            }
            onClick = onClickCb
          }
        ]
      }
    })
  }
}


let function mkEquippedSlot(params, item, slot, isSelected) {
  let { armyId, slotType, slotId } = params
  let onClickCb = function(p) {
    if (p?.slotType != slotType)
      return openSelectItem({
        armyId
        ownerGuid = p?.soldierGuid
        slotType = p?.slotType
        slotId = p?.slotId
      })
    curSlotIdx(-1)
    updateInvItem()
  }

  return mkItemWithModuls({
    item
    onClickCb
    onDoubleClickCb = onEquipItemDoubleClick
    slotType
    slotId
    itemSize = equipSlotSize
    slotImg = slot?.slotImg
    hasTypeIcon = true
    selectKey = "equipped_slot"
    selectedKey = Watched(isSelected ? "equipped_slot" : "")
  })
}


let equippedUi = function() {
  let params = selectParams.value
  let { ownerGuid, slotType, slotId } = params
  let slotItemsList = campItemsByLink.value?[ownerGuid][slotType] ?? []
  let item = slotId < 0
    ? slotItemsList?[0]
    : slotItemsList.findvalue(@(i) getFirstLinkByType(i, "index").tointeger() == slotId)

  let { equipScheme = {} } = curSoldierInfo.value
  let slot = getSlotParams(slotType) ?? getSlotParams(equipScheme?[slotType].ingameWeaponSlot)
  let slotText = item == null ? loc("menu/itemIsNotEquipped") : getItemName(item)
  return {
    watch = [selectParams, curSlotIdx, campItemsByLink, curSoldierInfo]
    size = [SIZE_TO_CONTENT, flex()]
    flow = FLOW_VERTICAL
    children = [
      {
        size = [flex(), itemNameHeight]
        valign = ALIGN_CENTER
        children = mkText(slotText, itemNameStyle)
      }
      mkEquippedSlot(params, item, slot, curSlotIdx.value == -1)
    ]
  }
}


let soldierIconSize = colPart(0.3)
let itemTypeIconSize = [colPart(0.4), colPart(0.4)]

let function selectedItemInfoUi() {
  let res = { watch = [curInventoryItem, curEquippedItem] }
  let item = curInventoryItem.value ?? curEquippedItem.value
  if (item == null)
    return res

  let { itemtype = null, itemsubtype = null } = item
  let typeIcon = itemtype == null ? null
    : {
        padding = midPadding
        rendObj = ROBJ_VECTOR_CANVAS
        commands = [[ VECTOR_ELLIPSE, 50, 50, 50, 50 ]]
        fillColor = 0xFF000000
        color = 0xFF000000
        children = itemTypeIcon(itemtype, itemsubtype, { size = itemTypeIconSize })
      }

  return res.__update({
    flow = FLOW_VERTICAL
    gap = midPadding
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    children = [
      function() {
        let soldier = curSoldierInfo.value
        let { sKind, sClassRare } = soldier
        return {
          watch = curSoldierInfo
          flow = FLOW_HORIZONTAL
          gap = columnGap
          valign = ALIGN_CENTER
          children = [
            mkKindIcon(sKind, sClassRare, soldierIconSize)
            mkText(getObjectName(soldier), defTxtStyle)
          ]
        }
      }
      {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        valign = ALIGN_CENTER
        children = [
          typeIcon
          mkText(getItemName(item), nameTxtStyle)
        ]
      }
    ]
  })
}


let headerUi = {
  size = [flex(), headerHeight]
  children = [
    {
      size = [flex(), headerHeight]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = colPart(0.6)
      children = [
        Bordered(loc("BackBtn"), itemClear, {
          hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn") }]]
        })
        mkText(loc("Choose item"), { hplace = ALIGN_CENTER }.__update(titleTxtStyle))
      ]
    }
    {
      size = [0, 0]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = selectedItemInfoUi
    }
  ]
}


let function mkMoveButton(inventoryItem, equippedItem) {
  if (inventoryItem == null)
    return Bordered(utf8ToUpper(loc("btn/moveItemToArmy")), @() null, { isEnabled = false })

  return function() {
    let { availableTypes = [], requiredOrders = [] } = itemsTransferConfig.value
    let isMovable = availableTypes.contains(inventoryItem.itemtype)
    let isItemsEqual = inventoryItem.guid == equippedItem?.guid
    let hasNoVariants = viewItemMoveVariants.value.len() == 0
    let isDisabled = !isMovable || isItemsEqual || hasNoVariants
    let btnCb = @() isDisabled ? null
      : itemTransferMsg(inventoryItem, viewItemMoveVariants, requiredOrders)
    let btnStyle = isDisabled ? { isEnabled = false } : {}
    return {
      watch = [viewItemMoveVariants, itemsTransferConfig]
      children = Bordered(utf8ToUpper(loc("btn/moveItemToArmy")), btnCb, btnStyle)
    }
  }
}


let function mkEquipButton(inventoryItem, equippedItem) {
  if (equippedItem != null && inventoryItem == null) {
    return Bordered(utf8ToUpper(loc("equip/quickUnequip")), function() {
      unequipBySlot(selectParams.value, @(_) sound_play("ui/enlist/button_click"))
    })
  }

  if (inventoryItem == null
    || inventoryItem.guid == ""
    || inventoryItem.basetpl == equippedItem?.basetpl
    || checkSelectItem(inventoryItem) != null)
    return Bordered(utf8ToUpper(loc("equip/quickUnequip")), @() null, { isEnabled = false })

  return Bordered(utf8ToUpper(loc("equip/quickEquip")), function() {
    selectItem(inventoryItem, @(_) sound_play("ui/enlist/button_click"))
  })
}


let openResearchUpgradeMsgbox = function(armyId, item) {
  let research = findResearchUpgradeUnlock(armyId, item)
  let hasResearch = research != null
  showMsgbox({
    text = loc(hasResearch ? "itemUpgradeResearch" : "itemUpgradeNoSquad")
    buttons = [
      {
        text = loc(hasResearch ? "mainmenu/btnResearch" : "squads/gotoUnlockBtn")
        action = function() {
          if (hasResearch)
            focusResearch(research)
          else
            jumpToArmyProgress()
        }
        isCurrent = true
      }
      { text = loc("Ok"), isCancel = true }
    ]
  })
}


let mkEquipPanelUi = function() {
  let newItemAlerts = mkNewItemAlerts(curSoldierInfo)
  return function() {
    let hasEquipVis = isEquipVisible.value
    return {
      watch = isEquipVisible
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = midPadding
      children = [
        watchElemState(function(sf) {
          return {
            size = [colPart(1), colPart(1)]
            behavior = Behaviors.Button
            onClick = @() isEquipVisible(!hasEquipVis)
            children = [
              mkSlotTextOverride(hasEquipVis ? S_HOVER : sf).__merge({
                size = [colPart(1), colPart(1)]
                rendObj = ROBJ_IMAGE
                image = Picture("ui/skin#weapon_menu_icon.svg:{0}:{0}:K".subst(colPart(1)))
              })
              @() {
                watch = newItemAlerts
                children = newItemAlerts.value.len() > 0 ? unblinkUnseen : null
              }
            ]
          }.__update(mkSlotBgOverride(hasEquipVis ? S_HOVER : sf))
        })
        hasEquipVis
          ? soldierEquipUi({
              soldier = curSoldierInfo
              isPresetHidden = true
            }, KWARG_NON_STRICT)
          : null
      ]
    }
  }
}


let fakeUpgradeButton = Bordered(utf8ToUpper(loc("btn/upgrade")), @() null, { isEnabled = false })

let function mkUpgradeButton(inventoryItem, equippedItem) {
  let item = inventoryItem ?? equippedItem
  if (item == null)
    return fakeUpgradeButton

  let upgradeDataWatch = mkItemUpgradeData(item)
  return function() {
    let res = {
      watch = upgradeDataWatch
    }
    let upgrData = upgradeDataWatch.value
    if (!upgrData.isUpgradable)
      return res.__update({ children = fakeUpgradeButton })

    let { isResearchRequired, armyId, upgradeMult } = upgrData
    if (isResearchRequired)
      return res.__update({
        children = Bordered(utf8ToUpper(loc("btn/upgrade")),
          @() openResearchUpgradeMsgbox(armyId, item), {
            onHover = @(on) setTooltip(on ? loc("tip/btnUpgrade") : null)
          })
      })

    let discount = round_by_value(100 - upgradeMult * 100, 1).tointeger()
    let upgradeDiscountInfo = discount <= 0 ? null : {
      pos = [0, -colPart(0.4)]
      rendObj = ROBJ_TEXT
      text = loc("upgradeDiscount", { discount })
    }.__update(defTxtStyle)

    return res.__update({
      children = [
        Bordered(utf8ToUpper(loc("btn/upgrade")), function() {
            if (isObjGuidBelongToRentedSquad(item?.guid))
              showRentedSquadLimitsBox()
            else
              openUpgradeItemMsg(item, upgrData)
          }, {
            onHover = function(on) {
              setTooltip(on ? loc("tip/btnUpgrade") : null)
            }
          }
        )
        upgradeDiscountInfo
      ]
    })
  }
}


let fakeDisposeButton = Bordered(utf8ToUpper(loc("btn/recycle")), @() null, { isEnabled = false })

let function mkDisposButton(inventoryItem) {
  if (inventoryItem == null)
    return fakeDisposeButton

  let disposeWatch = mkItemDisposeData(inventoryItem)
  return function() {
    let res = { watch = disposeWatch }
    let disposeData = disposeWatch.value
    if (!disposeData.isDisposable)
      return res.__update({ children = fakeDisposeButton })

    let { disposeMult, isDestructible = false, isRecyclable = false } = disposeData
    let bonus = round_by_value(disposeMult * 100 - 100, 1).tointeger()
    let disposeBonusInfo = bonus <= 0 ? null : {
      pos = [0, -colPart(0.4)]
      rendObj = ROBJ_TEXT
      text = loc("disposeBonus", { bonus })
    }.__update(defTxtStyle)

    let btnText = loc(isRecyclable ? "btn/recycle"
      : isDestructible ? "btn/dispose"
      : "btn/downgrade")
    let tipText = loc(isRecyclable ? "tip/btnRecycle"
      : isDestructible ? "tip/btnDispose"
      : "tip/btnDowngrade")
    return res.__update({
      children = [
        disposeBonusInfo
        Bordered(utf8ToUpper(btnText), @() openDisposeItemMsg(inventoryItem, disposeData), {
          onHover = @(on) setTooltip(on ? tipText : null)
        })
      ]
    })
  }
}


let function buttonsUi() {
  let inventoryItem = curInventoryItem.value
  let equippedItem = curEquippedItem.value
  return {
    watch = [isItemActionInProgress, curInventoryItem, curEquippedItem]
    flow = FLOW_HORIZONTAL
    size = [flex(), SIZE_TO_CONTENT]
    gap = { size = flex() }
    margin = [0, 0, 0, colFull(4) + columnGap]
    children = isItemActionInProgress.value
      ? spinner
      : [
          mkUpgradeButton(inventoryItem, equippedItem)
          mkEquipButton(inventoryItem, equippedItem)
          {
            flow = FLOW_HORIZONTAL
            gap = columnGap
            children = [
              mkMoveButton(inventoryItem, equippedItem)
              mkDisposButton(inventoryItem)
            ]
          }
        ]
  }
}


let function infoBlockUi() {
  let itemWatch = curInventoryItem.value != null
    ? curInventoryItem
    : curEquippedItem
  let item = itemWatch.value
  let res = {
    watch = [curInventoryItem, curEquippedItem]
  }
  if (item == null)
    return res

  return res.__update({
    size = [SIZE_TO_CONTENT, flex()]
    children = makeVertScroll({
      key = $"info_{item?.guid}"
      flow = FLOW_VERTICAL
      halign = ALIGN_RIGHT
      children = [
        mkDetailsInfo(itemWatch, isDetailsFull)
        detailsModeCheckbox
      ]
    }.__update(leftAppearanceAnim(0.1)), {
      styling = scrollStyle
      size = [SIZE_TO_CONTENT, flex()]
    })
  })
}


let function mkDemandsInfoUi() {
  let res = { watch = curInventoryItem }
  let item = curInventoryItem.value
  if (item == null)
    return res

  let demandsWatch = mkItemDemands(item)
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    margin = [0, 0, 0, colFull(4) + columnGap]
    halign = ALIGN_CENTER
    children = {
      size = [colFull(6), SIZE_TO_CONTENT]
      children = statusHintText(demandsWatch.value)
    }
  })
}


let equipSlotUi = @() {
  watch = isEquipVisible
  size = flex()
  flow = FLOW_VERTICAL
  children = isEquipVisible.value ? null
    : [
        equippedUi
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          gap = columnGap
          children = [
            mkDemandsInfoUi
            buttonsUi
            mkText(utf8ToUpper(loc("menu/warehouse")), headerTxtStyle)
          ]
        }
      ]
}


let selectItemScene = @() {
  watch = safeAreaBorders
  key = "selectItemScene"
  size = flex()
  flow = FLOW_VERTICAL
  gap = smallPadding
  padding = safeAreaBorders.value
  onAttach = function() {
    // TODO: need to add Tutorial later
    //if (armoryWndHasBeenOpend.value && isNewbie.value){
    //  openArmoryTutorial()
    //  markSeenArmoryTutorial()
    //}
  }
  behavior = Behaviors.MenuCameraControl
  children = [
    {
      size = flex()
      flow = FLOW_VERTICAL
      children = [
        headerUi
        {
          size = flex()
          flow = FLOW_HORIZONTAL
          gap = columnGap
          children = [
            {
              size = flex()
              flow = FLOW_VERTICAL
              gap = midPadding
              children = [
                mkEquipPanelUi()
                equipSlotUi
              ]
            }
            infoBlockUi
          ]
        }
      ]
    }
    @() {
      watch = isEquipVisible
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = columnGap
      children = isEquipVisible.value ? null
        : [
            mkPurchaseBtn(function() {
              let { armyId = null, scheme = null } = selectParams.value
              let templateId = curInventoryItem.value?.basetpl ?? curEquippedItem.value?.basetpl
              itemsShopScene(armyId, templateId, scheme?.itemTypes ?? [])
            })
            makeHorizScroll(equipListUi, {
              size = [flex(), SIZE_TO_CONTENT]
              rootBase = class {
                key = "itemsList"
                behavior = Behaviors.Pannable
                wheelStep = 0.2
              }
              styling = scrollStyle
            })
          ]
    }
  ]
}


let function open() {
  isEquipVisible(false)
  curSlotIdx(-1)
  curUpgrIdxBySlot.mutate(function(v) { v.clear() })
  updateInvItem()
  sceneWithCameraAdd(selectItemScene, "items_inventory")
}

if (selectParams.value)
  open()

selectParams.subscribe(function(p) {
  if (p == null) {
    clearAllPresentItems()
    sceneWithCameraRemove(selectItemScene)
  }
  else
    open()
})
