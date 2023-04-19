from "%enlSqGlob/ui_library.nut" import *

let { fontSmall, fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { bigPadding, titleTxtColor, defTxtColor, sidePadding, colPart, midPadding, footerContentHeight,
  smallPadding
} = require("%enlSqGlob/ui/designConst.nut")
let { spawnZonesState } = require("%ui/hud/state/spawn_zones_markers.nut")
let { secondsToTimeSimpleString } = require("%ui/helpers/time.nut")
let { mkCountdownTimerPerSec } = require("%ui/helpers/timers.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { isFirstSpawn, spawnCount, spawnSquadId, squadIndexForSpawn,
  squadsList, curSquadData, canSpawnCurrent, canSpawnCurrentSoldier, maxSpawnVehiclesOnPointBySquad,
  nextSpawnOnVehicleInTimeBySquad, canUseRespawnbaseByType, respawnBlockedReason,
  selectedRespawnGroupId, paratroopersPointSelectorOn, spawnScore, paratroopersOn
} = require("%ui/hud/state/respawnState.nut")
let { localPlayerTeamSquadsCanSpawn, localPlayerTeamInfo } = require("%ui/hud/state/teams.nut")
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let { respawnTimer, forceSpawnButton, squadNameBlock, mkSquadSpawnDesc, bgConfig, respAnims,
  commonBlockWidth, missionNameUI, respawnHint
} = require("%ui/hud/menus/respawn/respawnPkg.nut")
let soldiersRespawnBlock = require("%ui/hud/menus/respawn/soldiersRespawnBlock.nut")
let { mkRespawnSquadCard, squadCardSize } = require("%enlSqGlob/ui/mkSquadCard.nut")
let { mkSquadSpawnIcon } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let cursors = require("%ui/style/cursors.nut")
let { makeHorizScroll, styling } = require("%ui/components/scrollbar.nut")
let paratroopersButtonBlock = require("%ui/hud/huds/troopers_button.nut")

const MAX_SQUADS = 10
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

let function spawnPriceText(price) {
  let score = spawnScore.value
  return price <= 0 ? {} : {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    size = [flex(), SIZE_TO_CONTENT]
    watch = spawnScore
    halign = ALIGN_CENTER
    text = loc("respawn/squadReadyWithCost", { score, price })
  }.__update(defTxtStyle)
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


let function choosePoinHint() {
  let res = { watch = [paratroopersPointSelectorOn, availableSpawnZonesCount,
    canUseRespawnbaseByType, selectedRespawnGroupId, isFirstSpawn] }
  let hideHint = isFirstSpawn.value
    || (availableSpawnZonesCount.value <= 1 && !paratroopersPointSelectorOn.value)
    || (selectedRespawnGroupId.value?[canUseRespawnbaseByType.value] ?? -1) >= 0

  if (hideHint)
    return res

  return res.__update({
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    text = paratroopersPointSelectorOn.value
      ? loc("respawn/landingPoint")
      : loc("respawn/choose_respawn_point")
  })
}


let function spawnInfoBlock() {
  let { canSpawn = false, scorePrice = 0, isAffordable = true, squadType = null} = curSquadData.value
  let children = [ @() {
    size = [flex(), SIZE_TO_CONTENT]
    watch = [isGamepad, canSpawnCurrentSoldier]
    flow = FLOW_VERTICAL
    gap = midPadding
    halign = ALIGN_CENTER
    children = [
      vehicleSpawnInfoBlock(squadType)
      choosePoinHint
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

  let defText = {
    rendObj = ROBJ_TEXT
    behavior = Behaviors.TextArea
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
  }.__update(defTxtStyle)

  let restrictionsBlock = !respawnBlockedReason.value?.reason ? []
    : [defText.__merge({text = restrictionsText})]

  let notAffordableBlock = [
    @() defText.__merge({
      watch = spawnScore
      text = loc("respawn/notAffordable", {price=scorePrice, score=spawnScore.value})
    })
    defText.__merge({text = loc("respawn/notAffordableSubtext")})
  ]
  let firstSpawnCond = isFirstSpawn.value && (!paratroopersPointSelectorOn.value || paratroopersOn.value)
  children.extend(!isAffordable ? notAffordableBlock : !canSpawnCurrent.value ? restrictionsBlock
    : localPlayerTeamSquadsCanSpawn.value
      ? [
        respawnTimer("respawn/squadRespawnTimer")
        firstSpawnCond || (availableSpawnZonesCount.value <= 1 && !paratroopersPointSelectorOn.value) ||
        (selectedRespawnGroupId.value?[canUseRespawnbaseByType.value] ?? -1) >= 0
          ? forceSpawnButton
          : null
        paratroopersButtonBlock
        spawnsLeftText
        spawnPriceText(scorePrice)
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
      availableSpawnZonesCount, paratroopersPointSelectorOn]
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
  let spawnlist = squadsList.value.map(@(s) s.__merge({ addedRightObj = s.canSpawn
    ? null
    : mkSquadSpawnIcon
  }))

  let maxBlockWidth = MAX_SQUADS * squadCardSize[0] + (MAX_SQUADS - 1) * bigPadding

  let listComp = spawnlist.map(function(squad, idx) {
    let isSelected = Computed(@() spawnSquadId.value == squad.squadId)
    let onClick = @() spawnSquadId(squad.squadId)
    let { icon, squadType, level, premIcon, canSpawn, readinessPercent = 0 } = squad
    let isAlive = readinessPercent > 0
    return mkRespawnSquadCard({
      idx
      isSelected
      onClick
      icon
      squadType
      level
      premIcon
      isAlive
      canSpawn
    })
  })
  return {
    watch = [squadsList, spawnSquadId]
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
          maxWidth = maxBlockWidth
          rootBase = class {
            key = "squadList"
            behavior = Behaviors.Pannable
            wheelStep = 0.2
          }
          styling = scrollStyle
      })
  }
}


let soldierSpawn = @() {
  watch = spawnSquadId
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    squadNameBlock(spawnSquadId.value, titleTxtStyle).__update(bgConfig)
    soldiersRespawnBlock(true)
  ]
}


let chooseSquadBlock = {
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    soldierSpawn
    {
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        squadShortcuts
        squadsListUI
      ]
    }.__update(bgConfig)
  ]
}


let showSpawnHint = Computed(@() !isFirstSpawn.value && availableSpawnZonesCount.value > 0)

let selectSpawnHint = @() {
  watch = showSpawnHint
  hplace = ALIGN_CENTER
  children = respawnHint(paratroopersPointSelectorOn.value ? loc("respawn/selectLandingPoint") : showSpawnHint.value ? loc("select_spawn") : null)
}


let topBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  animations = respAnims
  transform = {}
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      children = [
        missionNameUI
      ]
    }
    selectSpawnHint
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
