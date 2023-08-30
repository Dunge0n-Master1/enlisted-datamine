from "%enlSqGlob/ui_library.nut" import *


let {TEAM_UNASSIGNED} = require("team")
let {TEAM0_COLOR_FG, TEAM1_COLOR_FG, TEAM0_COLOR_FG_TR, TEAM1_COLOR_FG_TR} = require("%ui/hud/style.nut")
let {lerp} = require("%sqstd/math.nut")
let {get_sync_time} = require("net")

let transformCenterPivot = {pivot = [0.5, 0.5]}
let animCapturing = [
  { prop=AnimProp.opacity, from=0.1, to=1.0, duration=1.0, play=true, loop=true, easing=CosineFull}
]
let animBombTicking = animCapturing

let NEUTRAL_TRANSP = Color(80,80,80,80)
let INACTIVATED_ZONE_FG = Color(160, 150, 120)
let CAPTURE_ZONE_BG = Color(80, 75, 50, 160)
let LOCK_ZONE_FG = Color(160, 160, 160, 160)

let defaultImage = Picture("ui/skin#circle_progress.avif")
let defendImage = Picture("!ui/skin#icon_defend.avif")

let function getZoneProgressIcon(capzone_data, hero_team, size, color) {
  let isDefendZone = capzone_data.attackTeam > TEAM_UNASSIGNED && capzone_data.attackTeam != hero_team && capzone_data.bombPlantingTeam == TEAM_UNASSIGNED
  let zoneDefendProgress = {
    rendObj = ROBJ_PROGRESS_CIRCULAR
    image = isDefendZone
      ? defendImage
      : defaultImage
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
  }
  return zoneDefendProgress.__merge({
    size
    transform = transformCenterPivot
    bgColor = color.bg
    fgColor = color.fg
  })
}

let function getCapZoneColors(capzone_data, hero_team) {
  local colorFg = null
  local colorBg = null

  let currentlyNoCap = capzone_data.capTeam == TEAM_UNASSIGNED || capzone_data.progress == 0.0
  let noLongerActive = !capzone_data.active && capzone_data.wasActive

  if (capzone_data.onlyTeamCanCapture == TEAM_UNASSIGNED) {
    if (currentlyNoCap || !noLongerActive) {
      colorBg = NEUTRAL_TRANSP
    }
    else {
      colorBg = CAPTURE_ZONE_BG
    }
  }
  else if (capzone_data.onlyTeamCanCapture == hero_team) {
    colorBg = TEAM1_COLOR_FG
  }
  else {
    colorBg = TEAM0_COLOR_FG
  }

  if (currentlyNoCap) {
    if (noLongerActive) {
      colorFg = INACTIVATED_ZONE_FG
    }
    else {
      colorFg = NEUTRAL_TRANSP
    }
  }
  else {
    if (capzone_data.capTeam == hero_team) {
      colorFg = capzone_data.active ? TEAM0_COLOR_FG : TEAM0_COLOR_FG_TR
    }
    else {
      colorFg = capzone_data.active ? TEAM1_COLOR_FG : TEAM1_COLOR_FG_TR
    }
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

let function mkGenericProgress(zoneData, heroTeam, zone_progress_icon, _color, progress, is_animation_available) {
  let zoneGeneric = zone_progress_icon.__merge({
    fValue = progress
  })
  let progressIndicator = !zoneData.isCapturing ? null
    : zoneGeneric.__merge({
      fgColor = (zoneData.curTeamCapturingZone == heroTeam) ? TEAM0_COLOR_FG : TEAM1_COLOR_FG
      animations = is_animation_available ? animCapturing : null
      key = zoneData.eid
    })

  return zoneGeneric.__merge({
    children = progressIndicator
  })
}

let mkLockProgress = @(capzone_data, _hero_team, zone_progress_icon, _color, _progress, _is_animation_available)
zone_progress_icon.__merge({
    behavior = Behaviors.RtPropUpdate
    fgColor = LOCK_ZONE_FG
    fValue = 1
    update = function() {
      this.fValue = getLockProgress(capzone_data)
    }
  })

let function mkTrainProgress(zoneData, heroTeam, zone_progress_icon, color, progress, is_animation_available) {
  let hasConflict = zoneData.curTeamCapturingZone < TEAM_UNASSIGNED
  let zoneGeneric = zone_progress_icon.__merge({
    fgColor = zoneData.curTeamCapturingZone == heroTeam ? TEAM0_COLOR_FG
      : (zoneData.curTeamCapturingZone > TEAM_UNASSIGNED || hasConflict) ? TEAM1_COLOR_FG
      : color.fg
    fValue = progress
  })
  let progressIndicator = !hasConflict ? null
    : zoneGeneric.__merge({
      fgColor = TEAM0_COLOR_FG
      animations = is_animation_available ? animCapturing : null
      key = zoneData.eid
    })

  return zoneGeneric.__merge({
    children = progressIndicator
  })
}

let function mkBombProgress(zoneData, heroTeam, zone_progress_icon, _color, progress, isAnimationAvailable) {
  let zoneGeneric = zone_progress_icon.__merge({
    behavior = Behaviors.RtPropUpdate
    fValue = 0
    update = function() {
      let currentProgress = getZoneProgress(zoneData) ?? progress
      this.fValue = zoneData.isBombPlanted ? (1 - currentProgress) : currentProgress
    }
  })

  let isHeroTeamPlanting = zoneData.bombPlantingTeam == heroTeam

  let zoneCapturing = zoneGeneric.__merge({
    fgColor = isHeroTeamPlanting ? TEAM0_COLOR_FG : TEAM1_COLOR_FG
    key = {}
    animations = zoneData.isBombPlanted && isAnimationAvailable ? animBombTicking : null
  })

  return zoneGeneric.__merge({
    children = zoneCapturing
  })
}

let function mkProgress(capzone_data, hero_team, size, is_animation_available = true) {
  let color = getCapZoneColors(capzone_data, hero_team)
  let {progress, trainZone, locked, bombPlantingTeam} = capzone_data

  let isBombZone = bombPlantingTeam > -1

  let zoneProgressIcon = getZoneProgressIcon(capzone_data, hero_team, size, color)

  let progressCtor = locked
    ? mkLockProgress
    : isBombZone
      ? mkBombProgress
      : capzone_data.trainZone
        ? mkTrainProgress
        : mkGenericProgress

  local prgs = 0
  if (trainZone)
    prgs = 1
  else if (progress >= 1.0)
    prgs = 1
  else if (progress > 0.0)
    prgs = lerp(0, 1, 0.015, 0.985, progress)
  return progressCtor(capzone_data, hero_team, zoneProgressIcon, color, prgs, is_animation_available)
}

return mkProgress
