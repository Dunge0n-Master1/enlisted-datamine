from "%enlSqGlob/ui_library.nut" import *

let {
  curArmy, curSquadId, curVehicle, curCampSoldiers,
  curSquadSoldiersInfo, getSoldierItem, objInfoByGuid
} = require("state.nut")
let { campItemsByLink } = require("%enlist/meta/profile.nut")
let { collectSoldierData } = require("collectSoldierData.nut")
let { items, soldiers, squads } = require("%enlist/meta/servProfile.nut")
let { getLinkedSquadGuid, getFirstLinkedObjectGuid } = require("%enlSqGlob/ui/metalink.nut")
let { nestWatched } = require("%dngscripts/globalState.nut")


let curSoldierIdx = nestWatched("curSoldierIdx", null)
let defSoldierGuid = nestWatched("defSoldierGuid", null)


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

let isSquadRented = @(squad) (squad?.expireTime ?? 0) > 0

let vehicleCapacity = Computed(@() objInfoByGuid.value?[curVehicle.value].crew ?? 0)

let function isSoldierBelongToRentedSquad(soldier, allSquads) {
  let squadGuid = getLinkedSquadGuid(soldier)
  return squadGuid != null && isSquadRented(allSquads?[squadGuid])
}

let function isObjGuidBelongToRentedSquad(guid) {
  let allSquads = squads.value
  let allSoldiers = soldiers.value
  let allItems = items.value

  let item = allItems?[guid]
  let linkedSoldierGuid = item == null ? null
    : getFirstLinkedObjectGuid(item, allSoldiers)
  let soldier = allSoldiers?[linkedSoldierGuid ?? guid]

  return soldier == null ? false
    : isSoldierBelongToRentedSquad(soldier, allSquads)
}

let buyRentedSquad = mkWatched(persist, "buyRentedSquad", null)

return {
  curSoldierIdx
  curSoldierInfo
  curSoldierGuid
  soldiersList = curSquadSoldiersInfo
  vehicleCapacity
  curSoldierMainWeapon
  defSoldierGuid
  isSquadRented
  isObjGuidBelongToRentedSquad
  buyRentedSquad
}
