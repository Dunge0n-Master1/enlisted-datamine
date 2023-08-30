from "%enlSqGlob/ui_library.nut" import *

let { soldiersStatuses, READY, OUT_OF_VEHICLE } = require("%enlist/soldiers/model/readySoldiers.nut")
let {
  chosenSquadsByArmy, soldiersBySquad, curArmiesList, curArmy, selectArmy, setCurSquadId
} = require("%enlist/soldiers/model/state.nut")
let { matchRandomTeam } = require("%enlist/quickMatch.nut")
let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let { myExtSquadData } = require("%enlist/squad/squadState.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")


let showNotReadySquads = Watched(null)
let armiesForBattle = Computed(@() matchRandomTeam.value ? curArmiesList.value : [curArmy.value])

let function calcSquadReady(squad, soldiers, statuses) {
  let unreadySoldiers = soldiers.filter(@(s) statuses?[s.guid] != null && statuses[s.guid] != READY
    && !(statuses[s.guid] & OUT_OF_VEHICLE))
  let notReadyCount = unreadySoldiers.len()
  let minCount = squad.size
  let canBattle = (soldiers.len() - notReadyCount) >= minCount
  let unreadyMsgs = []
  if (!canBattle)
    unreadyMsgs.append(loc("notReadySquad/notEnoughSoldiers", { minCount }))
  if (unreadySoldiers.len() > 0)
    unreadyMsgs.append(loc("notReadySquad/hasNotReadySoldiers", { notReadyCount }))
  return { isReady = unreadyMsgs.len() == 0, canBattle, unreadySoldiers, unreadyMsgs, squad }
}

let function getNotReadySquadsInfo(armiesList, chosenSquads, soldiers, statuses) {
  let res = []
  foreach (armyId in armiesList)
    foreach (squad in chosenSquads?[armyId] ?? []) {
      let readyData = calcSquadReady(squad, soldiers?[squad.guid] ?? [], statuses)
      if (!readyData.isReady)
        res.append(readyData)
    }
  return res
}

let function hasCurArmiesSquadsReady() {
  let notReadyInfo = getNotReadySquadsInfo(armiesForBattle.value, chosenSquadsByArmy.value,
    soldiersBySquad.value, soldiersStatuses.value)
  return notReadyInfo.len() == 0
}

let function showCurNotReadySquadsMsg(onContinue) {
  let notReadyInfo = getNotReadySquadsInfo(armiesForBattle.value, chosenSquadsByArmy.value,
    soldiersBySquad.value, soldiersStatuses.value)
  if (notReadyInfo.len() == 0)
    onContinue()
  else
    showNotReadySquads({ notReady = notReadyInfo, onContinue = onContinue })
}

let function goToSquadAndClose(squad) {
  showNotReadySquads(null)
  let armyId = getLinkedArmyName(squad)
  if (curArmiesList.value.indexof(armyId) == null)
    return
  selectArmy(armyId)
  let { squadId } = squad
  if ((chosenSquadsByArmy.value?[armyId] ?? []).findvalue(@(s) s.squadId == squadId) != null)
    setCurSquadId(squadId)
}

curCampaign.subscribe(function(_) {
  if (myExtSquadData.ready.value && !hasCurArmiesSquadsReady())
    myExtSquadData.ready(false)
})

return {
  getNotReadySquadsInfo
  showCurNotReadySquadsMsg
  goToSquadAndClose
  showNotReadySquads
}
