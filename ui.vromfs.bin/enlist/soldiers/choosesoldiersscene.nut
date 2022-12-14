from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { ceil } = require("%sqstd/math.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let unseenSignal = require("%ui/components/unseenSignal.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(50) })
let { showMessageWithContent, showMsgbox } = require("%enlist/components/msgbox.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { bigPadding, blurBgColor, blurBgFillColor, smallPadding,
  activeBgColor, defBgColor, slotBaseSize, scrollbarParams, listCtors,
  msgHighlightedTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { nameColor, txtDisabledColor } = listCtors
let { READY, TOO_MUCH_CLASS, NOT_FIT_CUR_SQUAD, NOT_READY_BY_EQUIP
} = require("%enlSqGlob/readyStatus.nut")
let { txt, note, noteTextArea } = require("%enlSqGlob/ui/defcomps.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let { FAButton, SmallFlat, Flat } = require("%ui/components/textButton.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { squadSoldiers, reserveSoldiers, selectedSoldierGuid, selectedSoldier, soldiersStatuses,
  applySoldierManage, changeSoldierOrderByIdx, maxSoldiersInBattle, soldiersSquadParams,
  moveCurSoldier, soldierToReserveByIdx, curSoldierToReserve, curSoldierToSquad, getCanTakeSlots,
  dismissSoldier, isDismissInProgress, soldiersSquad, curSquadSoldierIdx, closeChooseSoldiersWnd,
  isPurchaseWndOpend
} = require("model/chooseSoldiersState.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { getLinkedArmyName, getLinkedSquadGuid
} = require("%enlSqGlob/ui/metalink.nut")
let { curArmyReserve, curArmyReserveCapacity
} = require("model/reserve.nut")
let { gameProfile } = require("model/config/gameProfile.nut")
let { hasPremium } = require("%enlist/currency/premium.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let mkSoldierInfo = require("mkSoldierInfo.nut")
let squadHeader = require("components/squadHeader.nut")
let mkSoldierCard = require("%enlSqGlob/ui/mkSoldierCard.nut")
let mkValueWithBonus = require("%enlist/components/valueWithBonus.nut")
let mkHeader = require("%enlist/components/mkHeader.nut")
let { curSoldierIdx } = require("model/squadInfoState.nut")
let { unseenSoldiers, markSoldierSeen } = require("model/unseenSoldiers.nut")
let gotoResearchUpgradeMsgBox = require("researchUpgradeMsgBox.nut")
let { curCanUnequipSoldiersList } = require("model/selectItemState.nut")
let { RETIRE_ORDER, retireReturn } = require("model/config/soldierRetireConfig.nut")
let { debounce } = require("%sqstd/timers.nut")
let { freemiumWidget } = require("%enlSqGlob/ui/mkPromoWidget.nut")
let { needFreemiumStatus, curUpgradeDiscount
} = require("%enlist/campaigns/campaignConfig.nut")
let { perkLevelsGrid } = require("%enlist/meta/perks/perksExp.nut")
let soldiersPurchaseWnd = require("%enlist/shop/soldiersPurchaseWnd.nut")
let { unseenSoldierShopItems } = require("%enlist/shop/soldiersPurchaseState.nut")
let { smallUnseenNoBlink } = require("%ui/components/unseenComps.nut")


const NO_SOLDIER_SLOT_IDX = -1

let slotWithPadding = [slotBaseSize[0], slotBaseSize[1] + bigPadding]

let reserveAvailableSize = Computed(@() reserveSoldiers.value.findindex(@(s)
    (soldiersStatuses.value?[s.guid] ?? NOT_FIT_CUR_SQUAD) & NOT_FIT_CUR_SQUAD)
  ?? reserveSoldiers.value.len())

let curDropData = Watched(null)
let curDropTgtIdx = Watched(NO_SOLDIER_SLOT_IDX)
let curDropTgtIdxDebounced = Watched(NO_SOLDIER_SLOT_IDX)
curDropData.subscribe(@(_) curDropTgtIdx(NO_SOLDIER_SLOT_IDX))
curDropTgtIdx.subscribe(debounce(@(_) curDropTgtIdxDebounced(curDropTgtIdx.value), 0.01))

let moveParams = Computed(function() {
  local watch = null
  local idx = null
  let guid = selectedSoldierGuid.value
  if (guid != null)
    foreach (w in [squadSoldiers, reserveSoldiers]) {
      idx = w.value.findindex(@(s) s?.guid == guid)
      if (idx != null) {
        watch = w
        break
      }
    }

  let listSize = watch == squadSoldiers ? watch.value.len()
    : watch == reserveSoldiers ? reserveAvailableSize.value
    : 0
  let isAvailable = watch != null && idx < listSize
  return {
    canUp = isAvailable && idx > 0
    canDown = isAvailable && idx < listSize - 1
    canRemove = watch == squadSoldiers
    canTake = watch == reserveSoldiers
    takeAvailable = isAvailable && soldiersStatuses.value?[guid] == READY
      && squadSoldiers.value.findindex(@(s) s == null) != null
  }
})

let soldierToTake = Computed(function() {
  let dropIdx = curDropData.value?.soldierIdx
  if (dropIdx != null)
    return reserveSoldiers.value?[dropIdx - maxSoldiersInBattle.value]
  let selGuid = selectedSoldierGuid.value
  return selGuid == null ? null : reserveSoldiers.value.findvalue(@(s) s?.guid == selGuid)
})

let slotsHighlight = Computed(function() {
  let soldier = soldierToTake.value
  return soldier == null ? [] : getCanTakeSlots(soldier, squadSoldiers.value)
})

let commonLimit = Computed(@() curArmyReserveCapacity.value
  - (hasPremium.value ? (gameProfile.value?.premiumBonuses.soldiersReserve ?? 0) : 0))
let premiumLimit = Computed(@() hasPremium.value ? curArmyReserveCapacity.value : null)
let function reserveCountBlock() {
  let res = { watch = [reserveSoldiers] }
  let reserveCount = reserveSoldiers.value.len()
  if (reserveCount <= 0)
    return res

  return res.__update({
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(5)
    margin = [0, 0, bigPadding, 0]
    children = [
      note(loc("squad/reserveAmount", { count = reserveCount }))
      mkValueWithBonus(commonLimit, premiumLimit)
    ]
  })
}

let buttonOk = Flat(loc("Ok"), @() applySoldierManage(closeChooseSoldiersWnd),
  { margin = 0, hplace = ALIGN_RIGHT })

let getMoveDirSameList = @(idx, dropIdx, targetIdx)
  dropIdx < idx && targetIdx >= idx ? -1
    : dropIdx > idx && targetIdx <= idx ? 1
    : 0

let mkMoveDirComputed = @(idx, fixedSlotsWatch) Computed(function() {
  let dropIdx = curDropData.value?.soldierIdx ?? -1
  let targetIdx = curDropTgtIdxDebounced.value
  if (targetIdx < 0 || dropIdx < 0 || dropIdx == idx)
    return 0
  let fixedSlots = fixedSlotsWatch.value
  if (idx < fixedSlots)
    return dropIdx < fixedSlots && targetIdx < fixedSlots ? getMoveDirSameList(idx, dropIdx, targetIdx) : 0
  return dropIdx >= fixedSlots && targetIdx >= fixedSlots ? getMoveDirSameList(idx, dropIdx, targetIdx)
    : dropIdx < fixedSlots && targetIdx >= fixedSlots && targetIdx <= idx ? 1
    : 0
})

let soldierDragAnim = @(moveDir, idx, stateFlags, content, chContent)
  content.__merge({
    behavior = Behaviors.DragAndDrop
    canDrop = @(data) data?.dragid == "soldier"
    dropData = "dropData" in content ? content.dropData : { soldierIdx = idx, dragid = "soldier" }
    onDragMode = @(on, data) curDropData(on ? data : null)
    onElemState = function(sf) {
      stateFlags(sf)
      if (!curDropData.value || curDropData.value.soldierIdx == idx)
        return
      if (sf & S_ACTIVE)
        curDropTgtIdx(idx)
      else if (curDropTgtIdx.value == idx)
        curDropTgtIdx(NO_SOLDIER_SLOT_IDX)
    }
    transform = {}
    children = chContent.__merge({
      transform = {}
      transitions = [{ prop = AnimProp.translate, duration = 0.3, easing = OutQuad }]
      behavior = Behaviors.RtPropUpdate
      rtAlwaysUpdate = true
      update = @() {
        transform = { translate = [0, moveDir.value * slotWithPadding[1]] }
      }
    })
  })

let highlightBorder = {
  size = flex()
  rendObj = ROBJ_FRAME
  borderWidth = hdpx(1)
  borderColor = 0xFFFFFFFF
}

let function mkEmptySlot(idx, tgtHighlight, hasBlink) {
  let group = ElemGroup()
  let onDrop = @(data) changeSoldierOrderByIdx(data?.soldierIdx, idx)
  let isDropTarget = Computed(@() curDropTgtIdx.value == idx
    && (curDropData.value?.soldierIdx ?? -1) >= maxSoldiersInBattle.value)
  let needHighlight = Computed(@() tgtHighlight.value?[idx] ?? false)
  let stateFlags = Watched(0)
  let moveDir = mkMoveDirComputed(idx, maxSoldiersInBattle)

  return function() {
    let content = {
      watch = [stateFlags, isDropTarget, needHighlight]
      group = group
      size = slotWithPadding
      key = $"emptySlot_{idx}"
      onDrop = onDrop
      dropData = null
      onClick = @() selectedSoldierGuid(null)
    }

    let chContent = {
      size = flex()
      padding = [0, 0, bigPadding, 0]
      children = {
        key = $"empty_slot_{idx}{hasBlink}"
        size = flex()
        rendObj = ROBJ_SOLID
        color = isDropTarget.value ? activeBgColor : defBgColor
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          {
            rendObj = ROBJ_TEXT
            text = loc("squad/soldierFreeSlot")
            color = hasBlink
              ? nameColor(0, isDropTarget.value)
              : txtDisabledColor(0, isDropTarget.value)
            animations = hasBlink
              ? [{
                  prop = AnimProp.opacity, from = 0.4, to = 1, duration = 1,
                  play = true, loop = true, easing = Blink
                }]
              : null
          }.__update(sub_txt)
          needHighlight.value ? highlightBorder : null
        ]
      }
    }

    return soldierDragAnim(moveDir, idx, stateFlags, content, chContent)
  }
}

let unseenMark = @(soldierGuid) @() {
  watch = unseenSoldiers
  hplace = ALIGN_RIGHT
  children = (unseenSoldiers.value?[soldierGuid] ?? false) ? unseenSignal(0.7) : null
}

let function mkSoldierSlot(soldier, idx, tgtHighlight, addObjects) {
  let isSelectedWatch = Computed(@() selectedSoldierGuid.value == soldier.guid)
  let isDropTarget = Computed(@() idx < maxSoldiersInBattle.value && curDropTgtIdx.value == idx
    && (curDropData.value?.soldierIdx ?? -1) >= maxSoldiersInBattle.value)
  let needHighlight = Computed(@() tgtHighlight.value?[idx] ?? false)
  let moveDir = mkMoveDirComputed(idx, maxSoldiersInBattle)

  let soldierStatus = Computed(@() soldiersStatuses.value?[soldier.guid] ?? READY)
  let onDrop = @(data) changeSoldierOrderByIdx(data?.soldierIdx, idx)
  let stateFlags = Watched(0)
  let group = ElemGroup()
  return function mkSoldierSlotImpl() {
    let sf = stateFlags.value
    let status = soldierStatus.value
    let isSelected = isSelectedWatch.value

    let content = {
      watch = [stateFlags, soldierStatus, isSelectedWatch, isDropTarget, needHighlight]
      xmbNode = XmbNode()
      group = group
      size = slotWithPadding
      key = $"slot{soldier?.guid}{idx}"
      onDrop = onDrop
      onClick = @() selectedSoldierGuid(soldier.guid == selectedSoldierGuid.value ? null : soldier.guid)
      onHover = function(on) {
        hoverHoldAction("markSeenSoldier",
          { armyId = curArmy.value, guid = soldier?.guid },
          @(v) markSoldierSeen(v.armyId, v.guid))(on)
      }
    }

    let chContent = {
      padding = [0, bigPadding, 0, 0]
      children = @() {
        watch = [needFreemiumStatus, perkLevelsGrid]
        children = [
          mkSoldierCard({
            soldierInfo = soldier
            expToLevel = perkLevelsGrid.value?.expToLevel
            size = slotBaseSize
            group = group
            sf = sf
            isSelected = isSelected || isDropTarget.value
            isFaded = status != READY
            isClassRestricted = status & TOO_MUCH_CLASS
            hasAlertStyle = status & NOT_FIT_CUR_SQUAD
            hasWeaponWarning = (status & NOT_READY_BY_EQUIP) != 0
            isFreemiumMode = needFreemiumStatus.value
          })
          needHighlight.value ? highlightBorder : null
          {
            hplace = ALIGN_RIGHT
            flow = FLOW_HORIZONTAL
            children = addObjects
          }
        ]
      }
    }

    return status & NOT_FIT_CUR_SQUAD
      ? content.__update({
          behavior = Behaviors.Button
          onElemState = @(sf) stateFlags(sf)
          transform = {}
          children = chContent
        })
      : soldierDragAnim(moveDir, idx, stateFlags, content, chContent)
  }
}

let mkSoldiersList = kwarg(@(soldiers, hasUnseen = false, idxOffset = Watched(0),
  tgtHighlight = Watched([]), slotsBlinkWatch = Watched(false), isInReserve = false
) @() {
  watch = [soldiers, idxOffset, tgtHighlight, slotsBlinkWatch, curCanUnequipSoldiersList]
  size = [slotBaseSize[0], SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  behavior = Behaviors.Button
  onClick = @() selectedSoldierGuid(null)
  children = soldiers.value.map(function(s, idx) {
    let addObjects = hasUnseen ? [unseenMark(s.guid)] : []
    if (isInReserve && s.guid in curCanUnequipSoldiersList.value)
      addObjects.append(unseenSignal(0.9, msgHighlightedTxtColor, "th-large"))
    return s == null
      ? mkEmptySlot(idx + idxOffset.value, tgtHighlight, slotsBlinkWatch.value)
      : mkSoldierSlot(s, idx + idxOffset.value, tgtHighlight, addObjects)
  })
})

let labelUnableToAdd = @(listWatch) function() {
  let res = { watch = listWatch }
  if (listWatch.value.len() == 0)
    return res
  return res.__update({
    margin = [0, 0, smallPadding, 0]
    children = note(loc("squad/unableAddSoldier"))
  })
}

let bg = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  padding = bigPadding
  flow = FLOW_VERTICAL
}

let faBtnParams = {
  borderWidth = 0
  borderRadius = 0
}
let faBtnVisualDisabled = faBtnParams.__merge({
  style = {
    BgNormal = Color(20, 20, 20, 170)
    BdNormal = Color(20, 20, 20, 20)
    TextNormal = Color(0, 0, 0, 100)
  }
})

let function manageBlock() {
  let { canUp, canDown, canTake, canRemove, takeAvailable } = moveParams.value
  return {
    watch = moveParams
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    halign = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = [
      FAButton("arrow-up", @() moveCurSoldier(-1), faBtnParams.__merge({
        key = $"moveUp_{canUp}"
        isEnabled = canUp
        hotkeys = canUp ? [["^J:Y", { description = loc("Move Up") }]] : null
      })),
      FAButton("arrow-down", @() moveCurSoldier(1), faBtnParams.__merge({
        key = $"moveDown_{canDown}"
        isEnabled = canDown
        hotkeys = canDown ? [["^J:X", { description = loc("Move Down") }]] : null
      })),
      canTake
        ? FAButton("arrow-left", curSoldierToSquad,
            (takeAvailable ? faBtnParams : faBtnVisualDisabled).__merge({
              key = $"moveToSquad_{takeAvailable}"
              hotkeys = [["^J:LB", { description = loc("TakeToBattle") }]]
            }))
        : FAButton("arrow-right", curSoldierToReserve, faBtnParams.__merge({
            key = $"moveToReserve_{canRemove}"
            isEnabled = canRemove
            hotkeys = canRemove ? [["^J:RB", { description = loc("MoveToReserve") }]] : null
          })),
      { size = flex() },
      buttonOk
    ]
  }
}

let soldiersManageHint = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    noteTextArea(loc("soldier/manageHeader"))
    noteTextArea(loc("soldier/maxSoldiers"))
  ]
}

