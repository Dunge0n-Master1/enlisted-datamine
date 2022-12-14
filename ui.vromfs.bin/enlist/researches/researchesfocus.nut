from "%enlSqGlob/ui_library.nut" import *

let prepareResearch = require("researchesPresentation.nut")
let { jumpToResearches } = require("%enlist/mainMenu/sectionsState.nut")
let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let {
  configResearches, armiesResearches, allResearchStatus,
  viewSquadId, selectedTable, selectedResearch,
  NOT_ENOUGH_EXP, CAN_RESEARCH, RESEARCHED
} = require("researchesState.nut")
let { armySquadsById } = require("%enlist/soldiers/model/state.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")


let researchToShow = Watched(null)

let getClosestResearch = @(army_id, researches, statuses) researches //FIXME: Better not to merge armyId here, and detect it by research
    .map(@(res) res.__merge({ army_id, status = statuses?[res.research_id] }))
    .filter(@(res) res.status != RESEARCHED)
    .reduce(@(res, val) (res.status != CAN_RESEARCH && val.status == CAN_RESEARCH)
        || (res.status != NOT_ENOUGH_EXP && val.status == NOT_ENOUGH_EXP)
        || (res.line >= val.line && res.tier >= val.tier)
      ? val : res)

let function focusResearch(research) {
  let { army_id = null, squad_id = null, page_id = 0, research_id = null } = research
  let researchData = armiesResearches.value?[army_id].researches[research_id]
  if (squad_id == null || researchData == null)
    return
  jumpToResearches()
  // do not switch army, because all visible researches are belong to the current army
  viewSquadId(squad_id)
  selectedTable(page_id)

  let context = {
    armyId = army_id
    squadId = squad_id
    squadsCfg = squadsCfgById.value
    alltemplates = allItemTemplates.value
  }
  let preparedResearch = prepareResearch(clone researchData, context)
  selectedResearch(preparedResearch)
  researchToShow(preparedResearch)
}

let function findResearchById(research_id) {
  foreach (army_id, armyConfig in configResearches.value)
    foreach (squad_id, squadList in armyConfig?.pages ?? {}) {
      let resFound = squadList.findvalue(@(res) research_id in (res?.tables ?? {}))
      if (resFound != null)
        return { army_id, squad_id, page_id = resFound?.page_id ?? 0, research_id }
    }
  return null
}

let hasResearchSquad = @(armyId, researchData)
  researchData.squad_id in armySquadsById.value?[armyId]

let function findClosestResearch(armyId, checkFunc) {
  let researches = []
  let allResearches = armiesResearches.value?[armyId].researches ?? {}
  foreach (researchData in allResearches)
    if (checkFunc(researchData))
      researches.append(researchData)
  return getClosestResearch(armyId, researches, allResearchStatus.value?[armyId] ?? {})
}

let function findResearchSlotUnlock(soldier, slotType) {
  if (soldier == null || slotType == null)
    return null
  let armyId = getLinkedArmyName(soldier)
  let { sClass = "unknown" } = soldier
  return findClosestResearch(armyId, @(researchData)
    (researchData?.effect.slot_unlock[sClass] ?? []).contains(slotType)
    && hasResearchSquad(armyId, researchData))
}

let function findResearchUpgradeUnlock(armyId, item) {
  if (item == null)
    return null
  let upgradetpl = item?.upgradeitem
  return findClosestResearch(armyId, @(researchData)
    (researchData?.effect.weapon_upgrades ?? []).contains(upgradetpl)
    && hasResearchSquad(armyId, researchData))
}

let function findResearchTrainClass(soldier) {
  if (soldier == null)
    return null
  let armyId = getLinkedArmyName(soldier)
  let { sClass = "unknown" } = soldier
  return findClosestResearch(armyId, @(researchData)
    (researchData?.effect.class_training[sClass] ?? 0) > 0)
}

console_register_command(@(researchId)
  focusResearch(findResearchById(researchId)), "meta.focusResearch")

return {
  researchToShow
  focusResearch
  findResearchSlotUnlock
  findResearchUpgradeUnlock
  findResearchTrainClass
  findClosestResearch
  getClosestResearch
  hasResearchSquad
}
