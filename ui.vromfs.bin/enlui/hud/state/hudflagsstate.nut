from "%enlSqGlob/ui_library.nut" import *

let { forcedMinimalHud } = require("%ui/hud/state/hudGameModes.nut")
let { showSquadSpawn } = require("%ui/hud/state/respawnState.nut")
let { isTutorial } = require("%ui/hud/tutorial/state/tutorial_state.nut")
let { isAlive } = require("%ui/hud/state/health_state.nut")
let { debriefingShow } = require("%ui/hud/state/debriefingStateInBattle.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")
let { minimalistHud, showSelfAwards, showTips, showGameModeHints, showPlayerUI } = require("%ui/hud/state/hudOptionsState.nut")
let { showBigMap } = require("%ui/hud/menus/big_map.nut")
let { canShowGameHudInReplay } = require("%ui/hud/replay/replayState.nut")
let { tutorialPlaneShootEnable } = require("%ui/hud/state/tutorial_input_state_es.nut")

const HUD_BIT_FULL = 1
const HUD_BIT_MINIMAL = 2 // hardcore or minimalist
const HUD_BIT_SHOW_AWARDS = 3
const HUD_BIT_NO_BIG_MAP = 4
const HUD_BIT_NO_HARDCORE = 5 // define by game mode rule
const HUD_BIT_NO_MINIMALIST = 6 // define in user settings
const HUD_BIT_NO_SQUAD_SPAWN = 7
const HUD_BIT_SQUAD_SPAWN = 8
const HUD_BIT_TUTORIAL = 9
const HUD_BIT_PLAYER = 10
const HUD_BIT_REPLAY = 11
const HUD_BIT_NO_REPLAY = 12
const HUD_BIT_GAME_HUD = 13
const HUD_BIT_NO_TUTORIAL = 14
const HUD_BIT_SHOW_TIPS = 15
const HUD_BIT_SHOW_GAME_MODE_HINTS = 16
const HUD_BIT_PLAYER_UI = 17
const HUD_BIT_VEHICLE_CROSSHAIR = 18

let HUD_FLAGS = {
  FULL = 1 << HUD_BIT_FULL
  MINIMAL = 1 << HUD_BIT_MINIMAL
  SHOW_AWARDS = 1 << HUD_BIT_SHOW_AWARDS
  NO_BIG_MAP = 1 << HUD_BIT_NO_BIG_MAP
  NO_HARDCORE = 1 << HUD_BIT_NO_HARDCORE
  NO_MINIMALIST = 1 << HUD_BIT_NO_MINIMALIST
  NO_SQUAD_SPAWN = 1 << HUD_BIT_NO_SQUAD_SPAWN
  SQUAD_SPAWN = 1 << HUD_BIT_SQUAD_SPAWN
  TUTORIAL = 1 << HUD_BIT_TUTORIAL
  PLAYER = 1 << HUD_BIT_PLAYER
  REPLAY = 1 << HUD_BIT_REPLAY
  NO_REPLAY = 1 << HUD_BIT_NO_REPLAY
  GAME_HUD = 1 << HUD_BIT_GAME_HUD
  NO_TUTORIAL = 1 << HUD_BIT_NO_TUTORIAL
  SHOW_TIPS = 1 << HUD_BIT_SHOW_TIPS
  SHOW_GAME_MODE_HINTS = 1 << HUD_BIT_SHOW_GAME_MODE_HINTS
  PLAYER_UI = 1 << HUD_BIT_PLAYER_UI
  VEHICLE_CROSSHAIR = 1 << HUD_BIT_VEHICLE_CROSSHAIR
}

let minHud = keepref(Computed(@() forcedMinimalHud.value || minimalistHud.value))
let showHuds = Computed(@() !(!isAlive.value || debriefingShow.value))

let hudFlags = Computed(@() (!minHud.value).tointeger() << HUD_BIT_FULL
  | minHud.value.tointeger() << HUD_BIT_MINIMAL
  | showSelfAwards.value.tointeger() << HUD_BIT_SHOW_AWARDS
  | (!showBigMap.value).tointeger() << HUD_BIT_NO_BIG_MAP
  | (!forcedMinimalHud.value).tointeger() << HUD_BIT_NO_HARDCORE
  | (!minimalistHud.value).tointeger() << HUD_BIT_NO_MINIMALIST
  | (!showSquadSpawn.value).tointeger() << HUD_BIT_NO_SQUAD_SPAWN
  | showSquadSpawn.value.tointeger() << HUD_BIT_SQUAD_SPAWN
  | isTutorial.value.tointeger() << HUD_BIT_TUTORIAL
  | showHuds.value.tointeger() << HUD_BIT_PLAYER
  | isReplay.value.tointeger() << HUD_BIT_REPLAY
  | (!isReplay.value).tointeger() << HUD_BIT_NO_REPLAY
  | (!isReplay.value || canShowGameHudInReplay.value).tointeger() << HUD_BIT_GAME_HUD
  | (!isTutorial.value).tointeger() << HUD_BIT_NO_TUTORIAL
  | showTips.value.tointeger() << HUD_BIT_SHOW_TIPS
  | showGameModeHints.value.tointeger() << HUD_BIT_SHOW_GAME_MODE_HINTS
  | showPlayerUI.value.tointeger() << HUD_BIT_PLAYER_UI
  | tutorialPlaneShootEnable.value.tointeger() << HUD_BIT_VEHICLE_CROSSHAIR)

return {
  HUD_FLAGS
  hudFlags
  mkHudElement = @(element) ((hudFlags.value & element.flags) == element.flags) ? element.comp : null
}
