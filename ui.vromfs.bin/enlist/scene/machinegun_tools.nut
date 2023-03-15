from "%enlSqGlob/ui_library.nut" import *

let { getClassCfg } = require("%enlSqGlob/ui/soldierClasses.nut")
let { curArmy,
  curSquadSoldiersInfo, curSquadId } = require("%enlist/soldiers/model/state.nut")
let { researchStatuses,
  RESEARCHED, configResearches } = require("%enlist/researches/researchesState.nut")

let machineGunByArmy = {
  berlin_allies = "stationary_dshk_1942"
  berlin_axis = "stationary_mg_131"
  moscow_allies = "stationary_dshk_1942"
  moscow_axis = "stationary_mg_131"
  tunisia_allies = "stationary_browning_m2"
  tunisia_axis = "stationary_mg_131"
  normandy_allies = "stationary_browning_m2"
  normandy_axis = "stationary_mg_131"
  stalingrad_allies = "stationary_dshk_1942"
  stalingrad_axis = "stationary_mg_131"
  pacific_allies = "stationary_browning_m2"
  pacific_axis = "stationary_type_93_hmg"
}

const HEAVY_MGUN_RESEARCH_KEY = "5"

let function searchInResearchesForSquad(research, squadId){
  foreach(r in research)
    foreach(researchEffect in r.tables)
      if (researchEffect.effect?.building_unlock[squadId][HEAVY_MGUN_RESEARCH_KEY] == true)
        return researchEffect.research_id
  return null
}


let hasMgunTable = Computed(function(){
  let res = {}
  foreach(armyId, research in configResearches.value){
    let resArmy = {}
    foreach(squadId,  researchesForSquad in research.pages){
      let mGunResearch = searchInResearchesForSquad(researchesForSquad, squadId)
      if (mGunResearch)
        resArmy[squadId] <- mGunResearch
    }
    res[armyId] <- resArmy
  }
  return res
})

let enginObjectToPlace = Computed(function() {
  let hasEngineer = curSquadSoldiersInfo.value.findindex(@(s)
    getClassCfg(s.sClass).kind == "engineer"
  ) != null
  if (!hasEngineer)
    return null

  let researchIdWithMgun = hasMgunTable.value?[curArmy.value][curSquadId.value]
  if (!researchIdWithMgun)
    return null

  if (researchStatuses.value?[researchIdWithMgun] != RESEARCHED)
    return null

  let machineGun = machineGunByArmy?[curArmy.value]
  return machineGun != null ? [machineGun] : null
})

return {
  enginObjectToPlace
}