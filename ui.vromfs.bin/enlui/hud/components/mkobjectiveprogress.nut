from "%enlSqGlob/ui_library.nut" import *

#explicit-this

let {TEAM_UNASSIGNED} = require("team")
let {TEAM0_COLOR_FG, TEAM1_COLOR_FG, TEAM0_COLOR_FG_TR, TEAM1_COLOR_FG_TR} = require("%ui/hud/style.nut")
let {lerp} = require("%sqstd/math.nut")
let {get_sync_time} = require("net")

let ZoneProgress = {
  rendObj = ROBJ_PROGRESS_CIRCULAR
  image = Picture("ui/skin#circle_progress.png")
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
}

let ZoneDefendProgress = {
  rendObj = ROBJ_PROGRESS_CIRCULAR
  image = Picture("!ui/skin#icon_defend.png")
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
}

let transformCenterPivot = {pivot = [0.5, 0.5]}
let animCapturing = [
  { prop=AnimProp.opacity, from=0.1, to=1.0, duration=1.0, play=true, loop=true, easing=CosineFull}
]
let animBombTicking = animCapturing

let NEUTRAL_TRANSP = Color(80,80,80,80)
let INACTIVATED_ZONE_FG = Color(160, 150, 120)
let CAPTURE_ZONE_BG = Color(80, 75, 50, 160)
let LOCK_ZONE_FG = Color(160, 160, 160, 160)

let function getCapZoneColors(capzone_data, heroTeam, bright = false) {
  local colorFg = null
  local colorBg = null
  if (capzone_data.capTeam == TEAM_UNASSIGNED || capzone_data.progress == 0.0) {
    if (!capzone_data.active && capzone_data.wasActive) {
      colorFg = INACTIVATED_ZONE_FG
      colorBg = CAPTURE_ZONE_BG
    } else if (bright) {
      colorFg = Color(160, 160, 160)
      colorBg = Color(160, 160, 160)
    } else {
      colorFg = NEUTRAL_TRANSP
      colorBg = NEUTRAL_TRANSP
    }
  } else if (capzone_data.capTeam == heroTeam) {
    colorFg = capzone_data.active ? TEAM0_COLOR_FG : TEAM0_COLOR_FG_TR
    colorBg = CAPTURE_ZONE_BG
  } else {
    colorFg = capzone_data.active ? TEAM1_COLOR_FG : TEAM1_COLOR_FG_TR
    colorBg = CAPTURE_ZONE_BG
  }
  return { fg = colorFg, bg = colorBg }
}

let function getZoneProgress(zoneData) {
  let {progressEndTime=-1, progressPausedAt=-1, progressTotalTime=-1, progressIsPositive=1} = zoneData
  if (progressPausedAt >= 0)
    return progressPausedAt
  if (progressTotalTime <= 0 && progressEndTime < 0)
    return null
  let timeLeft = max(progressEndTime - get_sync_time(), 0)
  return progressIsPositive
    ? (1 - (timeLeft / progressTotalTime))
    : (timeLeft / progressTotalTime)
}

let function getLockProgress(zoneData) {
  let {endLockTime=-1, unlockAfterTime=-1} = zoneData
  if (unlockAfterTime <= 0 && endLockTime < 0)
    return 1
  let timeLeft = max(endLockTime - get_sync_time(), 0)
  return timeLeft / unlockAfterTime
}

let function mkGenericProgress(zoneData, heroTeam, size, color, progress, isAnimationAvailable) {
  let zoneGeneric = ZoneProgress.__merge({
    size
    transform = transformCenterPivot
    bgColor = color.bg
    fgColor = color.fg
    fValue = progress
  })
  let progressIndicator = !zoneData.isCapturing ? null
    : zoneGeneric.__merge({
      bgColor = CAPTURE_ZONE_BG
      fgColor = (zoneData.curTeamCapturingZone == heroTeam) ? TEAM0_COLOR_FG : TEAM1_COLOR_FG
      animations = zoneData.isCapturing && isAnimationAvailable ? animCapturing : null
      key = zoneData.eid
    })

  return zoneGeneric.__merge({
    children = progressIndicator
  })
}

