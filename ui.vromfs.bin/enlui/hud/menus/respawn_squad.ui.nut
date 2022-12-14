from "%enlSqGlob/ui_library.nut" import *

let { h1_txt, h2_txt, body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {spawnZonesState} = require("%ui/hud/state/spawn_zones_markers.nut")
let {verPadding, horPadding} = require("%enlSqGlob/safeArea.nut")
let {secondsToTimeSimpleString} = require("%ui/helpers/time.nut")
let {
  strokeStyle, bigPadding, smallPadding, blurBgColor
} = require("%enlSqGlob/ui/viewConst.nut")
let txt = require("%ui/components/text.nut").text
let {textarea} = require("%ui/components/textarea.nut")
let {mkCountdownTimerPerSec} = require("%ui/helpers/timers.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { missionName, missionType } = require("%enlSqGlob/missionParams.nut")
let { isFirstSpawn, spawnCount, spawnSquadId, squadIndexForSpawn,
        squadsList, curSquadData, canSpawnCurrent, canSpawnCurrentSoldier, maxSpawnVehiclesOnPointBySquad, nextSpawnOnVehicleInTimeBySquad,
        canUseRespawnbaseByType, respawnBlockedReason, selectedRespawnGroupId} = require("%ui/hud/state/respawnState.nut")
let { localPlayerTeamSquadsCanSpawn, localPlayerTeamInfo } = require("%ui/hud/state/teams.nut")
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")

let {respawnTimer, forceSpawnButton, panel, headerBlock} = require("%ui/hud/respawn_parts.nut")
let respawnSquadInfoUi = require("respawn_squad_info.ui.nut")
let mkCurSquadsList = require("%enlSqGlob/ui/mkSquadsList.nut")
let { mkSquadSpawnIcon, mkSquadSpawnDesc, mkKeyboardHint } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")

let blocksGap = smallPadding
let vehicleIconSize = hdpxi(28)

let bgConfig = {
  rendObj = ROBJ_WORLD_BLUR
  padding = bigPadding
  color = blurBgColor
}

let function spawnsLeftText() {
  let maxSpawn = localPlayerTeamInfo.value?["team__eachSquadMaxSpawns"] ?? 0
  return {
    size = [flex(), SIZE_TO_CONTENT]
    watch = [spawnCount, localPlayerTeamInfo]
    children = maxSpawn <= 0 ? null
      : textarea(loc("respawn/leftRespawns", { num = maxSpawn - spawnCount.value }),
          {
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_CENTER
          }.__update(sub_txt))
  }
}

let vehicleIcon = memoize(function(squadType) {
  return freeze({
    rendObj = ROBJ_IMAGE
    size = [vehicleIconSize, vehicleIconSize]
    image = Picture($"ui/skin#{squadType}_icon.svg:{vehicleIconSize}:{vehicleIconSize}:K")
  })
})

let curVehicle = Computed(@() curSquadData.value?.vehicle)
let maxSpawnVehiclesOnPoint = Computed(@() maxSpawnVehiclesOnPointBySquad.value?[squadIndexForSpawn.value] ?? -1)
let nextSpawnOnVehicleInTime = Computed(@() nextSpawnOnVehicleInTimeBySquad.value?[squadIndexForSpawn.value] ?? -1.0)
let timeToCanRespawnOnVehicle = mkCountdownTimerPerSec(nextSpawnOnVehicleInTime)

let vehicleSpawnText = Computed(function() {
    let time = timeToCanRespawnOnVehicle.value
    let limit = maxSpawnVehiclesOnPoint.value
    let vehicle = curVehicle.value
    if (vehicle == null)
      return ""
    if (time > 0)
      return "{0}{1}".subst(loc("respawn/timeToSpawn"), secondsToTimeSimpleString(time))
    if (limit > 0)
      return "{0}/{0}{1}".subst(limit, loc("respawn/vehicleUsed"))
    return ""
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
        txt(vehicleSpawnText.value, sub_txt)
      ]
    : null
}

let timeToActivateRespawn = Computed(@() respawnBlockedReason?.value.timeToActivate ?? 0.0)
let timeLeft = mkCountdownTimerPerSec(timeToActivateRespawn)

let availableSpawnZonesCount = Computed(@() spawnZonesState.value
  .reduce(@(sum, v) canUseRespawnbaseByType.value == v?.iconType
                    && localPlayerTeam.value == v?.forTeam ? sum + 1 : sum, 0))

let function spawnInfoBlock() {
  let { canSpawn = false, readinessPercent = 0, squadType = null} = curSquadData.value
  let spawnInfo = [
    @() {
      size = [flex(), SIZE_TO_CONTENT]
      watch = [isGamepad, canSpawnCurrentSoldier]
      flow = FLOW_VERTICAL
      gap = bigPadding
      halign = ALIGN_CENTER
      children = [
        vehicleSpawnInfoBlock(squadType)
        isGamepad.value
          ? null
          : mkKeyboardHint("Space", loc("respawn/spawn_current_squad"))
        mkSquadSpawnDesc(canSpawn, readinessPercent, canSpawnCurrentSoldier.value)
      ]
    }
  ]

  let restrictionsText = respawnBlockedReason.value?.waitNumber == null
    ? (timeLeft.value > 0
        ? "{0}\n{1}{2}".subst(loc(respawnBlockedReason.value?.reason), loc("respawn/activate_at"), secondsToTimeSimpleString(timeLeft.value))
        :  loc(respawnBlockedReason.value?.reason)
      )
    : (timeLeft.value > 0
        ? "{0}\n{1}{2}".subst(loc(respawnBlockedReason.value?.reason, {pos = respawnBlockedReason.value.waitNumber}),
                             loc("respawn/nextqueued_at"), secondsToTimeSimpleString(timeLeft.value))
        :  loc(respawnBlockedReason.value?.reason, {pos = respawnBlockedReason.value?.waitNumber} )
      )

  let restrictionsBlock = respawnBlockedReason.value?.reason ? [
    textarea(
      restrictionsText, {
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
      }.__update(sub_txt)
    )
  ] : []

  let children = !canSpawnCurrent.value ? restrictionsBlock
    : localPlayerTeamSquadsCanSpawn.value
      ? [
          respawnTimer(loc("respawn/respawn_squad"), sub_txt)
          isFirstSpawn.value || availableSpawnZonesCount.value <= 1 ||
          (selectedRespawnGroupId.value?[canUseRespawnbaseByType.value] ?? -1) >= 0
            ? forceSpawnButton()
            : textarea(loc("respawn/choose_respawn_point"), {
                size = [flex(), SIZE_TO_CONTENT]
                halign = ALIGN_CENTER
              }.__update(body_txt))
          spawnsLeftText
        ]
      : [
          textarea(loc("respawn/no_spawn_scores"), {
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_CENTER
          }.__update(sub_txt))
        ]
  children.extend(spawnInfo)
  return {
    watch = [curSquadData, localPlayerTeamSquadsCanSpawn, canSpawnCurrent,
             respawnBlockedReason, timeLeft, isFirstSpawn, selectedRespawnGroupId,
             availableSpawnZonesCount]
    minHeight = fontH(370) //timer appears and change size
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    gap = bigPadding
    children
  }
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
  children = !isGamepad.value ? null
    : [
        mkHotkey("^J:LB", @() changeSquad(-1), { opacity = changeSquadParams.value.canPrev ? 1.0 : 0.5 })
        mkHotkey("^J:RB", @() changeSquad(1), { opacity = changeSquadParams.value.canNext ? 1.0 : 0.5 })
      ]
}

let squadsListUI = mkCurSquadsList({
  curSquadsList = Computed(@() squadsList.value
    .map(@(s) s.__merge({ addedRightObj = s.canSpawn
      ? null
      : mkSquadSpawnIcon
    }))
  )
  curSquadId = spawnSquadId
  setCurSquadId = @(squadId) spawnSquadId(squadId)
  bgOverride = { rendObj = null, padding = 0 }
  addedObj = squadShortcuts
})

let squadSpawnList = {
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = [
        squadsListUI
        @() respawnSquadInfoUi.__update({ padding = 0, rendObj = null })
      ]
    }
    spawnInfoBlock
  ]
}.__update(bgConfig)