let gapBlock = { size = [flex(), bigPadding] }

let hasEmptySlotsBlink = Computed(function() {
  return reserveSoldiers.value.slice(0, reserveAvailableSize.value)
    .findindex(@(s) unseenSoldiers.value?[s.guid] ?? false) != null
})

let squadList = bg.__merge({
  size = [slotWithPadding[0] + 2 * bigPadding, SIZE_TO_CONTENT]
  children = [
    squadHeader({
      curSquad = soldiersSquad
      curSquadParams = soldiersSquadParams
      soldiersList = Computed(@() squadSoldiers.value.filter(@(s) s != null))
      soldiersStatuses = soldiersStatuses
      vehicleCapacity = Watched(0)
    })
    note(loc("menu/soldier"))
    mkSoldiersList({
      soldiers = squadSoldiers
      hasUnseen = false
      idxOffset = Watched(0)
      tgtHighlight = slotsHighlight
      slotsBlinkWatch = hasEmptySlotsBlink
    })
    soldiersManageHint
    gapBlock
    manageBlock
  ]
})

let getSoldiersBlock = @() {
  watch = unseenSoldierShopItems
  flow = FLOW_VERTICAL
  size = [flex(), SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  margin = [bigPadding,0,0,0]
  children = [
    noteTextArea({
      text = loc("squad/getMoreSoldiers")
    }).__update(sub_txt, {halign = ALIGN_CENTER})
    Flat(loc("soldiers/purchaseSoldier"), @() isPurchaseWndOpend(true),
      unseenSoldierShopItems.value.len() <= 0 ? {} : {
        fgChild = smallUnseenNoBlink
        halign = ALIGN_RIGHT
        valign = ALIGN_TOP
      } )
  ]
}

let availList = Computed(@() reserveSoldiers.value.slice(0, reserveAvailableSize.value))
let blockedList = Computed(@() reserveSoldiers.value.slice(reserveAvailableSize.value))
let function reserveList() {
  if (reserveSoldiers.value.len() == 0)
    return bg.__merge({
      watch = reserveSoldiers
      size = [slotWithPadding[0] + 2 * bigPadding, flex()]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      behavior = Behaviors.Button // only to attract cursor on dirpad navigation
      children = getSoldiersBlock
    })

  return bg.__merge({
    watch = [ reserveSoldiers, curArmyReserveCapacity ]
    size = [slotWithPadding[0] + 2 * bigPadding, flex()]
    children = [
      reserveCountBlock
      makeVertScroll({
        xmbNode = XmbContainer({
          canFocus = @() false
          scrollSpeed = 5.0
        })
        flow = FLOW_VERTICAL
        children = [
          mkSoldiersList({
            soldiers = availList
            hasUnseen = true
            idxOffset = maxSoldiersInBattle
            isInReserve = true
          })
          labelUnableToAdd(blockedList)
          mkSoldiersList({
            soldiers = blockedList
            hasUnseen = false
            idxOffset = Computed(@() maxSoldiersInBattle.value + reserveAvailableSize.value)
            isInReserve = true
          })
        ]
      }, scrollbarParams)
      reserveSoldiers.value.len() >= curArmyReserveCapacity.value ? null : getSoldiersBlock
    ]
  })
}

let mkDismissWarning = @(armyId, guid, count) showMessageWithContent({
  content = {
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    gap = hdpx(40)
    children = [
      {
        size = [sw(35), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("retireSoldier/title")
      }.__update(h2_txt)
      {
        size = [sw(50), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("retireSoldier/desc")
      }.__update(body_txt)
      {
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        children = [
          txt(loc("retireSoldier/currencyWillReturn")).__update(sub_txt)
          mkItemCurrency({ currencyTpl = RETIRE_ORDER, count })
        ]
      }
    ]
  }
  buttons = [
    {
      text = loc("Yes")
      action = @() dismissSoldier(armyId, guid)
      isCurrent = true
    }
    {
      text = loc("Cancel"), isCancel = true
    }
  ]
})

let mkApplyChangesWarning = @() showMsgbox({
  text = loc("msg/applySoldiersChangesRequired")
  buttons = [
    { text = loc("Apply"),
      action = @() applySoldierManage()
      isCurrent = true
    }
    { text = loc("Cancel")
      isCancel = true
    }
  ]
})


let function mkDismissBtn(soldier) {
  if (soldier == null)
    return null

  let { guid, sClass, tier, heroTpl } = soldier
  let armyId = getLinkedArmyName(soldier)
  return function() {
    let res = { watch = [
      curArmyReserve, curArmyReserveCapacity, isDismissInProgress,
      retireReturn, reserveSoldiers
    ]}

    if (reserveSoldiers.value.findindex(@(s) s.guid == guid ) == null)
      return res

    local retireCount = retireReturn.value?[sClass][tier] ?? 0
    if (retireCount == 0
        || curArmyReserveCapacity.value == 0
        || curArmyReserve.value.len() == 0
        || heroTpl != "")
      return res

    let retireCountMult = 1.0 - curUpgradeDiscount.value
    retireCount = ceil(retireCount * retireCountMult).tointeger()
    return res.__update({
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_RIGHT
      children = [
        isDismissInProgress.value
          ? spinner
          : SmallFlat(loc("btn/removeSoldier"),
              @() getLinkedSquadGuid(soldier) != null
                ? mkApplyChangesWarning()
                : mkDismissWarning(armyId, guid, retireCount),
              {
                margin = 0
                padding = [bigPadding, 2 * bigPadding]
              })
      ]
    })
  }
}

let soldiersContent = {
  size = flex()
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    squadList
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      behavior = Behaviors.DragAndDrop
      onDrop = @(data) soldierToReserveByIdx(data?.soldierIdx)
      canDrop = @(data) data?.soldierIdx != null && data.soldierIdx < maxSoldiersInBattle.value
      skipDirPadNav = true
      children = [
        reserveList
        mkSoldierInfo({
          soldierInfoWatch = selectedSoldier
          mkDismissBtn = mkDismissBtn
          onResearchClickCb = gotoResearchUpgradeMsgBox
        })
      ]
    }
    @() {
      watch = needFreemiumStatus
      children = !needFreemiumStatus.value ? null : freemiumWidget("soldiers_manage")
    }
  ]
}

let chooseSoldiersScene = @() {
  watch = [safeAreaBorders, isPurchaseWndOpend]
  size = [sw(100), sh(100)]
  behavior = Behaviors.MenuCameraControl
  children = [
    @() {
      watch = curArmy
      size = flex()
      flow = FLOW_VERTICAL
      padding = safeAreaBorders.value
      children = [
        mkHeader({
          armyId = curArmy.value
          textLocId = "soldier/manageTitle"
          closeButton = closeBtnBase({
            onClick = @() applySoldierManage(closeChooseSoldiersWnd)
          })
        })
        {
          size = flex()
          flow = FLOW_VERTICAL
          children = soldiersContent
        }
      ]
    }
    isPurchaseWndOpend.value
      ? soldiersPurchaseWnd(@() isPurchaseWndOpend(false))
      : null
  ]
}

let isOpened = keepref(Computed(@() soldiersSquad.value != null))
let open = function() {
  curSquadSoldierIdx(curSoldierIdx.value)
  curSoldierIdx(-1)
  sceneWithCameraAdd(chooseSoldiersScene, "soldiers")
}

if (isOpened.value)
  open()

isOpened.subscribe(function(v) {
  if (v == true)
    open()
  else
    sceneWithCameraRemove(chooseSoldiersScene)
})
