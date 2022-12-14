from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let mkSoldierDetailsUi = require("%enlist/soldiers/mkSoldierDetailsUi.nut")
let squadInfo = require("%enlist/squad/squadInfo.nut")
let mkDotPaginator = require("%enlist/components/mkDotPaginator.nut")
let openSoldiersPurchase = require("%enlist/shop/soldiersPurchaseWnd.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let unseenSignal = require("%ui/components/unseenSignal.nut")
let faComp = require("%ui/components/faComp.nut")
let reqUpgradeMsgBox = require("%enlist/soldiers/researchUpgradeMsgBox.nut")

let { showMsgbox } = require("%enlist/components/msgbox.nut")
let { debounce } = require("%sqstd/timers.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontSmall, fontLarge, fontXLarge, fontXXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { curSoldierIdx } = require("model/squadInfoState.nut")
let { soldierKindsList, getKindCfg } = require("%enlSqGlob/ui/soldierClasses.nut")
let { perkLevelsGrid } = require("%enlist/meta/perks/perksExp.nut")
let { perksData } = require("%enlist/soldiers/model/soldierPerks.nut")
let { kindIcon } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { mkColoredGradientY } = require("%enlSqGlob/ui/gradients.nut")
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
  changeSoldierOrderByIdx, getCanTakeSlots
} = require("model/chooseSoldiersState.nut")
let {
  titleTxtColor, defTxtColor, accentColor, commonBorderRadius,
  colPart, colFull, columnGap, smallPadding, blinkBdColor,
  attentionTxtColor, hoverBgColor, panelBgColor
} = require("%enlSqGlob/ui/designConst.nut")


const PAGE_SIZE = 11
const NO_SOLDIER_SLOT_IDX = -1


let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let nameTxtStyle = { color = defTxtColor }.__update(fontLarge)
let headerTxtStyle = { color = defTxtColor }.__update(fontXLarge)
let titleTxtStyle = { color = titleTxtColor }.__update(fontXXLarge)


let sKindSize = colPart(0.4)
let sKindOffset = (columnGap * 0.3).tointeger()
let sKindBg = mkColoredGradientY(0xFF384560, 0xFF262940)


let headerHeight = colPart(2)
let reserveWidth = colFull(8)
let vehicleSquadWidth = colFull(6)
let reserveHeight = (soldierCardSize[1] + columnGap) * 3


let wrapParams = {
  width = reserveWidth
  hGap = columnGap
  vGap = columnGap
}

let curSoldierKind = Watched(soldierKindsList[0])
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

let reserveAvailableSize = Computed(@() reserveSoldiers.value
  .findindex(@(s)
    (soldiersStatuses.value?[s.guid] ?? NOT_FIT_CUR_SQUAD) & NOT_FIT_CUR_SQUAD
  ) ?? reserveSoldiers.value.len()
)

let hasEmptySlotsBlink = Computed(@()
  reserveSoldiers.value.slice(0, reserveAvailableSize.value)
    .findindex(@(s) unseenSoldiers.value?[s.guid] ?? false) != null
)


let soldiersPaginator = mkDotPaginator({
  id = "soldiers"
  pageWatch = curPageIdx
  dotSize = hdpx(15)
})


let selectedKindLine = {
  size = [flex(), smallPadding]
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_SOLID
  color = accentColor
}

let headerUi = {
  size = [flex(), headerHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = headerHeight
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


let specializationsUi = {
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    @() {
      watch = curSoldierKind
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc(getKindCfg(curSoldierKind.value).locId))
    }.__update(nameTxtStyle)
    {
      size = [reserveWidth, SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = soldierKindsList.map(@(kindId) watchElemState(@(sf) {
        watch = curSoldierKind
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_IMAGE
        image = sKindBg
        behavior = Behaviors.Button
        onClick = @() curSoldierKind(kindId)
        children = function() {
          let isSelected = curSoldierKind.value == kindId
          let iconColor = isSelected || (sf & S_HOVER) != 0 ? titleTxtColor : defTxtColor
          return {
            watch = curSoldierKind
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_CENTER
            children = [
              kindIcon(kindId, sKindSize, null, iconColor).__update({
                margin = [columnGap, 0]
              })
              isSelected ? selectedKindLine : null
            ]
          }
        }
      }))
    }
  ]
}


let xAnimDist = soldierCardSize[0] + columnGap
let yAnimDist = soldierCardSize[1] + columnGap
let yAnimBigDist = soldierCardSize[1] + columnGap * 2

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
  children = (unseenSoldiers.value?[soldierGuid] ?? false) ? unseenSignal(0.7) : null
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


let function mkEmptySlot(idx, tgtHighlight, hasBlink, hasVehicle) {
  let group = ElemGroup()
  let onDrop = @(data) changeSoldierOrderByIdx(data?.soldierIdx, idx)
  let isDropTarget = Computed(@() curDropTargIdx.value == idx
    && (curDropData.value?.soldierIdx ?? -1) >= maxSoldiersInBattle.value
  )
  let needHighlight = Computed(@() tgtHighlight.value?[idx] ?? false)
  let stateFlags = Watched(0)
  let moveData = mkMoveComputed(idx, idx, maxSoldiersInBattle, hasVehicle)
  return function() {
    let nest = {
      watch = [stateFlags, isDropTarget, needHighlight]
      group = group
      size = soldierCardSize
      key = $"emptySlot_{idx}"
      onDrop = onDrop
      dropData = null
    }
    let child = {
      key = $"empty_slot_{idx}{hasBlink}"
      size = flex()
      children = [
        mkEmptySoldierBadge(stateFlags.value, isDropTarget.value, hasBlink)
        needHighlight.value ? highlightBorder : null
      ]
    }
    let yGap = hasVehicle ? yAnimBigDist : yAnimDist
    return soldierDragAnim(moveData, idx, idx, "", stateFlags, nest, child, yGap)
  }
}


let mkSeatText = @(seatLocId) seatLocId == null ? null
  : {
      padding = [0, smallPadding]
      pos = [0, -(columnGap + smallPadding)]
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc(seatLocId))
    }.__update(defTxtStyle)


let mkSoldiersList = kwarg(@(
  soldiers, hasUnseen = false, idxOffset = Watched(0), isInReserve = false,
  tgtHighlight = Watched([]), slotsBlinkWatch = Watched(false), prevObject = null,
  hasVehicle = false, seats = null
) function() {
  let curWrapParams = wrapParams.__merge({
    width = hasVehicle ? vehicleSquadWidth : reserveWidth
    vGap = hasVehicle ? 2 * columnGap : columnGap
  })

  let hasBlink = slotsBlinkWatch.value
  let soldiersList = (prevObject == null ? [] : [prevObject])
    .extend(soldiers.value.map(function(s, idx) {
      let absIdx = (isInReserve ? s.absIdx : idx) + idxOffset.value
      if (s == null)
        return mkEmptySlot(absIdx, tgtHighlight, hasBlink, hasVehicle)

      let addObjects = hasUnseen ? [unseenMark(s.guid)] : []
      if (isInReserve && s.guid in curCanUnequipSoldiersList.value)
        addObjects.append(unseenSignal(0.9, attentionTxtColor, "th-large"))
      let inPageIdx = isInReserve ? s.inPageIdx : idx

      let seatLocId = seats?[idx].locName
      let colorScemeId = !isInReserve ? SQUAD_COLOR_SCHEME_ID : RESERVE_COLOR_SCHEME_ID
      let slotChild = mkSoldierSlot(s, absIdx, inPageIdx, tgtHighlight, hasVehicle, colorScemeId, addObjects)
      return hasVehicle
        ? { children = [ slotChild, mkSeatText(seatLocId) ]}
        : slotChild
    }))

  return {
    watch = [soldiers, idxOffset, tgtHighlight, slotsBlinkWatch, curCanUnequipSoldiersList]
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
      slotsBlinkWatch = hasEmptySlotsBlink
      hasVehicle = isVehicleSquad.value
      seats = curVehicleSeats.value
    })
  ]
}


let function autoMoveToReserve(squadSoldierIdx, sKind) {
  curSoldierKind(sKind)
  curPageIdx(0)
  soldierToReserveByIdx(squadSoldierIdx)
}


let reserveStateFlags = Watched(0)
let reserveUi = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = columnGap
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
              onClick = openSoldiersPurchase
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
    children = Bordered(loc(btnLocId), swapSoldierPlace, { hotkeys = [["^J:X"]] })
  })
}


let manageBlockUi = {
  size = flex()
  children = [
    {
      size = flex()
      flow = FLOW_VERTICAL
      gap = colPart(1)
      children = [
        reserveUi
        squadInfo()
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
        swapButtonUi
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
  watch = [safeAreaBorders, curArmy]
  size = flex()
  flow = FLOW_VERTICAL
  padding = safeAreaBorders.value
  behavior = Behaviors.MenuCameraControl
  children = [
    headerUi
    contentUi
  ]
}


let isOpened = keepref(Computed(@()
  soldiersSquad.value != null && selectedSoldier.value != null))

let open = function() {
  curSquadSoldierIdx(curSoldierIdx.value)
  curSoldierIdx(-1)
  sceneWithCameraAdd(chooseSoldiersScene, "soldiers")
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
