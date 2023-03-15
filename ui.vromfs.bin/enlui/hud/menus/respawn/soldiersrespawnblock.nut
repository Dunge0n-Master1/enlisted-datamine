from "%enlSqGlob/ui_library.nut" import *

let { bigPadding, colPart, colFull, smallPadding, midPadding, titleTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let mkCurVehicle = require("%enlSqGlob/ui/mkCurVehicle.nut")
let {
  soldiersList, curSoldierIdx, canSpawnOnVehicleBySquad, vehicleInfo, squadIndexForSpawn,
  requestRespawnToEntity, respRequested
} = require("%ui/hud/state/respawnState.nut")
let { mkGrenadeIcon } = require("%ui/hud/huds/player_info/grenadeIcon.nut")
let { mkMineIcon } = require("%ui/hud/huds/player_info/mineIcon.nut")
let { mkMedkitIcon } = require("%ui/hud/huds/player_info/medkitIcon.nut")
let { mkFlaskIcon } = require("%ui/hud/huds/player_info/flaskIcon.nut")
let { mkSoldierBadge, LOCKED_COLOR_SCHEME_ID, SQUAD_COLOR_SCHEME_ID
} = require("%enlSqGlob/ui/mkSoldierBadge.nut")
let { iconByItem } = require("%enlSqGlob/ui/itemsInfo.nut")
let { bgConfig, sIconSize } = require("%ui/hud/menus/respawn/respawnPkg.nut")
let mkVehicleSeats = require("%enlSqGlob/squad_vehicle_seats.nut")
let { localPlayerSquadMembers } = require("%ui/hud/state/squad_members.nut")
let respawnSelection = require("%ui/hud/state/respawnSelection.nut")
let { logerr } = require("dagor.debug")
let soldiersData = require("%ui/hud/state/soldiersData.nut")


let seatsOrderWatch = mkVehicleSeats(vehicleInfo)
let canSpawnOnVehicle = Computed(@()
  canSpawnOnVehicleBySquad.value?[squadIndexForSpawn.value] ?? false)


let itemIcon = @(item) {
  color = titleTxtColor
  hplace = ALIGN_RIGHT
  padding = [midPadding, bigPadding]
  children = iconByItem(item, {
    width = colFull(2) - bigPadding * 2
    height = colPart(0.645)
  })
}.__update(bgConfig)


let function additionalSoldierItems(soldier) {
  let { grenadeType = null, mineType = null, targetHealCount = 0, hasFlask = false } = soldier
  return {
    size = [flex(), colPart(0.38)]
    halign = ALIGN_RIGHT
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    children = [
      targetHealCount > 0 ? mkMedkitIcon(sIconSize) : null
      hasFlask ? mkFlaskIcon(sIconSize) : null
      mkGrenadeIcon(grenadeType, sIconSize) ?? mkMineIcon(mineType, sIconSize)
    ]
  }
}


let soldiersRespawnBlock = @(isSquadSpawn) @() {
  size = [flex(), SIZE_TO_CONTENT]
  watch = [soldiersData, localPlayerSquadMembers, respawnSelection, seatsOrderWatch]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = (isSquadSpawn ? soldiersList.value : localPlayerSquadMembers.value).map(
  function(val, idx) {
    let soldierInfo = soldiersData.value?[val.guid] ?? {}
    if (soldierInfo.len() <= 0) {
      logerr($"Not found member info for respawn screen {val.guid}")
      return null
    }
    let isCurrent = val?.eid == respawnSelection.value
    let soldier = val.__merge(soldierInfo, { perksLevel = val?.level ?? 0 })
    let seatInfo = seatsOrderWatch.value?[idx]
    let seatName = loc(seatInfo?.locName)
    let { isAlive = true } = soldier
    return @() {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      children = [
        seatInfo == null ? null : {
          rendObj = ROBJ_TEXT
          text = seatName
          margin = [smallPadding, 0]
        }
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = { size = flex() }
          children = [
            watchElemState(@(sf) mkSoldierBadge(idx, soldier, isCurrent, sf,
              !isAlive ? null : function() {
                curSoldierIdx(idx)
                if(!isSquadSpawn){
                  requestRespawnToEntity(soldier.eid)
                  if (isCurrent)
                    @() respRequested(true)
                }
              }, isAlive ? SQUAD_COLOR_SCHEME_ID : LOCKED_COLOR_SCHEME_ID))
            {
              size = [colFull(2), SIZE_TO_CONTENT]
              flow = FLOW_VERTICAL
              halign = ALIGN_RIGHT
              children = [
                soldier.weapons.reduce(function(res, weap, idx){
                  let needToShowWeapon = weap.templateName != "" && idx <= 2
                  if (res == null && needToShowWeapon)
                    res = itemIcon({ gametemplate = weap.templateName })
                  return res
                }, null)
                additionalSoldierItems(soldier)
              ]
            }
          ]
        }
      ]
    }
  })
}


let respawnBlock = @(isSquadSpawn = false) {
  watch = vehicleInfo
  size = [colFull(4), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  halign = ALIGN_CENTER
  children = [
    vehicleInfo.value == null ? null
      : mkCurVehicle({ canSpawnOnVehicle, vehicleInfo, soldiersList })
    soldiersRespawnBlock(isSquadSpawn)
  ]
}


return respawnBlock
