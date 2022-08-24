from "%enlSqGlob/ui_library.nut" import *

let mkMainSoldiersBlock = require("%enlSqGlob/ui/mkSoldiersList.nut")
let mkCurVehicle = require("%enlSqGlob/ui/mkCurVehicle.nut")
let {
  soldiersList, curSoldierIdx, canSpawnOnVehicleBySquad, vehicleInfo, squadIndexForSpawn
} = require("%ui/hud/state/respawnState.nut")
let armyData = require("%ui/hud/state/armyData.nut")
let mkVehicleSeats = require("%enlSqGlob/squad_vehicle_seats.nut")
let { mkGrenadeIcon } = require("%ui/hud/huds/player_info/grenadeIcon.nut")
let { mkMineIcon } = require("%ui/hud/huds/player_info/mineIcon.nut")
let { mkMedkitIcon } = require("%ui/hud/huds/player_info/medkitIcon.nut")
let { mkFlaskIcon } = require("%ui/hud/huds/player_info/flaskIcon.nut")

let sIconSize = hdpxi(15)

let seatsOrderWatch = mkVehicleSeats(vehicleInfo)

let canSpawnOnVehicle = Computed(@()
  canSpawnOnVehicleBySquad.value?[squadIndexForSpawn.value] ?? false)

let function addCardChild(soldier, _isSelected) {
  let { grenadeType = null, mineType = null, targetHealCount = 0, hasFlask = false } = soldier
  return {
    hplace = ALIGN_RIGHT
    vplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    gap = hdpx(2)
    children = [
      targetHealCount > 0 ? mkMedkitIcon(sIconSize) : null
      hasFlask ? mkFlaskIcon(sIconSize) : null
      mkGrenadeIcon(grenadeType, sIconSize) ?? mkMineIcon(mineType, sIconSize)
    ]
  }
}

return mkMainSoldiersBlock({
  soldiersListWatch = soldiersList
  expToLevelWatch = Computed(@() armyData.value?.expToLevel)
  seatsOrderWatch
  hasVehicleWatch = Computed(@() vehicleInfo.value != null)
  curSoldierIdxWatch = curSoldierIdx
  curVehicleUi = mkCurVehicle({ canSpawnOnVehicle, vehicleInfo, soldiersList })
  canDeselect = false
  addCardChild
})