let mkLockProgress = @(zoneData, _heroTeam, size, color, _progress, _isAnimationAvailable)
  ZoneProgress.__merge({
    size
    behavior = Behaviors.RtPropUpdate
    bgColor = color.bg
    fgColor = LOCK_ZONE_FG
    fValue = 1
    update = function() {
      this.fValue = getLockProgress(zoneData)
    }
  })

let function mkTrainProgress(zoneData, heroTeam, size, color, progress, isAnimationAvailable) {
  let hasConflict = zoneData.curTeamCapturingZone < TEAM_UNASSIGNED
  let zoneGeneric = ZoneProgress.__merge({
    size
    transform = transformCenterPivot
    bgColor = color.bg
    fgColor = zoneData.curTeamCapturingZone == heroTeam ? TEAM0_COLOR_FG
      : (zoneData.curTeamCapturingZone > TEAM_UNASSIGNED || hasConflict) ? TEAM1_COLOR_FG
      : color.fg
    fValue = progress
  })
  let progressIndicator = !hasConflict ? null
    : zoneGeneric.__merge({
      bgColor = CAPTURE_ZONE_BG
      fgColor = TEAM0_COLOR_FG
      animations = isAnimationAvailable ? animCapturing : null
      key = zoneData.eid
    })

  return zoneGeneric.__merge({
    children = progressIndicator
  })
}

let function mkBombProgress(zoneData, heroTeam, size, color, progress, isAnimationAvailable) {
  let zoneGeneric = ZoneProgress.__merge({
    size
    behavior = Behaviors.RtPropUpdate
    transform = transformCenterPivot
    bgColor = color.bg
    fgColor = color.fg
    fValue = 0
    update = function() {
      let currentProgress = getZoneProgress(zoneData) ?? progress
      this.fValue = zoneData.isBombPlanted ? (1 - currentProgress) : currentProgress
    }
  })

  let isHeroTeamPlanting = zoneData.bombPlantingTeam == heroTeam

  let zoneCapturing = zoneGeneric.__merge({
    bgColor = CAPTURE_ZONE_BG
    fgColor = isHeroTeamPlanting ? TEAM0_COLOR_FG : TEAM1_COLOR_FG
    key = {}
    animations = zoneData.isBombPlanted && isAnimationAvailable ? animBombTicking : null
  })

  return zoneGeneric.__merge({
    children = zoneCapturing
  })
}

let function mkDefendProgress(zoneData, heroTeam, size, color, progress, isAnimationAvailable) {
  let zoneDefendProgressCapturing = ZoneDefendProgress.__merge({
    size
    transform = transformCenterPivot
    bgColor = CAPTURE_ZONE_BG
    fgColor = (zoneData?.active) ? (zoneData.capTeam == heroTeam) ? TEAM0_COLOR_FG : TEAM1_COLOR_FG : color.fg
    fValue = progress
  })

  return zoneDefendProgressCapturing.__merge({
    size
    transform = transformCenterPivot
    children = zoneData.isCapturing
      ? zoneDefendProgressCapturing.__merge({
          key = zoneData.eid
          animations = isAnimationAvailable ? animCapturing : null
          bgColor = (zoneData.curTeamCapturingZone == heroTeam) ? TEAM0_COLOR_FG : TEAM1_COLOR_FG
          transform = transformCenterPivot
        })
      : null
  })
}

let function mkProgress(zoneData, heroTeam, size, isAnimationAvailable = true) {
  let color = getCapZoneColors(zoneData, heroTeam)
  let {progress, trainZone, locked, attackTeam, bombPlantingTeam} = zoneData

  let isDefendZone = attackTeam > -1 && attackTeam != heroTeam
  let isBombZone = bombPlantingTeam > -1

  let progressCtor = locked
    ? mkLockProgress
    : isBombZone
      ? mkBombProgress
      : zoneData.trainZone
        ? mkTrainProgress
        : isDefendZone
          ? mkDefendProgress
          : mkGenericProgress

  local prgs = 0
  if (trainZone)
    prgs = 1
  else if (progress >= 1.0)
    prgs = 1
  else if (progress > 0.0)
    prgs = lerp(0, 1, 0.015, 0.985, progress)
  return progressCtor(zoneData, heroTeam, size, color, prgs, isAnimationAvailable)
}

return mkProgress
