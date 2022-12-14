import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {get_sync_time} = require("net")
let {debriefingShow, debriefingData} = require("debriefingStateInBattle.nut")
let {localPlayerNamePrefixIcon} = require("%ui/hud/state/player_state_es.nut")
let {localPlayerName, localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let {EventTeamRoundResult, CmdGetDebriefingResult, broadcastNetEvent} = require("dasevents")
let { remap_nick } = require("%enlSqGlob/remap_nick.nut")
let { get_session_id } = require("app")
let { missionName, missionType } = require("%enlSqGlob/missionParams.nut")
let psnMatchIdQuery = ecs.SqQuery("psnMatchInfoQuery", {comps_ro=[["psn_external_match_id", ecs.TYPE_STRING]]})
let getPsnMatchId = @() (psnMatchIdQuery.perform(@(_, comp) comp.psn_external_match_id) ?? "")
let { isTutorial } = require("%ui/hud/tutorial/state/tutorial_state.nut")
let { isPractice } = require("%ui/hud/state/practice_state.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")


let teamComps = {
  comps_ro = [
    ["team__id", ecs.TYPE_INT],
    ["team__winSubtitle", ecs.TYPE_STRING],
    ["team__loseSubtitle", ecs.TYPE_STRING],
    ["team__deserterSubtitle", ecs.TYPE_STRING, ""],
    ["team__winTitle", ecs.TYPE_STRING],
  ]
}
let teamsQuery = ecs.SqQuery("debriefingTeamQuery", teamComps)

enum STATUS {
  WIN,
  LOSE,
  FINISHED_EARLY,
  DESERTER
}

let langsByStatus = {
  [STATUS.WIN]        = { titleLocId = "debriefing/victory", subtitleCompId = "team__winSubtitle"},
  [STATUS.LOSE]       = { titleLocId = "debriefing/defeat", subtitleCompId = "team__loseSubtitle"},
  [STATUS.FINISHED_EARLY] = { titleLocId = "debriefing/finished_early" },
  [STATUS.DESERTER]   = { titleLocId = "debriefing/deserter", subtitleCompId = "team__deserterSubtitle"},
}

/*
    debriefing data should be done on server and send via netMessage
    It is not safe and correct to assume that player can correctly calculate everything by his own data!
    this data can be out of sync, obsolete, not full, etc.
    moreover - it definitely can be full if we are goind to show information about other players in debriefing
    so this code should be moved to game and should become sample where you can find how to correctly get data by player and send it to player
    todo:
      - make per player debriefing event and send it per player from server to player entity
      - killer and players list should have info (enlisted part)
      - listen only to perplayer event

*/

let function setResult(comp, status) {
  let debriefing = {
    sessionId = get_session_id()
    psnMatchId = getPsnMatchId() ?? ""
    playerName = remap_nick(localPlayerName.value)
    playerNamePrefixIcon = localPlayerNamePrefixIcon.value
    missionName = loc(missionName.value, { mission_type = loc($"missionType/{missionType.value}") })
    missionType = missionType.value

    result = {
      status = status
      title = loc(langsByStatus[status].titleLocId)
      subtitle = loc(langsByStatus[status]?.subtitleCompId) ?? ""
      success = status == STATUS.WIN
      fail = status == STATUS.LOSE
      deserter = status == STATUS.DESERTER
      finishedEarly = status == STATUS.FINISHED_EARLY
      time = get_sync_time()
      who = status == STATUS.WIN ? loc(comp["team__winTitle"]) : ""
    }
  }
  debriefingData(debriefing)

  if (isTutorial.value == true || isPractice.value == true) {
    debriefingShow(false)
  }
}

let function onTeamRoundResult(evt, _eid, comp) {
  if (localPlayerTeam.value != comp["team__id"] || debriefingShow.value)
    return
  let status = evt.isWon == (evt.team == comp["team__id"])
    ? STATUS.WIN : STATUS.LOSE
  log("[DEBRIEFING] Receive battle result via onTeamRoundResult")
  setResult(comp, status)
}

let function onGetBattleResult(_evt, _eid, playerComp) {
  if (debriefingShow.value || isReplay.value)
    return
  let status = playerComp["scoring_player__isGameFinished"] ? STATUS.FINISHED_EARLY : STATUS.DESERTER
  teamsQuery.perform(
    function(_eid, comp) {
      if (localPlayerTeam.value != comp["team__id"])
        return
      log("[DEBRIEFING] Receive battle result via onGetBattleResult")
      setResult(comp, status)
    })
}


ecs.register_es("roundresult_debriefing_es",
  {[EventTeamRoundResult] = onTeamRoundResult,},
  teamComps
)

ecs.register_es("deserter_debriefing_es",
  {
    [CmdGetDebriefingResult] = onGetBattleResult,
  },
  {
    comps_rq = ["player"]
    comps_ro = [["scoring_player__isGameFinished", ecs.TYPE_BOOL, false]]
  })


console_register_command(function() {
  broadcastNetEvent(EventTeamRoundResult({team=localPlayerTeam.value, isWon=true}))
}, "ui.broadcast_win")

console_register_command(function() {
  broadcastNetEvent(EventTeamRoundResult({team=localPlayerTeam.value, isWon=false}))
}, "ui.broadcast_defeat")
