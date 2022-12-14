from "%enlSqGlob/ui_library.nut" import *

let { fontSmall, fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { bigPadding, titleTxtColor, defTxtColor, sidePadding, colPart, colFull, midPadding,
  footerContentHeight
} = require("%enlSqGlob/ui/designConst.nut")
let { spawnZonesState } = require("%ui/hud/state/spawn_zones_markers.nut")
let { secondsToTimeSimpleString } = require("%ui/helpers/time.nut")
let { mkCountdownTimerPerSec } = require("%ui/helpers/timers.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { isFirstSpawn, spawnCount, spawnSquadId, squadIndexForSpawn,
  squadsList, curSquadData, canSpawnCurrent, canSpawnCurrentSoldier, maxSpawnVehiclesOnPointBySquad,
  nextSpawnOnVehicleInTimeBySquad, canUseRespawnbaseByType, respawnBlockedReason,
  selectedRespawnGroupId
} = require("%ui/hud/state/respawnState.nut")
let { localPlayerTeamSquadsCanSpawn, localPlayerTeamInfo } = require("%ui/hud/state/teams.nut")
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let { respawnTimer, forceSpawnButton, squadNameBlock, mkSquadSpawnDesc, mkKeyboardHint, bgConfig,
  respAnims, commonBlockWidth, missionNameUI, respawnHint
} = require("%ui/hud/menus/respawn/respawnPkg.nut")
let soldiersRespawnBlock = require("%ui/hud/menus/respawn/soldiersRespawnBlock.nut")
let { mkSquadCard } = require("%enlSqGlob/ui/mkSquadCard.nut")
let { mkSquadSpawnIcon } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let cursors = require("%ui/style/cursors.nut")
let { makeHorizScroll, styling } = require("%ui/components/scrollbar.nut")


let vehicleIconSize = colPart(0.5)

let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let titleTxtStyle = { color = titleTxtColor }.__update(fontMedium)


let function spawnsLeftText() {
  let maxSpawn = localPlayerTeamInfo.value?["team__eachSquadMaxSpawns"] ?? 0
  let res = { watch = [spawnCount, localPlayerTeamInfo] }
  if (maxSpawn <= 0)
    return res

  return res.__update({
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    text = loc("respawn/leftRespawns", { num = maxSpawn - spawnCount.value })
  }, defTxtStyle)
}

let vehicleIcon = memoize(function(squadType) {
  return freeze({
    rendObj = ROBJ_IMAGE
    size = [vehicleIconSize, vehicleIconSize]
    image = Picture($"ui/skin#{squadType}_icon.svg:{vehicleIconSize}:{vehicleIconSize}:K")
  })
})


let curVehicle = Computed(@() curSquadData.value?.vehicle)
let maxSpawnVehiclesOnPoint = Computed(@()
  maxSpawnVehiclesOnPointBySquad.value?[squadIndexForSpawn.value] ?? -1)
let nextSpawnOnVehicleInTime = Computed(@()
  nextSpawnOnVehicleInTimeBySquad.value?[squadIndexForSpawn.value] ?? -1.0)
let timeToCanRespawnOnVehicle = mkCountdownTimerPerSec(nextSpawnOnVehicleInTime)


let vehicleSpawnText = Computed(function() {
    let time = timeToCanRespawnOnVehicle.value
    let limit = maxSpawnVehiclesOnPoint.value
    let vehicle = curVehicle.value
    if (vehicle == null)
      return ""
    return time > 0 ? loc("respawn/spawnTimer", { time = secondsToTimeSimpleString(time) })
      : limit > 0 ? loc("respawn/vehicleUsedLimit", {limit})
      : ""
})


let vehicleSpawnInfoBlock = @(squadType) @(){
  watch = vehicleSpawnText
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = vehicleSpawnText.value.len() > 0
    ? [
        vehicleIcon(squadType)
        {
          rendObj = ROBJ_TEXT
          text = vehicleSpawnText.value
        }.__update(defTxtStyle)
      ]
    : null
}


let timeToActivateRespawn = Computed(@() respawnBlockedReason?.value.timeToActivate ?? 0.0)
let timeLeft = mkCountdownTimerPerSec(timeToActivateRespawn)


let availableSpawnZonesCount = Computed(@() spawnZonesState.value
  .reduce(@(sum, v) canUseRespawnbaseByType.value == v?.iconType
                    && localPlayerTeam.value == v?.forTeam ? sum + 1 : sum, 0))


let function spawnInfoBlock() {
  let { canSpawn = false, squadType = null} = curSquadData.value
  let children = [ @() {
    size = [flex(), SIZE_TO_CONTENT]
    watch = [isGamepad, canSpawnCurrentSoldier]
    flow = FLOW_VERTICAL
    gap = midPadding
    halign = ALIGN_CENTER
    children = [
      vehicleSpawnInfoBlock(squadType)
      isGamepad.value
        ? null
        : mkKeyboardHint("Space", loc("respawn/spawn_current_squad"))
      mkSquadSpawnDesc(canSpawn, canSpawnCurrentSoldier.value)
    ]
  }]

  local restrictionsText = ""
  let waitNumber = respawnBlockedReason.value?.waitNumber ?? ""
  let reason = loc(respawnBlockedReason.value?.reason,
    { pos = respawnBlockedReason.value?.waitNumber ?? ""})
  let time = secondsToTimeSimpleString(timeLeft.value)
    if (waitNumber == "") {
      restrictionsText = timeLeft.value > 0
        ? $"{reason}\n{loc("respawn/activateInTime", { time })}"
        : reason
    }
    else {
      restrictionsText = timeLeft.value > 0
        ? loc("respawn/nextQueuedTime", { reason, time })
        : reason
    }

  let restrictionsBlock = !respawnBlockedReason.value?.reason ? []
    : [{
      rendObj = ROBJ_TEXT
      behavior = Behaviors.TextArea
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      text = restrictionsText
    }.__update(defTxtStyle)]

  children.extend(!canSpawnCurrent.value ? restrictionsBlock
    : localPlayerTeamSquadsCanSpawn.value
      ? [
        respawnTimer("respawn/squadRespawnTimer")
          isFirstSpawn.value || availableSpawnZonesCount.value <= 1 ||
          (selectedRespawnGroupId.value?[canUseRespawnbaseByType.value] ?? -1) >= 0
            ? forceSpawnButton
            : null
          spawnsLeftText
        ]
      : [{
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          size = [flex(), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
          text = loc("respawn/no_spawn_scores")
        }.__update(defTxtStyle)])
  return {
    watch = [curSquadData, localPlayerTeamSquadsCanSpawn, canSpawnCurrent,
      respawnBlockedReason, timeLeft, isFirstSpawn, selectedRespawnGroupId,
      availableSpawnZonesCount]
    size = [commonBlockWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    vplace = ALIGN_BOTTOM
    gap = bigPadding
    children
  }.__update(bgConfig)
}


let changeSquadParams = Computed(function() {
  let squadId = spawnSquadId.value
  let idx = squadsList.value.findindex(@(s) s.squadId == squadId) ?? -1
  return {
    idx = idx
    canPrev = idx > 0
    canNext = idx < squadsList.value.len() - 1
  }
})


let function changeSquad(dir) {
  let idx = changeSquadParams.value.idx + dir
  if (idx in squadsList.value)
    spawnSquadId(squadsList.value[idx].squadId)
}


let squadShortcuts = @() {
  watch = [isGamepad, changeSquadParams]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  valign = ALIGN_CENTER
  children = !isGamepad.value ? null
    : [
        mkHotkey("^J:LB", @() changeSquad(-1),
          { opacity = changeSquadParams.value.canPrev ? 1.0 : 0.5 })
        mkHotkey("^J:RB", @() changeSquad(1),
          { opacity = changeSquadParams.value.canNext ? 1.0 : 0.5 })
        {
          rendObj = ROBJ_TEXT
          text = loc("respawn/squadSelection")
        }.__update(defTxtStyle)
      ]
}


let scrollStyle = styling.__merge({ Bar = styling.Bar(false) })
let function squadsListUI() {
  let squadsCount = squadsList.value.len()
  let blockWidth = min(colFull(2 * squadsCount), colFull(19))
  let spawnlist = squadsList.value .map(@(s) s.__merge({ addedRightObj = s.canSpawn
      ? null
      : mkSquadSpawnIcon
    }))

  let listComp = spawnlist.map(function(squad, idx) {
    let isSelected = Computed(@() spawnSquadId.value == squad.squadId)
    let onClick = @() spawnSquadId(squad.squadId)
    let { icon, squadType, level, premIcon, expireTime = 0} = squad
    return mkSquadCard({
      idx
      isSelected
      onClick
      icon
      squadType
      level
      premIcon
      expireTime
    })
  })
  return {
    watch = [squadsList, spawnSquadId]
    size = [blockWidth, SIZE_TO_CONTENT]
    vplace = ALIGN_BOTTOM
    xmbNode = XmbContainer({
      canFocus = @() false
      scrollSpeed = 10.0
      isViewport = true
    })
    children = makeHorizScroll({
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        children = listComp
      },
      {
          size = SIZE_TO_CONTENT
          rootBase = class {
            key = "squadList"
            behavior = Behaviors.Pannable
            wheelStep = 0.2
          }
          styling = scrollStyle
      })
  }
}


let chooseSquadBlock = {
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    squadShortcuts
    squadsListUI
  ]
}.__update(bgConfig)


let showSpawnHint = Computed(@() !isFirstSpawn.value && availableSpawnZonesCount.value > 0)

let selectSpawnHint = @() {
  watch = showSpawnHint
  hplace = ALIGN_CENTER
  children = respawnHint(showSpawnHint.value ? loc("select_spawn") : null)
}


let topBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  animations = respAnims
  transform = {}
  children = [
    @(){
      watch = spawnSquadId
      size = [commonBlockWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        squadNameBlock(spawnSquadId.value, titleTxtStyle).__update(bgConfig)
        soldiersRespawnBlock(true)
      ]
    }.__update(bgConfig)
    selectSpawnHint
    missionNameUI
  ]
}



let bottomBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  gap = { size = flex() }
  animations = respAnims
  transform = {}
  children = [
    chooseSquadBlock
    spawnInfoBlock
  ]
}


return {
  size = flex()
  cursor = cursors.normal
  padding = [sidePadding, sidePadding, footerContentHeight, sidePadding]
  children = [
    topBlock
    bottomBlock
  ]
}
