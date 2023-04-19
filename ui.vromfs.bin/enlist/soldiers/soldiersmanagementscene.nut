from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let mkSoldierDetailsUi = require("%enlist/soldiers/mkSoldierDetailsUi.nut")
let { squadInfo } = require("%enlist/squad/squadInfo.nut")
let mkDotPaginator = require("%enlist/components/mkDotPaginator.nut")
let soldiersPurchaseWnd = require("%enlist/shop/soldiersPurchaseWnd.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { blinkUnseenIcon } = require("%ui/components/unseenSignal.nut")
let { blinkUnseen, unblinkUnseen } = require("%ui/components/unseenComponents.nut")
let faComp = require("%ui/components/faComp.nut")
let reqUpgradeMsgBox = require("%enlist/soldiers/researchUpgradeMsgBox.nut")
let armyCurrencyUi = require("%enlist/shop/armyCurrencyUi.nut")
let currenciesWidgetUi = require("%enlist/currency/currenciesWidgetUi.nut")

let { promoWidget } = require("%enlSqGlob/ui/mkPromoWidget.nut")
let { showMsgbox } = require("%enlist/components/msgbox.nut")
let { debounce } = require("%sqstd/timers.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontXSmall, fontSmall, fontLarge, fontXLarge, fontXXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { curArmy, curSquadParams } = require("%enlist/soldiers/model/state.nut")
let { curSoldierIdx } = require("%enlist/soldiers/model/curSoldiersState.nut")
let { soldierKindsList, getKindCfg } = require("%enlSqGlob/ui/soldierClasses.nut")
let { perkLevelsGrid } = require("%enlist/meta/perks/perksExp.nut")
let { perksData } = require("%enlist/soldiers/model/soldierPerks.nut")
let { kindIcon } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { campPresentation, needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let { mkSoldierBadgeData } = require("%enlSqGlob/ui/soldiersComps.nut")
let { curCanUnequipSoldiersList } = require("model/selectItemState.nut")
let { mkVehicleBadge } = require("%enlSqGlob/ui/mkVehicleBadge.nut")
let { unseenSoldiers, markSoldierSeen } = require("model/unseenSoldiers.nut")
let { curArmyReserveCapacity } = require("model/reserve.nut")
let {
  curVehicleBadgeData, curVehicleSeats
} = require("%enlist/vehicles/vehiclesListState.nut")
let {
  mkSoldierBadge, mkEmptySoldierBadge, soldierCardSize, mkSoldierPresentation,
  SQUAD_COLOR_SCHEME_ID, RESERVE_COLOR_SCHEME_ID, LOCKED_COLOR_SCHEME_ID
} = require("%enlSqGlob/ui/mkSoldierBadge.nut")
let { READY, NOT_FIT_CUR_SQUAD } = require("%enlSqGlob/readyStatus.nut")
let {
  soldiersSquad, curSquadSoldierIdx, selectedSoldier, soldiersStatuses,
  squadSoldiers, closeChooseSoldiersWnd, applySoldierManage, reserveSoldiers,
  soldierToReserveByIdx, maxSoldiersInBattle, selectedSoldierGuid,
  changeSoldierOrderByIdx, getCanTakeSlots, isPurchaseWndOpend
} = require("model/chooseSoldiersState.nut")
let {
  titleTxtColor, defTxtColor, accentColor, commonBorderRadius, defItemBlur,
  colPart, colFull, columnGap, smallPadding, blinkBdColor, darkTxtColor,
  attentionTxtColor, hoverBgColor, panelBgColor, bigPadding,
  midPadding, miniPadding, navHeight, hoverPanelBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let { curSoldierKind } = require("model/soldiersState.nut")
let soldierDismissButton = require("%enlist/soldiers/soldierDismissButton.nut")


const PAGE_SIZE = 11
const NO_SOLDIER_SLOT_IDX = -1

let unseenIcon = blinkUnseenIcon(0.9, attentionTxtColor, "th-large")

let amountTxtStyle = { color = titleTxtColor }.__update(fontXSmall)
let activeTxtStyle = { color = darkTxtColor }.__update(fontXSmall)
let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let nameTxtStyle = { color = defTxtColor }.__update(fontLarge)
let headerTxtStyle = { color = defTxtColor }.__update(fontXLarge)
let titleTxtStyle = { color = titleTxtColor }.__update(fontXXLarge)


let sKindSize = colPart(0.35)
let sKindOffset = (columnGap * 0.3).tointeger()


let reserveWidth = colFull(8)
let reserveHeaderHeight = colPart(1)
let vehicleSquadWidth = colFull(6)
let reserveHeight = (soldierCardSize[1] + columnGap) * 3


let wrapParams = {
  width = reserveWidth
  hGap = columnGap
  vGap = columnGap
}

let curPageIdx = Watched(0)

curSoldierKind.subscribe(@(_) curPageIdx(0))

let reserveBadges = Computed(function() {
  let { expToLevel = [] } = perkLevelsGrid.value
  let color = needFreemiumStatus.value ? campPresentation.value?.color : null
  let perks = perksData.value
  return reserveSoldiers.value.map(@(s, idx)
    { absIdx = idx }.__update(mkSoldierBadgeData(s, perks, expToLevel, color))
  )
})

let curReserve = Computed(function() {
  let sKind = curSoldierKind.value
  return reserveBadges.value.filter(@(s) s.sKind == sKind)
})

let curPageReserve = Computed(function() {
  let startIdx = curPageIdx.value * PAGE_SIZE
  return curReserve.value
    .slice(startIdx, startIdx + PAGE_SIZE)
    .map(@(s, idx) { inPageIdx = idx + 1 }.__update(s))
})

let activeSoldiers = Computed(function() {
  let { expToLevel = [] } = perkLevelsGrid.value
  let color = needFreemiumStatus.value ? campPresentation.value?.color : null
  let perks = perksData.value
  return squadSoldiers.value
    .map(@(s)
      s == null ? null : mkSoldierBadgeData(s, perks, expToLevel, color)
    )
})

let pagesCount = Computed(@() 1 + (curReserve.value.len() - 1) / PAGE_SIZE)

let isVehicleSquad = Computed(@() curVehicleBadgeData.value != null)

let curDropTargIdx = Watched(NO_SOLDIER_SLOT_IDX)
let curDropTargIdxInPage = Watched(NO_SOLDIER_SLOT_IDX)

let curDropData = Watched(null)
curDropData.subscribe(@(_) curDropTargIdx(NO_SOLDIER_SLOT_IDX))

let curDropTgtIdxDebounced = Watched(null)
foreach(v in [curDropTargIdx, curDropTargIdxInPage])
  v.subscribe(debounce(@(_) curDropTgtIdxDebounced({
    soldierIdx = curDropTargIdx.value
    inPageIdx = curDropTargIdxInPage.value
  }), 0.01))


let soldierToTake = Computed(function() {
  let dropIdx = curDropData.value?.soldierIdx
  return dropIdx != null
    ? reserveSoldiers.value?[dropIdx - maxSoldiersInBattle.value]
    : reserveSoldiers.value.findvalue(@(s) s.guid == selectedSoldierGuid.value)
})

let slotsHighlight = Computed(function() {
  let soldier = soldierToTake.value
  return soldier == null ? [] : getCanTakeSlots(soldier, squadSoldiers.value)
})


let soldiersPaginator = mkDotPaginator({
  id = "soldiers"
  pageWatch = curPageIdx
  dotSize = hdpx(15)
})


let currencies = {
  flow = FLOW_HORIZONTAL
  gap = columnGap
  hplace = ALIGN_RIGHT
  children = [
    currenciesWidgetUi
    armyCurrencyUi
  ]
}


let headerUi = {
  size = [flex(), navHeight]
  valign = ALIGN_CENTER
  children = [
    {
      flow = FLOW_HORIZONTAL
      gap = colFull(1)
      valign = ALIGN_CENTER
      children = [
        Bordered(loc("BackBtn"),
          @() applySoldierManage(closeChooseSoldiersWnd),
          {
            hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn") }]]
          })
        {
          rendObj = ROBJ_TEXT
          hplace = ALIGN_CENTER
          text = utf8ToUpper(loc("soldier/manageButton"))
        }.__update(titleTxtStyle)
      ]
    }
    {
      hplace = ALIGN_CENTER
      vplace = ALIGN_TOP
      padding = midPadding
      children = promoWidget("soldiers_manage")
    }
    currencies
  ]
}


let unseenKinds = Computed(function() {
  let unseen = unseenSoldiers.value
  return reserveBadges.value.reduce(function(r, v) {
    if (v.guid in unseen && v.sKind not in r)
      r.rawset(v.sKind, true)
    return r
  }, {})
})


let specializationsUi = {
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    @() {
      watch = curSoldierKind
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc(getKindCfg(curSoldierKind.value).locId))
    }.__update(nameTxtStyle)
    function() {
      let { maxClasses = {} } = curSquadParams.value
      return {
        watch = curSquadParams
        size = [reserveWidth, reserveHeaderHeight]
        flow = FLOW_HORIZONTAL
        children = soldierKindsList.map(function(sKind) {
          let isSelected = Computed(@() curSoldierKind.value == sKind)
          let isUnseen = Computed(@() sKind in unseenKinds.value)
          let amount = Computed(@() reserveBadges.value
            .reduce(@(r, v) v.sKind == sKind ? r + 1 : r, 0))
          let isSuitable = sKind in maxClasses
          return watchElemState(@(sf) {
            size = flex()
            behavior = Behaviors.Button
            onClick = @() curSoldierKind(sKind)
            children = function() {
              let isActive = isSelected.value
              let iconColor = isActive ? darkTxtColor : titleTxtColor
              return {
                watch = isSelected
                rendObj = ROBJ_WORLD_BLUR
                color = defItemBlur
                fillColor = isSelected.value ? accentColor
                  : sf & S_HOVER ? hoverPanelBgColor
                  : panelBgColor
                size = flex()
                children = [
                  kindIcon(sKind, sKindSize, null, iconColor).__update({
                    margin = [bigPadding, 0]
                    hplace = ALIGN_CENTER
                    vplace = ALIGN_CENTER
                    opacity = !isSuitable && !isActive && (sf & S_HOVER) <= 0 ? 0.3 : 1
                  })
                  @() {
                    watch = amount
                    margin = [miniPadding, smallPadding]
                    rendObj = ROBJ_TEXT
                    text = amount.value > 0 ? amount.value : null
                  }.__update(isActive ? activeTxtStyle : amountTxtStyle)
                  @() {
                    watch = isUnseen
                    hplace = ALIGN_RIGHT
                    children = isUnseen.value ? unblinkUnseen : null
                  }
                ]
              }
            }
          })
        })
      }
    }
  ]
}


let xAnimDist = soldierCardSize[0] + columnGap
let yAnimDist = soldierCardSize[1] + columnGap
let yAnimBigDist = soldierCardSize[1] + columnGap * 3

let soldierDragAnim = @(moveData, soldierIdx, inPageIdx, sKind, stateFlags, nest, child, yGap)
  nest.__merge({
    behavior = Behaviors.DragAndDrop
    canDrop = @(data) data?.dragid == "soldier"
    dropData = "dropData" in nest
      ? nest.dropData
      : { soldierIdx, inPageIdx, sKind, dragid = "soldier" }
    onDragMode = @(on, data) curDropData(on ? data : null)
    onElemState = function(sf) {
      stateFlags(sf)
      if (!curDropData.value || curDropData.value.soldierIdx == soldierIdx)
        return
      if (sf & S_ACTIVE) {
        curDropTargIdx(soldierIdx)
        curDropTargIdxInPage(inPageIdx)
      }
      else if (curDropTargIdx.value == soldierIdx)
        curDropTargIdx(NO_SOLDIER_SLOT_IDX)
    }
    transform = {}
    children = child.__merge({
      transform = {}
      transitions = [{ prop = AnimProp.translate, duration = 0.3, easing = OutQuad }]
      behavior = Behaviors.RtPropUpdate
      rtAlwaysUpdate = true
      update = @() {
        transform = {
          translate = [moveData.value[0] * xAnimDist, moveData.value[1] * yGap]
        }
      }
    })
  })


const COLUMNS_IN_SQUAD_BLOCK = 4
const COLUMNS_IN_VEH_SQUAD_BLOCK = 3

let function calcSquadAnimData(idx, dragIdx, targIdx, columns) {
  let column = idx % columns
  if ((dragIdx >= 0 && dragIdx < idx) && targIdx >= idx)
    return column == 0 ? [columns - 1, -1] : [-1, 0]

  if ((dragIdx == -1 || dragIdx > idx) && targIdx <= idx)
    return column == columns - 1 ? [-(columns - 1), 1] : [1, 0]

  return [0, 0]
}


let function mkMoveComputed(absIdx, inPageIdx, fixedSlotsWatch, hasVehicle) {
  let columns = hasVehicle ? COLUMNS_IN_VEH_SQUAD_BLOCK : COLUMNS_IN_SQUAD_BLOCK
  return Computed(function() {
    let dragData = curDropData.value
    let targData = curDropTgtIdxDebounced.value
    let dragIdx = dragData?.soldierIdx ?? -1
    let targIdx = targData?.soldierIdx ?? -1

    if (targIdx < 0 || dragIdx < 0 || dragIdx == absIdx)
      return [0, 0]

    let inPageDragIdx = dragData?.inPageIdx ?? -1
    let inPageTargIdx = targData?.inPageIdx ?? -1
    let fixedSlots = fixedSlotsWatch.value
    if (absIdx < fixedSlots)
      return (dragIdx < fixedSlots && targIdx < fixedSlots)
        ? calcSquadAnimData(inPageIdx, dragIdx, targIdx, columns)
        : [0, 0]

    return dragIdx >= fixedSlots && targIdx >= fixedSlots
        ? calcSquadAnimData(inPageIdx, inPageDragIdx, inPageTargIdx, columns)
      : dragIdx < fixedSlots && targIdx >= fixedSlots
        ? calcSquadAnimData(inPageIdx, -1, inPageTargIdx, columns)
      : [0, 0]
  })
}


let highlightBorder = {
  size = flex()
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  borderColor = blinkBdColor
  borderRadius = commonBorderRadius
  transform = { pivot = [0.5, 0.5] }
  animations = [{
    prop = AnimProp.opacity, from = 1, to = 0, duration = 2,
    play = true, loop = true, easing = CosineFull
  }]
}


let unseenMark = @(soldierGuid) @() {
  watch = unseenSoldiers
  hplace = ALIGN_RIGHT
  children = (unseenSoldiers.value?[soldierGuid] ?? false) ? blinkUnseen : null
}


let function autoMoveToReserve(squadSoldierIdx, sKind) {
  curSoldierKind(sKind)
  curPageIdx(0)
  soldierToReserveByIdx(squadSoldierIdx)
}


let function swapSoldierPlace() {
  let soldier = selectedSoldier.value
  if (soldier == null)
    return

  let { guid, sKind } = soldier
  let squadSoldierIdx = activeSoldiers.value.findindex(@(s) s?.guid == guid)
  if (squadSoldierIdx != null) {
    autoMoveToReserve(squadSoldierIdx, sKind)
    return
  }

  let reservedSoldierIdx = reserveSoldiers.value.findindex(@(s) s.guid == guid)
  if (reservedSoldierIdx == null)
    return

  let freeIdx = activeSoldiers.value.indexof(null)
  if (freeIdx == null) {
    showMsgbox({ text = loc("noFreeSlotForNewSoldier") })
    return
  }

  let offset = maxSoldiersInBattle.value
  changeSoldierOrderByIdx(reservedSoldierIdx + offset, freeIdx)
}


let function mkSoldierSlot(soldier, idx, inPageIdx, tgtHighlight, hasVehicle, colorScemeId, addObjects) {
  let isSelectedWatch = Computed(@() selectedSoldierGuid.value == soldier.guid)
  let isDropTarget = Computed(@() idx < maxSoldiersInBattle.value
    && curDropTargIdx.value == idx
    && (curDropData.value?.soldierIdx ?? -1) >= maxSoldiersInBattle.value
  )
  let needHighlight = Computed(@() tgtHighlight.value?[idx] ?? false)
  let moveData = mkMoveComputed(idx, inPageIdx, maxSoldiersInBattle, hasVehicle)
  let soldierStatus = Computed(@() soldiersStatuses.value?[soldier.guid] ?? READY)
  let onDrop = @(data) changeSoldierOrderByIdx(data?.soldierIdx, idx)
  let stateFlags = Watched(0)
  let group = ElemGroup()

  return function() {
    let sf = stateFlags.value
    let status = soldierStatus.value
    let isSelected = isSelectedWatch.value || isDropTarget.value
    let isLocked = status & NOT_FIT_CUR_SQUAD

    let onClick = function() {
      if (soldier.guid != selectedSoldierGuid.value)
        selectedSoldierGuid(soldier.guid)
    }

    let nest = {
      watch = [stateFlags, soldierStatus, isSelectedWatch, isDropTarget, needHighlight]
      key = $"slot_{soldier?.guid}_{idx}"
      xmbNode = XmbNode()
      group
      onDrop
      onClick
      onDoubleClick = swapSoldierPlace
      onHover = function(on) {
        hoverHoldAction("markSeenSoldier",
          { armyId = curArmy.value, guid = soldier?.guid },
          @(v) markSoldierSeen(v.armyId, v.guid))(on)
      }
    }

    let child = {
      key = $"slot_badge_{soldier?.guid}_{idx}"
      children = [
        mkSoldierBadge(idx, soldier, isSelected, sf, null, isLocked ? LOCKED_COLOR_SCHEME_ID : colorScemeId)
        needHighlight.value ? highlightBorder : null
        addObjects.len() == 0 ? null
          : {
              flow = FLOW_HORIZONTAL
              children = addObjects
            }
      ]
    }

    let yGap = hasVehicle ? yAnimBigDist : yAnimDist
    return isLocked
      ? nest.__update({
          behavior = Behaviors.Button
          onElemState = @(sf) stateFlags(sf)
          transform = {}
          children = child
        })
      : soldierDragAnim(moveData, idx, inPageIdx, soldier.sKind, stateFlags, nest, child, yGap)
  }
}


let function chooseSelectedReserveSoldier(slotIdx) {
  let soldier = selectedSoldier.value
  if (soldier == null)
    return

  let { guid } = soldier
  let squadSoldierIdx = activeSoldiers.value.findindex(@(s) s?.guid == guid)
  if (squadSoldierIdx != null)
    return

  let reservedSoldierIdx = reserveSoldiers.value.findindex(@(s) s.guid == guid)
  if (reservedSoldierIdx == null)
    return

  let offset = maxSoldiersInBattle.value
  changeSoldierOrderByIdx(reservedSoldierIdx + offset, slotIdx)
}


let function mkEmptySlot(idx, tgtHighlight, hasVehicle) {
  let group = ElemGroup()
  let onDrop = @(data) changeSoldierOrderByIdx(data?.soldierIdx, idx)
  let isDropTarget = Computed(@() curDropTargIdx.value == idx
    && (curDropData.value?.soldierIdx ?? -1) >= maxSoldiersInBattle.value
  )
  let needHighlight = Computed(@() tgtHighlight.value?[idx] ?? false)
  let stateFlags = Watched(0)
  let moveData = mkMoveComputed(idx, idx, maxSoldiersInBattle, hasVehicle)
  return function() {
    let hasBlink = needHighlight.value
    let nest = {
      watch = [stateFlags, isDropTarget, needHighlight]
      group = group
      size = soldierCardSize
      key = $"emptySlot_{idx}"
      onDrop = onDrop
      dropData = null
      onClick = @() chooseSelectedReserveSoldier(idx)
    }
    let child = {
      key = $"empty_slot_{idx}{hasBlink}"
      size = flex()
      children = [
        mkEmptySoldierBadge(stateFlags.value, isDropTarget.value, hasBlink)
        hasBlink ? highlightBorder : null
      ]
    }
    let yGap = hasVehicle ? yAnimBigDist : yAnimDist
    return soldierDragAnim(moveData, idx, idx, "", stateFlags, nest, child, yGap)
  }
}


let mkSeatText = @(seatLocId) seatLocId == null ? null
  : {
      padding = [0, smallPadding]
      pos = [0, -(columnGap + bigPadding)]
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc(seatLocId))
    }.__update(defTxtStyle)


let mkSoldiersList = kwarg(@(
  soldiers, hasUnseen = false, idxOffset = Watched(0), isInReserve = false,
  tgtHighlight = Watched([]), prevObject = null,
  hasVehicle = false, seats = null
) function() {
  let curWrapParams = wrapParams.__merge({
    width = hasVehicle ? vehicleSquadWidth : reserveWidth
    vGap = hasVehicle ? 3 * columnGap : columnGap
  })

  let soldiersList = (prevObject == null ? [] : [prevObject])
    .extend(soldiers.value.map(function(s, idx) {
      let absIdx = (isInReserve ? s.absIdx : idx) + idxOffset.value
      if (s == null)
        return mkEmptySlot(absIdx, tgtHighlight, hasVehicle)

      let addObjects = hasUnseen ? [unseenMark(s.guid)] : []
      if (isInReserve && s.guid in curCanUnequipSoldiersList.value)
        addObjects.append(unseenIcon)
      let inPageIdx = isInReserve ? s.inPageIdx : idx

      let seatLocId = seats?[idx].locName
      let colorScemeId = !isInReserve ? SQUAD_COLOR_SCHEME_ID : RESERVE_COLOR_SCHEME_ID
      let slotChild = mkSoldierSlot(s, absIdx, inPageIdx, tgtHighlight, hasVehicle, colorScemeId, addObjects)
      return hasVehicle
        ? { children = [ slotChild, mkSeatText(seatLocId) ]}
        : slotChild
    }))

  return {
    watch = [soldiers, idxOffset, tgtHighlight, curCanUnequipSoldiersList]
    children = wrap(soldiersList, curWrapParams)
  }
})


let reserveCountText = Computed(function() {
  let count = reserveSoldiers.value.len()
  if (count <= 0)
    return ""

  let total = curArmyReserveCapacity.value
  return total <= 0 ? "" : loc("countTotalText", { count, total })
})


let function reserveCountUi() {
  let res = { watch = reserveCountText }
  let reserveCount = reserveSoldiers.value.len()
  if (reserveCount <= 0)
    return res

  return {
    flow = FLOW_HORIZONTAL
    gap = columnGap
    children = [
      {
        rendObj = ROBJ_TEXT
        text = utf8ToUpper(loc("soldierReserveHeader"))
      }.__update(headerTxtStyle)
      {
        flow = FLOW_HORIZONTAL
        gap = columnGap / 2
        padding = [0, columnGap]
        children = [
          faComp("user", {
            fontSize = sKindSize
            color = titleTxtColor
          })
          {
            rendObj = ROBJ_TEXT
            text = reserveCountText.value
          }.__update(headerTxtStyle)
        ]
      }
    ]
  }
}


let specPagesDotsUi = @() {
  watch = pagesCount
  size = [reserveWidth, SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  margin = [sKindOffset, 0]
  valign = ALIGN_BOTTOM
  children = [
    reserveCountUi
    soldiersPaginator(pagesCount.value)
  ]
}


let function curVehicleUi() {
  let res = { watch = curVehicleBadgeData }
  if (curVehicleBadgeData.value == null)
    return res

  return res.__update({
    children =  mkVehicleBadge(curVehicleBadgeData.value, false)
  })
}


let squadSoldiersUi = @() {
  watch = [isVehicleSquad, curVehicleSeats]
  flow = FLOW_HORIZONTAL
  gap = columnGap
  children = [
    curVehicleUi
    mkSoldiersList({
      soldiers = activeSoldiers
      hasUnseen = false
      idxOffset = Watched(0)
      tgtHighlight = slotsHighlight
      hasVehicle = isVehicleSquad.value
      seats = curVehicleSeats.value
    })
  ]
}


let reserveStateFlags = Watched(0)
let reserveUi = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = midPadding
  children = [
    specPagesDotsUi
    specializationsUi
    {
      size = [SIZE_TO_CONTENT, reserveHeight]
      behavior = Behaviors.DragAndDrop
      onDrop = @(data) autoMoveToReserve(data?.soldierIdx, data?.sKind)
      canDrop = @(data) data?.soldierIdx != null && data.soldierIdx < maxSoldiersInBattle.value
      skipDirPadNav = true
      onElemState = @(sf) reserveStateFlags(sf)
      children = [
        {
          size = [SIZE_TO_CONTENT, reserveHeight]
          clipChildren = true
          children = mkSoldiersList({
            soldiers = curPageReserve
            idxOffset = maxSoldiersInBattle
            hasUnseen = true
            isInReserve = true
            prevObject = watchElemState(@(sf) {
              behavior = Behaviors.Button
              onClick = @() isPurchaseWndOpend(true)
              children = mkEmptySoldierBadge(sf, false, false, true)
            })
          })
        }
        function() {
          let isVisible = (reserveStateFlags.value & S_HOVER) != 0 || curDropData.value != null
          let isHighlighted = (reserveStateFlags.value & S_ACTIVE) != 0
          return {
            watch = [curDropData, reserveStateFlags]
            size = [flex(), hdpx(1)]
            vplace = ALIGN_BOTTOM
            rendObj = isVisible ? ROBJ_SOLID : null
            color = isHighlighted ? hoverBgColor : panelBgColor
          }
        }
      ]
    }
  ]
}


let curSoldierBadgeData = Computed(function() {
  let { expToLevel = [] } = perkLevelsGrid.value
  let color = needFreemiumStatus.value ? campPresentation.value?.color : null
  let perks = perksData.value
  let soldier = selectedSoldier.value
  return soldier == null ? null : mkSoldierBadgeData(soldier, perks, expToLevel, color)
})


let function swapButtonUi() {
  let res = {
    watch = [selectedSoldier, activeSoldiers]
  }
  let soldier = selectedSoldier.value
  if (soldier == null)
    return res

  let isActive = activeSoldiers.value.findindex(@(s) s?.guid == soldier.guid) != null
  let btnLocId = isActive ? "MoveToReserve" : "TakeToBattle"
  return res.__update({
    hplace = ALIGN_CENTER
    children = Bordered(loc(btnLocId), swapSoldierPlace, { hotkeys = [["^J:X"]] })
  })
}


let manageBlockUi = {
  size = flex()
  children = [
    {
      size = flex()
      flow = FLOW_VERTICAL
      children = [
        reserveUi
        {
          size = flex()
          valign = ALIGN_CENTER
          children = squadInfo()
        }
        squadSoldiersUi
      ]
    }
    {
      flow = FLOW_VERTICAL
      gap = columnGap
      padding = [0,0,0,colPart(3)]
      hplace = ALIGN_CENTER
      halign = ALIGN_CENTER
      vplace = ALIGN_BOTTOM
      children = [
        function() {
          let badgeData = curSoldierBadgeData.value
          return {
            watch = curSoldierBadgeData
            children = badgeData == null ? null : mkSoldierPresentation(badgeData)
          }
        }
        @() {
          watch = [selectedSoldier, activeSoldiers]
          hplace = ALIGN_CENTER
          valign = ALIGN_BOTTOM
          children = [
            swapButtonUi
            soldierDismissButton(selectedSoldier.value,
              @() selectedSoldierGuid(activeSoldiers.value[0].guid))
          ]
        }
      ]
    }
  ]
}


let contentUi = {
  size = flex()
  padding = [0,0,colPart(1),0]
  children = [
    manageBlockUi
    {
      size = [SIZE_TO_CONTENT, flex()]
      hplace = ALIGN_RIGHT
      children = mkSoldierDetailsUi({
        soldierWatch = selectedSoldier
        onResearchClickCb = reqUpgradeMsgBox
      })
    }
  ]
}


let chooseSoldiersScene = @() {
  watch = [safeAreaBorders, curArmy, isPurchaseWndOpend]
  size = flex()
  children = [
    {
      size = flex()
      flow = FLOW_VERTICAL
      gap = colPart(1.12)
      padding = safeAreaBorders.value
      behavior = Behaviors.MenuCameraControl
      children = [ headerUi, contentUi ]
    }
    isPurchaseWndOpend.value
      ? soldiersPurchaseWnd(@() isPurchaseWndOpend(false))
      : null
  ]
}


let isOpened = keepref(Computed(@()
  soldiersSquad.value != null && selectedSoldier.value != null))

let open = function() {
  curSquadSoldierIdx(curSoldierIdx.value)
  curSoldierIdx(-1)
  sceneWithCameraAdd(chooseSoldiersScene, "soldiers_quarters")
  curSoldierKind(selectedSoldier.value.sKind)
  curPageIdx(0)
}

if (isOpened.value)
  open()

isOpened.subscribe(function(v) {
  if (v == true)
    open()
  else
    sceneWithCameraRemove(chooseSoldiersScene)
})
