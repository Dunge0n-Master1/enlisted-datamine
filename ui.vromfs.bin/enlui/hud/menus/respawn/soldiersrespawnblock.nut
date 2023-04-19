from "%enlSqGlob/ui_library.nut" import *

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { bigPadding, colFull, smallPadding, midPadding, levelNestGradient, defTxtColor, colPart,
  defItemBlur
} = require("%enlSqGlob/ui/designConst.nut")
let mkCurVehicle = require("%enlSqGlob/ui/mkCurVehicle.nut")
let {
  soldiersList, curSoldierIdx, canSpawnOnVehicleBySquad, vehicleInfo, squadIndexForSpawn,
  requestRespawnToEntity, respRequested
} = require("%ui/hud/state/respawnState.nut")
let { mkGrenadeIcon } = require("%ui/hud/huds/player_info/grenadeIcon.nut")
let { mkMineIcon } = require("%ui/hud/huds/player_info/mineIcon.nut")
let mkMedkitIcon = require("%ui/hud/huds/player_info/medkitIcon.nut")
let mkFlaskIcon = require("%ui/hud/huds/player_info/flaskIcon.nut")
let { mkSoldierRespawnBadge, LOCKED_COLOR_SCHEME_ID, SQUAD_COLOR_SCHEME_ID, selectionLine,
  levelInfoHeight, soldierCardSize, selectionLineHeight, soldierBgSchemes
} = require("%enlSqGlob/ui/mkSoldierBadge.nut")
let { iconByItem, soldierNameSlicer } = require("%enlSqGlob/ui/itemsInfo.nut")
let { bgConfig, sIconSize, deadTxtStyle } = require("%ui/hud/menus/respawn/respawnPkg.nut")
let mkVehicleSeats = require("%enlSqGlob/squad_vehicle_seats.nut")
let { localPlayerSquadMembers } = require("%ui/hud/state/squad_members.nut")
let respawnSelection = require("%ui/hud/state/respawnSelection.nut")
let { logerr } = require("dagor.debug")
let soldiersData = require("%ui/hud/state/soldiersData.nut")
let { makeVertScroll, styling } = require("%ui/components/scrollbar.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let seatsOrderWatch = mkVehicleSeats(vehicleInfo)
let canSpawnOnVehicle = Computed(@()
  canSpawnOnVehicleBySquad.value?[squadIndexForSpawn.value] ?? false)
let scrollStyle = styling.__merge({ Bar = styling.Bar(false) })


let itemIcon = @(item, isAlive) {
  size = flex()
  halign = ALIGN_CENTER
  children = iconByItem(item, {
    picSaturate = isAlive ? 1 : 0.3
    width = soldierCardSize[0] - smallPadding * 2
    height = soldierCardSize[1] - levelInfoHeight - smallPadding * 2
  })
}


let function additionalSoldierItems(soldier, sf, isSelected) {
  let { grenadeType = null, mineType = null, targetHealCount = 0, hasFlask = false, isAlive = true
  } = soldier
  let needDarkColor = !isAlive || isSelected || (sf & S_HOVER) != 0
  return {
    rendObj = ROBJ_IMAGE
    image = levelNestGradient
    size = [flex(), levelInfoHeight]
    padding = [0, smallPadding]
    halign = ALIGN_RIGHT
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    children = [
      targetHealCount > 0
        ? mkMedkitIcon(sIconSize, needDarkColor ? deadTxtStyle.color : defTxtColor)
        : null
      hasFlask
        ? mkFlaskIcon(sIconSize, needDarkColor ? deadTxtStyle.color : defTxtColor)
        : null
      grenadeType == null ? null
        : mkGrenadeIcon(grenadeType, sIconSize, needDarkColor ? deadTxtStyle.color : defTxtColor)
      mineType == null ? null
        : mkMineIcon(mineType, sIconSize, needDarkColor ? deadTxtStyle.color : defTxtColor)
    ]
  }
}


let soldiersRespawnBlock = @(isSquadSpawn) @() {
  size = [flex(), SIZE_TO_CONTENT]
  watch = [soldiersData, localPlayerSquadMembers, respawnSelection, seatsOrderWatch, soldiersList,
    curSoldierIdx]
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = (isSquadSpawn ? soldiersList.value : localPlayerSquadMembers.value).map(
  function(val, idx) {
    let soldierInfo = soldiersData.value?[val.guid] ?? {}
    if (soldierInfo.len() <= 0) {
      logerr($"Not found member info for respawn screen {val.guid}")
      return null
    }
    let isCurrent = val?.eid == respawnSelection.value || (curSoldierIdx.value ?? 0) == idx
    let soldier = val.__merge(soldierInfo, { perksLevel = val?.level ?? 0 })
    let seatInfo = seatsOrderWatch.value?[idx]
    let seatName = loc(seatInfo?.locName)
    local weaponName = null
    if (seatInfo == null)
      weaponName = soldierInfo.weapons.findvalue(@(v) v?.isPrimary)?.name
    let { isAlive = true } = soldier
    let soldierBg = soldierBgSchemes[isAlive ? SQUAD_COLOR_SCHEME_ID : LOCKED_COLOR_SCHEME_ID]
    return {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          valign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = [
            {
              rendObj = ROBJ_TEXT
              size = [flex(), SIZE_TO_CONTENT]
              behavior = Behaviors.Marquee
              text = soldierNameSlicer(soldier, true)
            }.__update(isAlive ? defTxtStyle : deadTxtStyle)
            seatInfo == null && weaponName == null ? null : {
              rendObj = ROBJ_TEXT
              size = [flex(), SIZE_TO_CONTENT]
              halign = ALIGN_RIGHT
              behavior = Behaviors.Marquee
              text = seatName ?? weaponName
            }.__update(isAlive ? defTxtStyle : deadTxtStyle)
          ]
        }
        watchElemState(@(sf) {
          picSaturate = 0.2
          brightnes = 0.2
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          halign = ALIGN_CENTER
          behavior = Behaviors.Button
          onClick = function() {
            if (!isAlive)
              return
            curSoldierIdx(idx)
            if(!isSquadSpawn)
              requestRespawnToEntity(soldier.eid)
          }
          onDoubleClick = function(){
            if (!isAlive)
              return
            if(!isSquadSpawn) {
              requestRespawnToEntity(soldier.eid)
              respRequested(true)
            }
          }
          children = [
            mkSoldierRespawnBadge(idx, soldier, isCurrent, sf)
            {
              size = soldierCardSize
              rendObj = ROBJ_WORLD_BLUR
              fillColor = soldierBg(sf, isCurrent)
              color = defItemBlur
              flow = FLOW_VERTICAL
              halign = ALIGN_RIGHT
              children = [
                soldier.weapons.reduce(function(res, weap, idx){
                  let needToShowWeapon = weap.templateName != "" && idx <= 2
                  if (res == null && needToShowWeapon)
                    res = itemIcon({ gametemplate = weap.templateName }, isAlive)
                  return res
                }, null)
                additionalSoldierItems(val, sf, isCurrent)
              ]
            }
          ]
        })
        isCurrent ? selectionLine : { size = [flex(), selectionLineHeight] }
      ]
    }
  })
}


let respawnBlock = @(isSquadSpawn = false) @() {
  watch = vehicleInfo
  size = [colFull(4) + midPadding * 2, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  halign = ALIGN_CENTER
  children = [
    vehicleInfo.value == null ? null
      : mkCurVehicle({ canSpawnOnVehicle, vehicleInfo, soldiersList })
    makeVertScroll(
      soldiersRespawnBlock(isSquadSpawn)
      {
        size = [flex(), SIZE_TO_CONTENT]
        maxHeight = colPart(12.1)
        rootBase = class {
          key = "respawnList"
          behavior = Behaviors.Pannable
          wheelStep = 0.2
        }
        styling = scrollStyle
      }
    )
  ]
}.__update(bgConfig)


return respawnBlock
