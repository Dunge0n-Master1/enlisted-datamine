import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { TEAM0_COLOR_FG, TEAM1_COLOR_FG, DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")
let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let {
  gunGameFriendlyTeamProgress, gunGameEnemyTeamProgress, gunGamePlayerProgress,
  gunGameLevelCount, gunGameLevelKillsDone, gunGameLevelKillsRequire,
  gunGameLeaderPlayerEid, gunGameLeaderName, gunGameLeaderTeam
} = require("%ui/hud/state/gun_game_state.nut")
let { localPlayerTeam, localPlayerEid } = require("%ui/hud/state/local_player.nut")

let LEVELS_COLOR_BG = Color(50, 50, 50, 150)
let levelsPointSize = [hdpxi(8), hdpxi(8)]
let levelsPointSpacing = hdpx(18)
let levelsLineHeight = fsh(0.5)

let levelsPointImage = Picture("ui/skin#train/train_point.svg:{0}:{1}:K".subst(levelsPointSize[0], levelsPointSize[1]))

let progressMarkerSize = [hdpxi(24), hdpxi(30)]
let progressMarkerTextSize = hdpx(10)

let progressMarkerImage = Picture("!ui/skin#teammate_arrow_white.svg:{0}:{1}:K".subst(progressMarkerSize[0], progressMarkerSize[1]))


let mkProgressMarker = @(text, color, invert) @() {
  valign = ALIGN_BOTTOM
  vplace = invert ? ALIGN_BOTTOM : ALIGN_TOP
  size = progressMarkerSize
  margin = progressMarkerSize[1]/2
  children = [
    {
      rendObj = ROBJ_IMAGE
      image = progressMarkerImage
      transform = {rotate = invert ? 180.0 : 0.0}
      size = progressMarkerSize
      color
    }
    {
      rendObj = ROBJ_INSCRIPTION
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      padding = invert ? [0, 0, hdpx(2), hdpx(1)] : [hdpx(3), 0, 0, hdpx(1)]
      text
      fontSize = progressMarkerTextSize
    }
  ]
}

let levelsSpacingLine = {
  vplace = ALIGN_CENTER
  size = [levelsPointSpacing, levelsLineHeight]
  rendObj = ROBJ_SOLID
  color = LEVELS_COLOR_BG
}

let progressMarkerOrDummy = @(level, progress, color, inverted)
  level == progress.value ? mkProgressMarker(progress.value + 1, color, inverted) : null

let mkLevelsPoint = @(level) function() {
  let getLevelPointColor = @() level <= gunGameFriendlyTeamProgress.value
    ? TEAM0_COLOR_FG
    : level <= gunGameEnemyTeamProgress.value
      ? TEAM1_COLOR_FG
      : Color(100,100,100,200)

  let children = [
    gunGamePlayerProgress.value != gunGameFriendlyTeamProgress.value
      ? progressMarkerOrDummy(level, gunGameFriendlyTeamProgress, Color(70,90,250,215), true)
      : null
    progressMarkerOrDummy(level, gunGamePlayerProgress, Color(150,255,160,215), true)
    progressMarkerOrDummy(level, gunGameEnemyTeamProgress, Color(250,70,70,215), false)
  ]

  return {
    watch = [gunGameFriendlyTeamProgress, gunGameEnemyTeamProgress, gunGamePlayerProgress]
    size = levelsPointSize
    color = getLevelPointColor()
    rendObj = ROBJ_IMAGE
    image = levelsPointImage
    halign = ALIGN_CENTER
    children
  }
}



let function mkLevelsAndProgressBlock() {
  let children = [mkLevelsPoint(0)]

  for (local i = 1; i < gunGameLevelCount.value; i++) {
    children.append(levelsSpacingLine)
    children.append(mkLevelsPoint(i))
  }

  return {
    flow = FLOW_HORIZONTAL
    gap = hdpx(1)
    children
  }
}

let currentLevelKillsInfo = {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    halign = ALIGN_RIGHT
    size = [0, SIZE_TO_CONTENT]
    children = [
      @() {
        watch = [gunGameLevelKillsDone, gunGameLevelKillsRequire]
        rendObj = ROBJ_TEXT
        size = [hdpx(55), SIZE_TO_CONTENT]
        text = $"{gunGameLevelKillsDone.value} / {gunGameLevelKillsRequire.value}"
        color = DEFAULT_TEXT_COLOR
      }.__update(fontBody)
      {
        rendObj = ROBJ_IMAGE
        image = Picture("ui/skin#skull_white.svg:{0}:{0}:K".subst(hdpxi(32)))
        color = Color(150,150,150,100)
        size = [hdpx(32), hdpx(32)]
      }
    ]
}

let leaderBlock = @() {
  watch = [gunGameLeaderPlayerEid, gunGameLeaderName, gunGameLeaderTeam, localPlayerEid, localPlayerTeam]
  flow = FLOW_HORIZONTAL
  size = [0, SIZE_TO_CONTENT]
  children = gunGameLeaderPlayerEid.value == ecs.INVALID_ENTITY_ID ? null : [
    {
      rendObj = ROBJ_INSCRIPTION
      text = loc("gun_game/currentLeader")
    }
    {
      rendObj = ROBJ_TEXT
      color = gunGameLeaderPlayerEid.value == localPlayerEid.value
        ? Color(150,255,160,215)
        : gunGameLeaderTeam.value == localPlayerTeam.value
          ? Color(70,90,250,215)
          : Color(250,70,70,215)
      text = $"{gunGameLeaderName.value}"
    }
  ]
}

let GunGameModeUI = {
  padding = [0, 0, hdpx(32), 0]
  gap = fsh(3)
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    currentLevelKillsInfo
    mkLevelsAndProgressBlock
    leaderBlock
  ]
}

let isGunGameMode = Computed(@() gunGameLevelCount.value > 0)

return {
  isGunGameMode
  GunGameModeUI
}