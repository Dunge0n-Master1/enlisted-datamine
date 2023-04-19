from "%enlSqGlob/ui_library.nut" import *

let { h0_txt, h1_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { respawnsInBot, canUseRespawnbaseByType, needSpawnMenu, selectedRespawnGroupId, isFirstSpawn, respRequested, paratroopersPointSelectorOn } = require("%ui/hud/state/respawnState.nut")
let { localPlayerTeam } = require("%ui/hud/state/local_player.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")
let {
  spawnZonesState,
  spawnZonesGetWatched,
} = require("%ui/hud/state/spawn_zones_markers.nut")
let { delete_paratroopers_icon } = require("%ui/hud/menus/troopers_point_chooser.nut")

let spawnIconColor = Color(86,131,212,250)
let inactiveSpawnIconColor = Color(160,160,160,150)
let playerSpawnActiveColor = Color(57, 99, 255)

//Temporarily same icons as spawn points icons for soldiers
let spawnIconSize = [fsh(9), fsh(9)]
let selectedSpawnIconSize = [fsh(12), fsh(12)]
let customSpawnSize = [fsh(6), fsh(6)]
let selectedCustomSpawnSize = [fsh(9), fsh(9)]
let playerSpawnSize = [fsh(6), fsh(6)]
let selectedPlayerSpawnSize = [fsh(8), fsh(8)]
let counterSpawnSize = [fsh(3), fsh(3)]

let spawn_point = Picture($"!ui/skin#spawn_point.svg:{spawnIconSize[0]}:{spawnIconSize[1]}:K")
let selected_spawn_point = Picture($"!ui/skin#spawn_point_active.svg:{selectedSpawnIconSize[0]}:{selectedSpawnIconSize[1]}:K")

let teammate_spawn_point = Picture($"!ui/skin#spawn_soldier_point.svg:{playerSpawnSize[0]}:{playerSpawnSize[1]}:K")
let selected_teammate_spawn_point = Picture($"!ui/skin#spawn_soldier_point_active.svg:{selectedPlayerSpawnSize[0]}:{selectedPlayerSpawnSize[1]}:K")

let custom_spawn_point = Picture($"!ui/skin#custom_spawn_point.svg:{customSpawnSize[0]}:{customSpawnSize[1]}:K")
let selected_custom_spawn_point = Picture($"!ui/skin#custom_spawn_point_active.svg:{selectedCustomSpawnSize[0]}:{selectedCustomSpawnSize[1]}:K")

let counter_spawn_icon = Picture($"!ui/skin#counter_spawn_icon.svg:{counterSpawnSize[0]}:{counterSpawnSize[1]}:K")
let paratroopers_spawn_point = Picture($"!ui/skin#paratrooper_spawn_point.svg:{spawnIconSize[0]}:{spawnIconSize[1]}:K")

let mkSpawnPointInfo = @() {
  icon = @(isSelected) isSelected ? selected_spawn_point : spawn_point
  size = @(isSelected) isSelected ? selectedSpawnIconSize : spawnIconSize
  color = @(isActive) isActive ? spawnIconColor : inactiveSpawnIconColor
}

let customSpawnPointInfo = {
  icon = @(isSelected) isSelected ? selected_custom_spawn_point : custom_spawn_point
  size = @(isSelected) isSelected ? selectedCustomSpawnSize : customSpawnSize
  color = @(isActive) isActive ? spawnIconColor : inactiveSpawnIconColor
}

let playerSpawnPointInfo = {
  icon = @(isSelected) isSelected ? selected_teammate_spawn_point : teammate_spawn_point
  size = @(isSelected) isSelected ? selectedPlayerSpawnSize : playerSpawnSize
  color = @(isActive) isActive ? playerSpawnActiveColor : inactiveSpawnIconColor
}

let paratroopersSpawnPointInfo = {
  icon = @(isSelected) isSelected ? paratroopers_spawn_point : spawn_point
  size = @(isSelected) isSelected ? selectedSpawnIconSize : spawnIconSize
  color = @(isActive) isActive ? playerSpawnActiveColor : inactiveSpawnIconColor
}

let counterSpawnIconInfo = {
  icon = counter_spawn_icon
  size = counterSpawnSize
  color = @(isActive) isActive ? spawnIconColor : inactiveSpawnIconColor
}

let spawnPointsTypesInfo = {
  vehicle = mkSpawnPointInfo()
  human = mkSpawnPointInfo()
}

let function paratroopers_icon_click(event){
  if (event.button == 1)
    delete_paratroopers_icon()
}



let defTransform = {}
let defPos = [0, -fsh(1)]

let  function mkQueueCounter(spawnIconInfo, isSelected, isActive, queueSize) {
  let res = queueSize > 0 ? {
    pos = [0, -spawnIconInfo.size(isSelected)[1]*0.7]
    flow = FLOW_HORIZONTAL
    children = [
      {
        rendObj = ROBJ_TEXT
        color = Color(255, 255, 255)
        halign = ALIGN_LEFT
        valign = ALIGN_CENTER
        text = queueSize
        transform = defTransform
        size = SIZE_TO_CONTENT
      }.__update(h1_txt),
      {
        rendObj = ROBJ_IMAGE
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        size = counterSpawnIconInfo.size
        color = counterSpawnIconInfo.color(isActive)
        image = counterSpawnIconInfo.icon
        pos = [-counterSpawnIconInfo.size[0], counterSpawnIconInfo.size[1]*0.1]
      }
    ]
  }: null

  return res
}

let mkRespawnPoint = @(eid, isSelected, spawnIconInfo, selectedGroup, isActive, queueSize, additiveAngle, iconType) {
    additiveAngle
    targetEid = eid
    transform = defTransform
    behavior = Behaviors.RotateRelativeToDir
    children = @() {
      watch = isReplay
      rendObj = ROBJ_IMAGE
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = spawnIconInfo.size(isSelected)
      color = spawnIconInfo.color(isActive)
      image = spawnIconInfo.icon(isSelected)
      pos = [0, -spawnIconInfo.size(isSelected)[0]*0.1]
      behavior = isReplay.value ? null : Behaviors.Button
      onClick = @(event) iconType == "paratroopers" ? paratroopers_icon_click(event) : selectedRespawnGroupId.mutate(@(v) v[iconType] <- selectedGroup)
      onDoubleClick = @() respRequested(true)
      children = mkQueueCounter(spawnIconInfo, isSelected, isActive, queueSize)
    }
  }
let mkTextPlayerGroupmate = @(num, isSelected) {
  rendObj = ROBJ_TEXT
  color = Color(255, 255, 255)
  text = num
  transform = defTransform
  pos = defPos
  size = SIZE_TO_CONTENT
}.__update(isSelected ? h0_txt : h1_txt)

let isAllZonesHidden = Computed(@() (isFirstSpawn.value && !paratroopersPointSelectorOn.value) || respawnsInBot.value || !needSpawnMenu.value)

let mk_respawn_point = memoize(function(eid) {
  let data = {
    eid
    minDistance = 0.7
    maxDistance = 15000
    distScaleFactor = 0.5
    clampToBorder = true
  }
  let markerState = spawnZonesGetWatched(eid)
  let watch = [selectedRespawnGroupId, canUseRespawnbaseByType, isAllZonesHidden, localPlayerTeam,
    markerState, isReplay]

  return function() {
    let {selectedGroup, iconType, iconIndex, forTeam, isCustom, isPlayerSpawn, isActive, queueSize, additiveAngle} = markerState.value
    local spawnIconInfo = spawnPointsTypesInfo?[iconType] ?? spawnPointsTypesInfo.human
    if (isPlayerSpawn)
      spawnIconInfo = playerSpawnPointInfo
    else if (isCustom)
      spawnIconInfo = customSpawnPointInfo
    if (iconType == "paratroopers")
      spawnIconInfo = paratroopersSpawnPointInfo

    let isHidden = isReplay.value
      || isAllZonesHidden.value
      || forTeam != localPlayerTeam.value
      || iconType != canUseRespawnbaseByType.value
    let isSelected = (selectedRespawnGroupId.value?[iconType] ?? -1) == selectedGroup
    return {
      data
      targetEid = eid
      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      key = eid
      transform = defTransform
      behavior = Behaviors.Projection
      watch
      sortOrder = eid
      children = isHidden ? null : [
            mkRespawnPoint(
              eid, isSelected, spawnIconInfo, selectedGroup, isActive, queueSize, additiveAngle, iconType
            )
            iconIndex > 0 ? mkTextPlayerGroupmate(iconIndex, isSelected) : null
          ]
    }
  }
})

return {
  spawn_zone_ctor = { watch = spawnZonesState,
    ctor = @() spawnZonesState.value.keys().map(mk_respawn_point) },
}
