from "%enlSqGlob/ui_library.nut" import *

let cursors = require("%ui/style/cursors.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let STATUS = require("%enlSqGlob/readyStatus.nut")
let { slotBaseSize, smallPadding, bigPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { note } = require("%enlSqGlob/ui/defcomps.nut")
let mkSoldierCard = require("%enlSqGlob/ui/mkSoldierCard.nut")

let mkSoldierSlot = kwarg(function(soldier, idx, curSoldierIdxWatch,
  canDeselect = true, addCardChild = null, isFreemiumMode = false, thresholdColor = 0,
  soldiersReadyWatch = Watched(null), defSoldierGuidWatch = Watched(null),
  seatsOrderWatch = Watched([]), expToLevelWatch = Watched([])
) {
  let isSelectedWatch = Computed(function() {
    if (curSoldierIdxWatch.value == idx)
      return true
    let sGuid = defSoldierGuidWatch.value
    return sGuid != null && soldier.guid == sGuid
  })

  let group = ElemGroup()
  return watchElemState(function(sf) {
    let soldiersReadyInfo = soldiersReadyWatch.value
    let soldierStatus = soldiersReadyInfo?[soldier.guid] ?? STATUS.READY
    let hasWeaponWarning = (soldierStatus & STATUS.NOT_READY_BY_EQUIP) != 0
    let isFaded = soldierStatus != STATUS.READY
    let outOfVehicSize = (soldierStatus & STATUS.OUT_OF_VEHICLE) != 0
    let seatInfo = seatsOrderWatch.value?[idx]

    let chContent = {
      xmbNode = XmbNode()
      vplace = ALIGN_CENTER
      children = mkSoldierCard({
        soldierInfo = soldier
        expToLevel = expToLevelWatch.value
        size = slotBaseSize
        group = group
        sf = sf
        isSelected = isSelectedWatch.value
        isFaded = isFaded
        isClassRestricted = (soldierStatus & STATUS.TOO_MUCH_CLASS) != 0
        hasAlertStyle = hasWeaponWarning
        hasWeaponWarning = hasWeaponWarning
        addChild = addCardChild
        isFreemiumMode = isFreemiumMode
        thresholdColor
      })
    }

    return {
      watch = [soldiersReadyWatch, isSelectedWatch, seatsOrderWatch, expToLevelWatch]
      group = group
      key = $"slot{soldier?.guid}{idx}"
      flow = FLOW_VERTICAL
      behavior = Behaviors.Button
      onHover = outOfVehicSize
        ? @(on) cursors.setTooltip(on ? loc("soldier/status/outOfVehicleCrewSize") : null)
        : null
      onClick = function() {
        if (soldier?.canSpawn ?? true) {
          defSoldierGuidWatch(null)
          curSoldierIdxWatch(canDeselect && idx == curSoldierIdxWatch.value ? null : idx)
        }
      }
      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
        active = "ui/enlist/button_action"
      }
      children = [
        seatInfo ? note(loc(seatInfo.locName)) : null
        chContent
      ]
    }
  })
})

let function mkSoldiersBlock(params) {
  let {
    soldiersListWatch, curSoldierIdxWatch, seatsOrderWatch = Watched([]), addCardChild = null
  } = params
  return function() {
    let unitsInVehicle = seatsOrderWatch.value.len()
    let soldiers = soldiersListWatch.value
    let children = soldiers.slice(0, unitsInVehicle).map(@(soldier, idx)
      mkSoldierSlot(params.__merge({ soldier, idx, addCardChild }), KWARG_NON_STRICT))

    if (unitsInVehicle < soldiers.len()) {
      children.extend(soldiers.slice(unitsInVehicle).map(@(soldier, idx)
        mkSoldierSlot(params.__merge({ soldier, idx = idx + unitsInVehicle, addCardChild }),
          KWARG_NON_STRICT)))
    }

    return {
      watch = [soldiersListWatch, curSoldierIdxWatch, seatsOrderWatch]
      size = [slotBaseSize[0], SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      behavior = Behaviors.Button
      gap = bigPadding
      onClick = function() {
        if (params?.canDeselect ?? false)
          curSoldierIdxWatch(null)
      }
      children = children
    }
  }
}

let mkVehicleBlock = @(hasVehicleWatch, curVehicleUi) function() {
  let res = { watch = hasVehicleWatch }
  if (!hasVehicleWatch.value)
    return res

  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    margin = [0, 0, bigPadding, 0]
    children = {
      flow = FLOW_VERTICAL
      gap = smallPadding
      size = [flex(), SIZE_TO_CONTENT]
      children = curVehicleUi
    }
  })
}

let mkMainSoldiersBlock = @(params) {
  size = [slotBaseSize[0], flex()]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    params?.headerBlock
    {
      size = flex()
      flow = FLOW_VERTICAL
      children = [
        "hasVehicleWatch" not in params ? null
          : mkVehicleBlock(params.hasVehicleWatch, params.curVehicleUi)
        makeVertScroll(mkSoldiersBlock(params), {
          size = [SIZE_TO_CONTENT, flex()], styling = thinStyle
        })
      ]
    }
    params?.bottomObj
  ]
}

return mkMainSoldiersBlock