let squadRespawn = panel(@() {
    size = [SIZE_TO_CONTENT, flex()]
    flow = FLOW_VERTICAL
    gap = blocksGap
    watch = [isFirstSpawn]
    children = [
      headerBlock(isFirstSpawn.value
        ? loc("respawn/shooseSquad")
        : loc("respawn/squadIsDead")).__update(bgConfig)
      squadSpawnList
    ]
  }
  {
    rendObj = null
    size = [SIZE_TO_CONTENT, flex()]
    flow = FLOW_HORIZONTAL
    gap = blocksGap
  }
)

let titlePadding = fsh(4)
let missionNameUI = @() {
  rendObj = ROBJ_TEXT
  text = loc(missionName.value, { mission_type = loc($"missionType/{missionType.value}") })
  margin = [verPadding.value + titlePadding, horPadding.value + titlePadding]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  watch = [verPadding, missionName, missionType]
}.__update(h1_txt, strokeStyle)


let selectSpawnTitle = @() {
  rendObj = ROBJ_TEXT
  text = loc("select_spawn")
}.__update(h2_txt, strokeStyle)
let showSpawnHint = Computed(@() !isFirstSpawn.value && availableSpawnZonesCount.value > 0)

let selectSpawnHint = @(){
  watch = [showSpawnHint, verPadding]
  hplace = ALIGN_CENTER
  pos = [0, verPadding.value + fsh(10)]
  children = showSpawnHint.value ? selectSpawnTitle : null
}
return {
  children = [
    squadRespawn
    selectSpawnHint
    missionNameUI
  ]
  size = flex()
}
