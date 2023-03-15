from "%enlSqGlob/ui_library.nut" import *

let {bindSquadROVar, bindSquadRWVar} = require("%enlist/squad/squadManager.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let { crossnetworkPlay } = require("%enlSqGlob/crossnetwork_state.nut")
let { nestWatched } = require("%dngscripts/globalState.nut")
let ready = nestWatched("myExtData.ready", false)
let { maxVersionStr } = require("%enlSqGlob/client_version.nut")
let { get_app_id } = require("app")
let appId = Watched(get_app_id())

bindSquadROVar("inBattle", isInBattleState)
bindSquadRWVar("ready", ready)
bindSquadROVar("crossnetworkPlay", crossnetworkPlay)
bindSquadROVar("version", maxVersionStr)
bindSquadROVar("appId", appId)
