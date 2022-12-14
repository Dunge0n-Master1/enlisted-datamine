from "%enlSqGlob/ui_library.nut" import *

let { sub_txt, tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { bigPadding, activeTxtColor, noteTxtColor, slotBaseSize, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { note } = require("%enlSqGlob/ui/defcomps.nut")
let colorize = require("%ui/components/colorize.nut")
let blinkingIcon = require("%enlSqGlob/ui/blinkingIcon.nut")
let { curArmy, curSquadId, curSquad, curSquadParams, curVehicle, objInfoByGuid
} = require("model/state.nut")
let { perkLevelsGrid } = require("%enlist/meta/perks/perksExp.nut")
let { curArmyReserve, needSoldiersManageBySquad } = require("model/reserve.nut")
let { mkSoldiersDataList } = require("model/collectSoldierData.nut")
let { notChoosenPerkSoldiers, perksData } = require("model/soldierPerks.nut")
let { unseenSoldiersWeaponry } = require("model/unseenWeaponry.nut")
let { unseenSquadsVehicle } = require("%enlist/vehicles/unseenVehicles.nut")
let { curSoldierIdx, soldiersList, vehicleCapacity, curSoldierInfo,
  isSquadRented, buyRentedSquad
} = require("model/squadInfoState.nut")
let { curSquadSoldiersStatus } = require("model/readySoldiers.nut")
let mkMainSoldiersBlock = require("%enlSqGlob/ui/mkSoldiersList.nut")
let mkCurVehicle = require("%enlSqGlob/ui/mkCurVehicle.nut")
let {
  mkAlertIcon, PERK_ALERT_SIGN, ITEM_ALERT_SIGN, REQ_MANAGE_SIGN
} = require("%enlSqGlob/ui/soldiersUiComps.nut")
let squadHeader = require("components/squadHeader.nut")
let {
  hasSquadVehicle, selectVehParams
} = require("%enlist/vehicles/vehiclesListState.nut")
let { openChooseSoldiersWnd } = require("model/chooseSoldiersState.nut")
let { curUnseenUpgradesBySoldier, isUpgradeUsed } = require("model/unseenUpgrades.nut")
let { disabledSectionsData } = require("%enlist/mainMenu/disabledSections.nut")
let sClassesConfig = require("model/config/sClassesConfig.nut")
let mkVehicleSeats = require("%enlSqGlob/squad_vehicle_seats.nut")
let { vehDecorators } = require("%enlist/meta/profile.nut")
let { campPresentation, needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let { Flat } = require("%ui/components/textButton.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let { unseenSoldierShopItems } = require("%enlist/shop/soldiersPurchaseState.nut")
let { smallUnseenNoBlink } = require("%ui/components/unseenComps.nut")


let vehicleInfo = Computed(function() {
  let vehGuid = curVehicle.value
  if (vehGuid == null)
    return null

  let skin = (vehDecorators.value ?? {})
    .findvalue(@(d) d.cType == "vehCamouflage" && d.vehGuid == vehGuid)

  let override = skin == null ? {} : { skin }
  let vehicle = objInfoByGuid.value?[vehGuid]
  return vehicle == null ? null : vehicle.__merge(override)
})

let seatsOrderWatch = mkVehicleSeats(vehicleInfo)

let function openChooseVehicle(event) {
  if (event.button >= 0 && event.button <= 2)
    selectVehParams.mutate(@(params) params.__update({
      armyId = curArmy.value
      squadId = curSquadId.value
      isCustomMode = false
    }))
}

let mkAlertInfo = @(soldierInfo, _isSelected) {
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  children = [
    mkAlertIcon(ITEM_ALERT_SIGN, Computed(function() {
      let weapCount = unseenSoldiersWeaponry.value?[soldierInfo?.guid].len() ?? 0
      let upgrCount = (isUpgradeUsed.value ?? false) ? 0
        : (curUnseenUpgradesBySoldier.value?[soldierInfo?.guid] ?? 0)
      return weapCount + upgrCount > 0
    }))
    mkAlertIcon(PERK_ALERT_SIGN, Computed(@()
      (notChoosenPerkSoldiers.value?[soldierInfo?.guid] ?? 0) > 0
    ))
  ]
}

let allowedReserve = Computed(function() {
  let { maxClasses = null } = curSquadParams.value
  if (maxClasses == null)
    return 0
  let classesCfgV = sClassesConfig.value
  return curArmyReserve.value.reduce(function(res, s) {
    let kind = s?.sKind ?? classesCfgV?[s.sClass].kind
    return (maxClasses?[kind] ?? 0) > 0 ? res + 1 : res
  }, 0)
})

let function reserveAvailableBlock() {
  let res = { watch = allowedReserve }
  let count = allowedReserve.value
  if (count <= 0)
    return res
  return res.__update({
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    margin = [bigPadding * 2, 0,]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = loc("squad/reserveAvailable", { count, countColored = colorize(activeTxtColor, count) })
    color = noteTxtColor
  }.__update(tiny_txt))
}

let function manageSoldiersBtn() {
  let squad = curSquad.value
  let { guid = null, squadId = null } = squad
  let armyId = getLinkedArmyName(squad)
  let needSoldiersManage = needSoldiersManageBySquad.value?[guid] ?? false
  let hasUnseesSoldiers = unseenSoldierShopItems.value.len() > 0
  let res = { watch = [needSoldiersManageBySquad, curSquad,
    disabledSectionsData, unseenSoldierShopItems] }
  return disabledSectionsData.value?.SOLDIERS_MANAGING ?? false ? res
    : res.__update({
      size = [flex(), SIZE_TO_CONTENT]
      children = Flat(loc("soldier/manageButton"),
        function() {
          if (isSquadRented(squad)) {
            buyRentedSquad({ armyId, squadId, hasMsgBox = true })
            return
          }
          openChooseSoldiersWnd(curSquad.value?.guid, curSoldierInfo.value?.guid)
        }, {
          fgChild = {
            flow = FLOW_HORIZONTAL
            hplace = ALIGN_RIGHT
            vplace = ALIGN_TOP
            gap = smallPadding
            children = [
              needSoldiersManage ? mkAlertIcon(REQ_MANAGE_SIGN, Computed(@() true)) : null
              hasUnseesSoldiers
                ? smallUnseenNoBlink.__merge({ size = [hdpxi(15), hdpxi(15)], fontSize = hdpxi(14) })
                : null
            ]
          }
          onHover = @(on) setTooltip(on && needSoldiersManage ? loc("msg/canAddSoldierToSquad") : null)
          size = [flex(), SIZE_TO_CONTENT]
          fontSize = sub_txt.fontSize
          maxWidth = slotBaseSize[0]
          hplace = ALIGN_CENTER
          margin = 0
        }
      )
    })
}

let curSquadUnseenVehicleCount = Computed(@() unseenSquadsVehicle.value?[curSquad.value?.guid].len() ?? 0)
let function unseenVehiclesMark() {
  let res = { watch = curSquadUnseenVehicleCount }
  if (curSquadUnseenVehicleCount.value > 0)
    res.__update(blinkingIcon("arrow-up", curSquadUnseenVehicleCount.value))
  return res
}

let squadListWatch = mkSoldiersDataList(soldiersList)

let freeSeatsInVehicle = Computed(@() seatsOrderWatch.value.slice(squadListWatch.value.len()))

let freeSeatsBlock = @(freeSeats) freeSeats.len() == 0 ? null : {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    note(loc("vehicle_seats/freeSeats"))
    {
      rendObj = ROBJ_TEXTAREA
      size = [flex(), SIZE_TO_CONTENT]
      behavior = Behaviors.TextArea
      text = ", ".join(freeSeats.map(@(seat) loc(seat.locName)))
    }.__update(tiny_txt)
  ]
}

return function() {
  let res = { watch = [
    curSquadId, perksData, vehicleInfo, seatsOrderWatch, freeSeatsInVehicle,
    soldiersList, needFreemiumStatus, campPresentation
  ] }
  if (curSquadId.value == null)
    return res

  return res.__update({
    size = [SIZE_TO_CONTENT, flex()]
    children = mkMainSoldiersBlock({
      soldiersListWatch = squadListWatch
      expToLevelWatch = Computed(@() perkLevelsGrid.value?.expToLevel)
      hasVehicleWatch = Computed(@() hasSquadVehicle(curSquad.value))
      seatsOrderWatch
      curSoldierIdxWatch = curSoldierIdx
      soldiersReadyWatch = curSquadSoldiersStatus
      isFreemiumMode = needFreemiumStatus.value
      thresholdColor = campPresentation.value?.color
      curVehicleUi = mkCurVehicle({
        openChooseVehicle
        vehicleInfo
        topRightChild = unseenVehiclesMark
        soldiersList = squadListWatch
      })
      canDeselect = true
      addCardChild = mkAlertInfo
      headerBlock = squadHeader({
        curSquad = curSquad
        curSquadParams = curSquadParams
        soldiersList = squadListWatch
        vehicleCapacity = vehicleCapacity
        soldiersStatuses = curSquadSoldiersStatus
      })
      bottomObj = @() {
        size = [flex(), SIZE_TO_CONTENT]
        margin = vehicleInfo.value != null ? null : [bigPadding, 0, 0, 0]
        flow = FLOW_VERTICAL
        gap = smallPadding
        children = [
          freeSeatsBlock(freeSeatsInVehicle.value)
          reserveAvailableBlock
          manageSoldiersBtn
        ]
      }
    })
  })
}
