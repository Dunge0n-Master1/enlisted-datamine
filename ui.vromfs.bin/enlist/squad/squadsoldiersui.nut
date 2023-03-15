from "%enlSqGlob/ui_library.nut" import *

let { colPart, columnGap, bigPadding, smallPadding, defTxtColor, rightAppearanceAnim
} = require("%enlSqGlob/ui/designConst.nut")
let armySelectUi = require("%enlist/army/armySelectionUi.nut")
let squads_list = require("%enlist/squad/squadsList.ui.nut")
let squadInfo = require("%enlist/squad/squadInfo.nut")
let researchScene = require("%enlist/researches/researchScene.nut")
let mkSoldierDetailsUi = require("%enlist/soldiers/mkSoldierDetailsUi.nut")
let reqUpgradeMsgBox = require("%enlist/soldiers/researchUpgradeMsgBox.nut")

let { curSection } = require("%enlist/mainMenu/sectionsState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { ceil } = require("%sqstd/math.nut")
let { openChooseSoldiersWnd } = require("%enlist/soldiers/model/chooseSoldiersState.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { mkSoldierBadgeData } = require("%enlSqGlob/ui/soldiersComps.nut")
let { perksData } = require("%enlist/soldiers/model/soldierPerks.nut")
let { perkLevelsGrid } = require("%enlist/meta/perks/perksExp.nut")
let { campPresentation, needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let { mkVehicleBadge } = require("%enlSqGlob/ui/mkVehicleBadge.nut")
let { selectVehParams, curVehicleBadgeData, curVehicleSeats
} = require("%enlist/vehicles/vehiclesListState.nut")
let { curArmy, curSquad, curSquadId } = require("%enlist/soldiers/model/state.nut")
let { curSoldierInfo, curSoldiersDataList, curSoldierIdx
} = require("%enlist/soldiers/model/curSoldiersState.nut")
let { mkSoldierBadge, mkSoldierPresentation } = require("%enlSqGlob/ui/mkSoldierBadge.nut")


const COLUMNS = 3


let squadInfoHeight = colPart(3)
let soldierInfoOffcet = colPart(2.2)

let defTxtStyle = { color = defTxtColor }.__update(fontSmall)


let curSoldiersBadgeData = Computed(function() {
  let { expToLevel = [] } = perkLevelsGrid.value
  let color = needFreemiumStatus.value ? campPresentation.value?.color : null
  let perks = perksData.value
  return curSoldiersDataList.value.map(@(s) mkSoldierBadgeData(s, perks, expToLevel, color))
})


let squadInfoUi = @() {
  watch = curSquadId
  size = [flex(), squadInfoHeight]
  children = {
    key = $"squad_info_{curSquadId.value}"
    flow = FLOW_VERTICAL
    gap = columnGap
    children = [
      squadInfo()
      Bordered(loc("btn/squadUpgrades"), researchScene)
    ]
  }.__update(rightAppearanceAnim(0.1))
}


let function curSoldiersListUi() {
  let res = {
    watch = [curSoldierIdx, curSoldiersBadgeData, curVehicleSeats, curVehicleBadgeData]
  }

  let sList = curSoldiersBadgeData.value
  let sCount = sList.len()
  if (sCount == 0)
    return res

  let hasVehicle = curVehicleBadgeData.value != null
  let seats = curVehicleSeats.value
  let curIdx = curSoldierIdx.value
  let children = []
  let rowAmount = ceil(sCount.tofloat() / COLUMNS)
  for (local row = 0; row < rowAmount; row++) {
    let rowChildren = []
    for (local col = 0; col < COLUMNS; col++) {
      let idx = row * COLUMNS + col
      if (idx >= sCount)
        break

      let seatLocId = seats?[idx].locName
      let child = hasVehicle
        ? {
            children = [
              watchElemState(@(sf)
                mkSoldierBadge(idx, sList[idx], idx == curIdx, sf, @() curSoldierIdx(idx))
              )
              seatLocId == null ? null
                : {
                    padding = [0, smallPadding]
                    pos = [0, -(columnGap + bigPadding)]
                    rendObj = ROBJ_TEXT
                    text = utf8ToUpper(loc(seatLocId))
                  }.__update(defTxtStyle)
            ]
          }.__update(rightAppearanceAnim(0.05 * idx + 0.1))
        : watchElemState(@(sf)
            mkSoldierBadge(idx, sList[idx], idx == curIdx, sf, @() curSoldierIdx(idx))
              .__update(rightAppearanceAnim(0.05 * idx))
          )

      rowChildren.append(child)
    }
    children.append({
      flow = FLOW_HORIZONTAL
      gap = columnGap
      children = rowChildren
    })
  }

  return res.__update({
    flow = FLOW_VERTICAL
    gap = hasVehicle ? columnGap * 3 : columnGap
    children
    onAttach = @() curSoldierIdx(0)
    onDetach = @() curSoldierIdx(null)
  })
}


let function chooseVehicle(event) {
  if (event.button >= 0 && event.button <= 2)
    selectVehParams.mutate(@(params) params.__update({
      armyId = curArmy.value
      squadId = curSquadId.value
      isCustomMode = false
    }))
}


let function curVehicleUi() {
  let res = { watch = curVehicleBadgeData }
  if (curVehicleBadgeData.value == null)
    return res

  return res.__update({
    children = watchElemState(@(sf)
      mkVehicleBadge(curVehicleBadgeData.value, false, sf, chooseVehicle)
        .__update(rightAppearanceAnim(0))
    )
  })
}


let soldiersUi = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = columnGap
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = columnGap
      children = [
        curVehicleUi
        curSoldiersListUi
      ]
    }
    Bordered(loc("soldier/manageButton"), function() {
      openChooseSoldiersWnd(curSquad.value?.guid, curSoldierInfo.value?.guid)
    })
  ]
}


let squadsUi = {
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    armySelectUi
    squads_list
  ]
}


let mainBlockUi = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = colPart(1)
  children = [
    squadInfoUi
    soldiersUi
    squadsUi
  ]
}


let function curSoldierFullInfoUi() {
  let res = {
    watch = [curSoldierIdx, curSoldiersBadgeData]
  }

  let curIdx = curSoldierIdx.value
  if (curIdx == null)
    return res

  let soldier = curSoldiersBadgeData.value?[curIdx]
  if (soldier == null)
    return res

  return res.__update({
    size = SIZE_TO_CONTENT
    margin = [soldierInfoOffcet, 0]
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    children = mkSoldierPresentation(soldier)
  })
}


let function resetSoldierChoise(_) {
  if (curSection.value == "SQUAD_SOLDIERS")
    curSoldierIdx(0)
}

foreach(v in [curSquadId, curArmy, curSection])
  v.subscribe(resetSoldierChoise)


return {
  size = flex()
  margin = [colPart(1.8), 0, 0, 0]
  children = [
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = columnGap
      children = [
        mainBlockUi
        mkSoldierDetailsUi({
          soldierWatch = curSoldierInfo
          onResearchClickCb = reqUpgradeMsgBox
        })
      ]
    }
    curSoldierFullInfoUi
  ]
}
