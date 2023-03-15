from "%enlSqGlob/ui_library.nut" import *

let { curArmy, curSquadId, curVehicle, objInfoByGuid } = require("state.nut")
let { curSoldierIdx, defSoldierGuid } = require("curSoldiersState.nut")
let { items, soldiers, squads } = require("%enlist/meta/servProfile.nut")
let { getLinkedSquadGuid, getFirstLinkedObjectGuid } = require("%enlSqGlob/ui/metalink.nut")


let function deselectSoldier() {
  curSoldierIdx(null)
  defSoldierGuid(null)
}
curArmy.subscribe(@(_) deselectSoldier())
curSquadId.subscribe(@(_) deselectSoldier())


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
  vehicleCapacity
  defSoldierGuid
  isSquadRented
  isObjGuidBelongToRentedSquad
  buyRentedSquad
}
