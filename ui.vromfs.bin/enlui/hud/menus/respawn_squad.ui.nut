from "%enlSqGlob/ui_library.nut" import *

let colorize = require("%ui/components/colorize.nut")
let { fontHeading1, fontHeading2, fontBody, fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let {spawnZonesState} = require("%ui/hud/state/spawn_zones_markers.nut")
let {verPadding, horPadding} = require("%enlSqGlob/safeArea.nut")
let {secondsToTimeSimpleString} = require("%ui/helpers/time.nut")
let { strokeStyle, bigPadding, smallPadding } = require("%enlSqGlob/ui/viewConst.nut")
let txt = require("%ui/components/text.nut").text
let {textarea} = require("%ui/components/textarea.nut")
let {mkCountdownTimerPerSec} = require("%ui/helpers/timers.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { missionName, missionType } = require("%enlSqGlob/missionParams.nut")
let { isFirstSpawn, spawnCount, spawnSquadId, squadIndexForSpawn,
  squadsList, curSquadData, canSpawnCurrent, canSpawnCurrentSoldier, maxSpawnVehiclesOnPointBySquad, nextSpawnOnVehicleInTimeBySquad,
  canUseRespawnbaseByType, respawnBlockedReason, selectedRespawnGroupId, paratroopersPointSelectorOn, spawnScore, paratroopersOn
} = require("%ui/hud/state/respawnState.nut")
let { localPlayerTeamSquadsCanSpawn, localPlayerTeamInfo } = require("%ui/hud/state/teams.nut")
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")

let {respawnTimer, forceSpawnButton, panel, headerBlock} = require("%ui/hud/respawn_parts.nut")
let respawnSquadInfoUi = require("respawn_squad_info.ui.nut")
let mkCurSquadsList = require("%enlSqGlob/ui/mkSquadsList.nut")
let { mkSquadSpawnIcon, mkSquadSpawnDesc } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let paratroopersButtonBlock = require("%ui/hud/huds/troopers_button.nut")
let { attentionTxtColor, panelBgColor } = require("%enlSqGlob/ui/designConst.nut")


let vehicleIconSize = hdpxi(28)

let bgConfig = {
  rendObj = ROBJ_WORLD_BLUR
  color = panelBgColor
}

let function spawnsLeftText() {
  let maxSpawn = localPlayerTeamInfo.value?["team__eachSquadMaxSpawns"] ?? 0
  return {
    size = [flex(), SIZE_TO_CONTENT]
    watch = [spawnCount, localPlayerTeamInfo]
    children = maxSpawn <= 0 ? null
      : textarea(loc("respawn/leftRespawns", {
          num = colorize(attentionTxtColor, maxSpawn - spawnCount.value)
        }), {
          size = [flex(), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
        }.__update(fontSub))
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
        txt(vehicleSpawnText.value, fontSub)
      ]
    : null
}

let timeToActivateRespawn = Computed(@() respawnBlockedReason?.value.timeToActivate ?? 0.0)
let timeLeft = mkCountdownTimerPerSec(timeToActivateRespawn)

let availableSpawnZonesCount = Computed(@() spawnZonesState.value
  .reduce(@(sum, v) canUseRespawnbaseByType.value == v?.iconType
                    && localPlayerTeam.value == v?.forTeam ? sum + 1 : sum, 0))

let mkReasonWithTime = @(reasonTxt, timerLocId, timeVal) "{0}\n{1}{2}"
  .subst(reasonTxt, loc(timerLocId),
    colorize(attentionTxtColor, secondsToTimeSimpleString(timeVal)))

let function spawnInfoBlock() {
  let { canSpawn = false, readinessPercent = 0, scorePrice = 0,
    isAffordable = true, squadType = null} = curSquadData.value
  let spawnInfo = [
    @() {
      size = [flex(), SIZE_TO_CONTENT]
      watch = [isGamepad, canSpawnCurrentSoldier, spawnScore]
      flow = FLOW_VERTICAL
      gap = bigPadding
      halign = ALIGN_CENTER
      children = [
        vehicleSpawnInfoBlock(squadType)
        mkSquadSpawnDesc(canSpawn, readinessPercent, canSpawnCurrentSoldier.value, isAffordable, scorePrice, spawnScore.value)
      ]
    }
  ]

  let tmVal = timeLeft.value
  let { reason = null, waitNumber = null } = respawnBlockedReason.value
  let reasonTxt = waitNumber == null ? loc(reason) : loc(reason, { pos = waitNumber })
  let timerLocId = waitNumber == null ? "respawn/activate_at" : "respawn/nextqueued_at"
  let restrictionsText = tmVal > 0 ? mkReasonWithTime(reasonTxt, timerLocId, tmVal) : reasonTxt
  let restrictionsBlock = reason != null
    ? textarea(restrictionsText, {
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
      }.__update(fontSub))
    : null

  let notAffordableBlock = @() textarea(
    loc("respawn/notAffordable", { price = scorePrice, score = spawnScore.value }), {
      watch = spawnScore
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
    }.__update(fontBody))

  let firstSpawnCond = isFirstSpawn.value && (!paratroopersPointSelectorOn.value || paratroopersOn.value)
  let hasForceSpawnButton = firstSpawnCond
    || (availableSpawnZonesCount.value <= 1 && !paratroopersPointSelectorOn.value)
    || (selectedRespawnGroupId.value?[canUseRespawnbaseByType.value] ?? -1) >= 0
  let children = !isAffordable ? [ notAffordableBlock ]
    : !canSpawnCurrent.value ? [ restrictionsBlock ]
    : localPlayerTeamSquadsCanSpawn.value
      ? [
          respawnTimer(loc("respawn/respawn_squad"), fontSub)
          hasForceSpawnButton ? forceSpawnButton()
            : textarea(paratroopersPointSelectorOn.value ? loc("respawn/landingPoint") : loc("respawn/choose_respawn_point"), {
                size = [flex(), SIZE_TO_CONTENT]
                halign = ALIGN_CENTER
              }.__update(fontBody))
          paratroopersButtonBlock
          spawnsLeftText
        ]
      : [
          textarea(loc("respawn/no_spawn_scores"), {
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_CENTER
          }.__update(fontSub))
        ]

  children.extend(spawnInfo)

  return {
    watch = [curSquadData, localPlayerTeamSquadsCanSpawn, canSpawnCurrent,
             respawnBlockedReason, timeLeft, isFirstSpawn, selectedRespawnGroupId,
             availableSpawnZonesCount, paratroopersPointSelectorOn]
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
  hplace = ALIGN_CENTER
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
  addedObj = squadShortcuts
  hasOffset = false
})

let squadSpawnList = {
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  padding = bigPadding
  rendObj = ROBJ_SOLID
  children = [
    squadsListUI
    {
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        @() respawnSquadInfoUi.__update({ padding = 0, rendObj = null })
        spawnInfoBlock
      ]
    }
  ]
}.__update(bgConfig)


let squadRespawn = panel(@() {
    watch = [isFirstSpawn, spawnSquadId]
    size = [SIZE_TO_CONTENT, flex()]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      headerBlock(isFirstSpawn.value
        ? loc("respawn/shooseSquad")
        : loc($"squad/{spawnSquadId.value}")).__update(bgConfig)
      squadSpawnList
    ]
  }
  {
    rendObj = null
    size = [SIZE_TO_CONTENT, flex()]
    flow = FLOW_HORIZONTAL
    gap = smallPadding
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
}.__update(fontHeading1, strokeStyle)


let selectSpawnTitle = @() {
  watch = [ paratroopersPointSelectorOn ]
  rendObj = ROBJ_TEXT
  text = paratroopersPointSelectorOn.value ? loc("respawn/selectLandingPoint") : loc("select_spawn")
}.__update(fontHeading2, strokeStyle)
let showSpawnHint = Computed(@() !isFirstSpawn.value && availableSpawnZonesCount.value > 0)

let selectSpawnHint = @(){
  watch = [showSpawnHint, verPadding]
  hplace = ALIGN_CENTER
  pos = [0, verPadding.value + fsh(10)]
  children = showSpawnHint.value || paratroopersPointSelectorOn.value ? selectSpawnTitle : null
}

return {
  children = [
    squadRespawn
    selectSpawnHint
    missionNameUI
  ]
  size = flex()
}
