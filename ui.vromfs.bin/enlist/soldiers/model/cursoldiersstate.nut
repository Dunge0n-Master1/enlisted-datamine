from "%enlSqGlob/ui_library.nut" import *

let { nestWatched } = require("%dngscripts/globalState.nut")

let { armies, curCampSquads, curSquadSoldiersInfo, objInfoByGuid } = require("state.nut")
let { collectSoldierDataImpl } = require("%enlist/soldiers/model/collectSoldierData.nut")
let { perksData } = require("soldierPerks.nut")
let { campItemsByLink, curCampSoldiers } = require("%enlist/meta/profile.nut")
let { soldiersLook } = require("%enlist/meta/servProfile.nut")
let { allOutfitByArmy } = require("%enlist/soldiers/model/config/outfitConfig.nut")
let sClassesCfg = require("config/sClassesConfig.nut")


let curSoldierIdx = nestWatched("curSoldierIdx", null)
let defSoldierGuid = nestWatched("defSoldierGuid", null)


let collectSoldierData = @(soldier) collectSoldierDataImpl(
  soldier, perksData.value, curCampSquads.value, armies.value,
  sClassesCfg.value, campItemsByLink.value, objInfoByGuid.value, soldiersLook.value,
  allOutfitByArmy.value
)

let curSoldiersDataList = Computed(@() curSquadSoldiersInfo.value.map(@(soldier) collectSoldierDataImpl(
  soldier, perksData.value, curCampSquads.value, armies.value,
  sClassesCfg.value, campItemsByLink.value, objInfoByGuid.value, soldiersLook.value,
  allOutfitByArmy.value
)))

let curSoldierInfo = Computed(@() curSoldiersDataList.value?[curSoldierIdx.value]
  ?? collectSoldierData(curCampSoldiers.value?[defSoldierGuid.value])
)

let curSoldierGuid = Computed(@() curSoldierInfo.value?.guid)


let mkSoldiersData = @(soldier) soldier instanceof Watched
  ? Computed(@() collectSoldierDataImpl(
      soldier.value, perksData.value, curCampSquads.value, armies.value,
      sClassesCfg.value, campItemsByLink.value, objInfoByGuid.value, soldiersLook.value,
      allOutfitByArmy.value
    ))
  : Computed(@() collectSoldierDataImpl(
      soldier, perksData.value, curCampSquads.value, armies.value,
      sClassesCfg.value, campItemsByLink.value, objInfoByGuid.value, soldiersLook.value,
      allOutfitByArmy.value
    ))

return {
  curSoldierIdx
  defSoldierGuid

  curSoldierInfo
  curSoldiersDataList
  curSoldierGuid

  collectSoldierData
  mkSoldiersData
}