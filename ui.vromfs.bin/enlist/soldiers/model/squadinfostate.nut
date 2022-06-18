from "%enlSqGlob/ui_library.nut" import *

let {
  curArmy, curSquadId, curVehicle, curCampSoldiers,
  curSquadSoldiersInfo, getSoldierItem, objInfoByGuid
} = require("state.nut")
let { campItemsByLink } = require("%enlist/meta/profile.nut")
let { collectSoldierData } = require("collectSoldierData.nut")

let curSoldierIdx = mkWatched(persist, "curSoldierIdx")
let defSoldierGuid = mkWatched(persist, "defSoldierGuid")

let function deselectSoldier() {
  curSoldierIdx(null)
  defSoldierGuid(null)
}
curArmy.subscribe(@(_) deselectSoldier())
curSquadId.subscribe(@(_) deselectSoldier())

let curSoldierInfo = Computed(@()
  collectSoldierData(curSquadSoldiersInfo.value?[curSoldierIdx.value]
    ?? curCampSoldiers.value?[defSoldierGuid.value]))

let curSoldierGuid = Computed(@() curSoldierInfo.value?.guid)

let curSoldierMainWeapon = Computed(function() {
  let guid = curSoldierGuid.value
  if (!guid)
    return null

  return ["primary", "secondary", "side", "melee"]
    .reduce(@(res, slot) res ?? getSoldierItem(guid, slot, campItemsByLink.value), null)?.guid
})

let vehicleCapacity = Computed(@() objInfoByGuid.value?[curVehicle.value].crew ?? 0)

return {
  curSoldierIdx
  curSoldierInfo
  curSoldierGuid
  soldiersList = curSquadSoldiersInfo
  vehicleCapacity
  curSoldierMainWeapon
  defSoldierGuid
}
