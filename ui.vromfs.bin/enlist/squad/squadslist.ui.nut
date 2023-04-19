from "%enlSqGlob/ui_library.nut" import *

let mkCurSquadsList = require("%enlSqGlob/ui/mkCurSquadsList.nut")
let { curArmy, curSquadId, setCurSquadId, setCurForcedSquadId,
  clearCurForcedSquadId, curChoosenSquads, curUnlockedSquads
} = require("%enlist/soldiers/model/state.nut")
let { allSquadsLevels } = require("%enlist/researches/researchesState.nut")
let { notChoosenPerkSquads } = require("%enlist/soldiers/model/soldierPerks.nut")
let { unseenSquadsWeaponry } = require("%enlist/soldiers/model/unseenWeaponry.nut")
let { unseenSquadsVehicle } = require("%enlist/vehicles/unseenVehicles.nut")
let { needSoldiersManageBySquad } = require("%enlist/soldiers/model/reserve.nut")
let { curUnseenUpgradesBySquad, isUpgradeUsed } = require("%enlist/soldiers/model/unseenUpgrades.nut")
let { mkAlertIcon, PERK_ALERT_SIGN, ITEM_ALERT_SIGN, REQ_MANAGE_SIGN
} = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { openChooseSquadsWnd } = require("%enlist/soldiers/model/chooseSquadsState.nut")

let mkManageAlert = @(guid) mkAlertIcon(REQ_MANAGE_SIGN, Computed(@()
  needSoldiersManageBySquad.value?[guid] ?? false))

let mkUnseenAlert = @(guid) mkAlertIcon(ITEM_ALERT_SIGN, Computed(function() {
  let count = (unseenSquadsWeaponry.value?[guid] ?? 0)
    + (unseenSquadsVehicle.value?[guid].len() ?? 0)
    + ((isUpgradeUsed.value ?? false) ? 0 : (curUnseenUpgradesBySquad.value?[guid] ?? 0))
  return count > 0
}))

let mkPerksAlert = @(squadId) mkAlertIcon(PERK_ALERT_SIGN, Computed(@()
  (notChoosenPerkSquads.value?[curArmy.value][squadId] ?? 0) > 0))



let mkSquadViewData = @(armyId, squad, levels) {
  onDoubleClick = @() openChooseSquadsWnd(armyId, squad.squadId)
  addChild = @() {
    flow = FLOW_HORIZONTAL
    hplace = ALIGN_RIGHT
    valign = ALIGN_CENTER
    children = [
      mkManageAlert(squad.guid)
      mkUnseenAlert(squad.guid)
      mkPerksAlert(squad.squadId)
    ]
  }
  level = levels?[squad.squadId] ?? 0
}

let curChoosenSquadsList = Computed(function() {
  let armyId = curArmy.value
  let levels = allSquadsLevels.value
  return (curChoosenSquads.value ?? [])
    .map(@(squad) squad.__merge( mkSquadViewData(armyId, squad, levels) ))
})

let curUnlockedSquadsList = Computed(function() {
  let armyId = curArmy.value
  let levels = allSquadsLevels.value
  return (curUnlockedSquads.value ?? [])
    .map(@(squad) squad.__merge( mkSquadViewData(armyId, squad, levels) ))
})

let choosenSquadsList = mkCurSquadsList({
  curSquadsList = curChoosenSquadsList
  curSquadId
  setCurSquadId
  onAttach = clearCurForcedSquadId
})

let unlockedSquadsList = mkCurSquadsList({
  curSquadsList = curUnlockedSquadsList
  curSquadId
  setCurSquadId = setCurForcedSquadId
  reserveIdx = Computed(@() curChoosenSquadsList.value.len())
})

return {
  choosenSquadsList
  unlockedSquadsList
}
