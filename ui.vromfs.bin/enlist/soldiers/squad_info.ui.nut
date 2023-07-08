from "%enlSqGlob/ui_library.nut" import *

let { Bordered } = require("%ui/components/txtButton.nut")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { bigPadding, smallPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { note } = require("%enlSqGlob/ui/defcomps.nut")
let blinkingIcon = require("%enlSqGlob/ui/blinkingIcon.nut")
let { curArmy, curSquadId, curSquad, curSquadParams, curVehicle, objInfoByGuid
} = require("model/state.nut")
let { perkLevelsGrid } = require("%enlist/meta/perks/perksExp.nut")
let { curArmyReserve, needSoldiersManageBySquad } = require("model/reserve.nut")
let { perksData } = require("model/soldierPerks.nut")
let { unseenSquadsVehicle } = require("%enlist/vehicles/unseenVehicles.nut")
let { vehicleCapacity, isSquadRented, buyRentedSquad } = require("model/squadInfoState.nut")
let { curSoldierInfo, curSoldiersDataList, curSoldierIdx } = require("%enlist/soldiers/model/curSoldiersState.nut")
let { curSquadSoldiersStatus } = require("model/readySoldiers.nut")
let mkMainSoldiersBlock = require("%enlSqGlob/ui/mkSoldiersList.nut")
let mkCurVehicle = require("%enlSqGlob/ui/mkCurVehicle.nut")
let {
  mkAlertIcon, REQ_MANAGE_SIGN
} = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { Notifiers, markNotifierSeen } = require("%enlist/tutorial/notifierTutorial.nut")
let squadHeader = require("components/squadHeader.nut")
let {
  hasSquadVehicle, selectVehParams
} = require("%enlist/vehicles/vehiclesListState.nut")
let { openChooseSoldiersWnd } = require("model/chooseSoldiersState.nut")
let { disabledSectionsData } = require("%enlist/mainMenu/disabledSections.nut")
let sClassesConfig = require("model/config/sClassesConfig.nut")
let mkVehicleSeats = require("%enlSqGlob/squad_vehicle_seats.nut")
let { vehDecorators } = require("%enlist/meta/profile.nut")
let { campPresentation, needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let { unseenSoldierShopItems } = require("%enlist/shop/soldiersPurchaseState.nut")
let { smallUnseenNoBlink } = require("%ui/components/unseenComps.nut")
let { mkAlertInfo } = require("model/soldiersState.nut")
let { curSection } = require("%enlist/mainMenu/sectionsState.nut")

let prevSoldier = mkWatched(persist, "prevSoldier", null)
let function mkSquadInfo() {
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


  let function manageSoldiersBtn() {
    let squad = curSquad.value
    let { guid = null, squadId = null } = squad
    let armyId = getLinkedArmyName(squad)
    let needSoldiersManage = needSoldiersManageBySquad.value?[guid] ?? false
    let hasUnseesSoldiers = unseenSoldierShopItems.value.len() > 0
    let res = {
      watch = [
        needSoldiersManageBySquad, curSquad, disabledSectionsData,
        unseenSoldierShopItems, allowedReserve
      ]
    }
    let count = allowedReserve.value
    let countText = count == 0
      ? loc("soldier/manageButton")
      : loc("soldier/manageButtonWithCount", { count })
    return disabledSectionsData.value?.SOLDIERS_MANAGING ?? false ? res
      : res.__update({
        size = [flex(), SIZE_TO_CONTENT]
        children = Bordered(countText,
          function() {
            if (isSquadRented(squad)) {
              buyRentedSquad({ armyId, squadId, hasMsgBox = true })
              return
            }
            markNotifierSeen(Notifiers.SOLDIER)
            openChooseSoldiersWnd(curSquad.value?.guid, curSoldierInfo.value?.guid)
          }, {
            fgChild = {
              flow = FLOW_HORIZONTAL
              hplace = ALIGN_RIGHT
              vplace = ALIGN_TOP
              gap = smallPadding
              padding = smallPadding
              children = [
                needSoldiersManage ? mkAlertIcon(REQ_MANAGE_SIGN, Computed(@() true)) : null
                hasUnseesSoldiers
                  ? smallUnseenNoBlink.__merge({ size = [hdpxi(15), hdpxi(15)], fontSize = hdpxi(14) })
                  : null
              ]
            }
            hotkeys = [["^J:X"]]
            onHover = @(on) setTooltip(on && needSoldiersManage ? loc("msg/canAddSoldierToSquad") : null)
            btnWidth = flex()
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

  let freeSeatsInVehicle = Computed(@() seatsOrderWatch.value.slice(curSoldiersDataList.value.len()))

  let freeSeatsBlock = @(freeSeats) freeSeats.len() == 0 ? null : {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      note(loc("vehicle_seats/freeSeats")).__update(sub_txt)
      {
        rendObj = ROBJ_TEXTAREA
        size = [flex(), SIZE_TO_CONTENT]
        behavior = Behaviors.TextArea
        halign = ALIGN_CENTER
        text = ", ".join(freeSeats.map(@(seat) loc(seat.locName)))
      }.__update(sub_txt)
    ]
  }

  return function() {
    let res = { watch = [
      curSquadId, perksData, vehicleInfo, seatsOrderWatch, freeSeatsInVehicle,
      curSoldiersDataList, needFreemiumStatus, campPresentation
    ] }
    if (curSquadId.value == null)
      return res

    return res.__update({
      size = [SIZE_TO_CONTENT, flex()]
      onDetach = function() {
        prevSoldier({squadId = curSquadId.value, soldier = curSoldierIdx.value})
        if (curSection.value != "SQUAD_SOLDIERS")
          curSoldierIdx(null)
      }
      onAttach = function() {
        if (curSoldierIdx.value == null) {
          let { squadId = null, soldier = 0 } = prevSoldier.value
          if (curSquadId.value == squadId) {
            curSoldierIdx(soldier ?? 0)
            prevSoldier(null)
          } else {
            curSoldierIdx(0)
          }
        }
      }
      children = mkMainSoldiersBlock({
        soldiersListWatch = curSoldiersDataList
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
          soldiersList = curSoldiersDataList
        })
        canDeselect = true
        addCardChild = mkAlertInfo
        headerBlock = squadHeader({
          curSquad = curSquad
          curSquadParams = curSquadParams
          soldiersList = curSoldiersDataList
          vehicleCapacity = vehicleCapacity
          soldiersStatuses = curSquadSoldiersStatus
        })
        bottomObj = {
          size = [flex(), SIZE_TO_CONTENT]
          margin = vehicleInfo.value != null ? null : [bigPadding, 0, 0, 0]
          flow = FLOW_VERTICAL
          gap = smallPadding
          children = [
            freeSeatsBlock(freeSeatsInVehicle.value)
            manageSoldiersBtn
          ]
        }
      })
    })
  }
}

return {mkSquadInfo}
