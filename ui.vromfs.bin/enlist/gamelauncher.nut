import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let { launch_network_session } = require("app")
let statsd = require("statsd")
let msgbox = require("%enlist/components/msgbox.nut")
let { EventGameSessionFinished, EventGameSessionStarted } = require("dasevents")

let lastGame = mkWatched(persist, "lastGame", null)
let extraGameLaunchParams = mkWatched(persist, "extraGameLaunchParams", {})

let isRealBattleStarted = Watched(false)

let function setNotInBattle(){
  if (isRealBattleStarted.value)
    return
  isInBattleState(false)
}

local function startGame(params) {
  console_print("Launching game client...")
  params = params.__merge(extraGameLaunchParams.value)
  if ((params?.modHashes ?? "") != "" && params?.modId == null)
    params.modId <- "blob";
  log("starting game with params", params.filter(@(_,k) k!="authKey" && k!="modFile"))

  if (isInBattleState.value) {
    msgbox.show({text=loc("msgboxtext/gameIsRunning")})
    return
  }

  isInBattleState(true) //to not wait dedicated answer and event EventGameSessionStarted
  gui_scene.resetTimeout(30, setNotInBattle)
  statsd.send_counter("game_launch", 1)
  lastGame(params)
  launch_network_session(params)
}
ecs.register_es(
  "script_game_launcher_es",
  {
    [EventGameSessionFinished] = function() {
      isInBattleState(false)
      isRealBattleStarted(false)
    },
    [EventGameSessionStarted] = function() {
      gui_scene.clearTimer(setNotInBattle)
      isInBattleState(true)
      isRealBattleStarted(true)
    }
  }
)

return {
  startGame
  lastGame
  extraGameLaunchParams
}
