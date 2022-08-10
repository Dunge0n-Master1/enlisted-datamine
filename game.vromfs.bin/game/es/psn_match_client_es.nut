import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *

let isDedicated = require_optional("dedicated") != null
if (isDedicated)
  return

let {has_network} = require("net")
let {EventTeamRoundResult, EventSessionFinished} = require("dasevents")
let {EventOnDisconnectedFromServer} = require("gameevents")
let { get_local_player_team } = require("%dngscripts/common_queries.nut")
let {get_setting_by_blk_path} = require("settings")
let {DBGLEVEL} = require("dagor.system")


let find_local_player_id_compsQuery = ecs.SqQuery("find_local_player_uid_compsQuery", {
    comps_ro = [
      ["is_local", ecs.TYPE_BOOL],
      ["playerIdInSession", ecs.TYPE_STRING]
    ],
    comps_rq = ["player"]
  }, "is_local")

let function getPlayerId(){
  let playerid = find_local_player_id_compsQuery.perform(@(_eid, comp) comp.playerIdInSession) ?? ""
  if (playerid != "")
    return playerid
  return null
}

let debug = DBGLEVEL > 0 && (get_setting_by_blk_path("testPsnMatch") ?? false)

let dbgLog = @(...) log_for_user.acall([null, "[PSNM]"].extend(vargv))

let platform = require("%dngscripts/platform.nut")
if (!(platform.is_ps5 || debug))
  return

let { psnSend,
        psnMatchCreate, psnMatchJoin, psnMatchLeave, psnMatchUpdateStatus, psnMatchReportResults,
        PSN_MATCH_STATUS_PLAYING,
        PSN_MATCH_LEAVE_REASON_FINISHED, PSN_MATCH_LEAVE_REASON_QUIT, PSN_MATCH_LEAVE_REASON_DISCONNECTED
      } = require("%sonyLib/webApi.nut")

let accountIdString = platform.is_ps5 ? require("sony.user").accountIdString : "0123456789"

let function makePlayerRec(comp) {
  let player = {
    playerId = $"{comp.playerIdInSession}"
    accountId = accountIdString
    playerType = "PSN_PLAYER"
  }

  if (comp.psn_activity_requires_teams)
    player["teamId"] <- $"{get_local_player_team()}"

  return player
}

let function joinPsnMatch(matchId, comp){
  if (matchId!="") {
    dbgLog("join", matchId)
    psnSend(psnMatchJoin(matchId, makePlayerRec(comp)))
  }
}

let function startPsnMatch(matchId, comp) {
  if (matchId != "")
    psnSend(psnMatchUpdateStatus(matchId, PSN_MATCH_STATUS_PLAYING), @(_r, _e) joinPsnMatch(matchId, comp))
}

let function onEventTeamRoundResult(evt, _eid, comp) {
  if (comp.psn_local_user_leaved_match)
    return
  let matchId = comp.psn_external_match_id
  dbgLog("updating match results for", matchId)
  let {team, isWon} = evt
  let teamResults = [
    { teamId = $"{team}", rank = $"{isWon ? 1 : 2}" },
    { teamId = $"{3 - team}", rank = $"{isWon ? 2 : 1}" } // we have only two teams for now
  ]
  psnSend(psnMatchReportResults(matchId, { teamResults }))
  comp.psn_local_user_leaved_match = true
}

let function leavePsnMatch(comp, reason=null){
  let matchId = comp.psn_external_match_id
  if (comp.psn_local_user_leaved_match)
    return
  if (matchId != "") {
    dbgLog("leave", matchId)
    psnSend(psnMatchLeave(matchId, {
      playerId = $"{comp.playerIdInSession}"
      reason = reason ?? PSN_MATCH_LEAVE_REASON_QUIT
    }))
    comp.psn_local_user_leaved_match = true
  }
}

let createPsnMatch = debug
  ? @(eid, comp) ecs.client_send_event(
      eid,
      ecs.event.CmdPsnExternalMatchId({
        match_id = "123456789",
        player_id = comp.playerIdInSession
      })
    )
  : function(eid, comp) {
      let activityId = comp.psn_activity_id
      let playerId = comp.playerIdInSession
      if (activityId == "" || playerId == "")
        return

      let inGameRoster = { players = [makePlayerRec(comp)] }
      let hasTeams = comp.psn_activity_requires_teams
      if (hasTeams)
        inGameRoster["teams"] <- [{teamId="1"}, {teamId="2"}]
      let matchCreateRequest = psnMatchCreate({activityId, inGameRoster })
      dbgLog("create", activityId)
      psnSend(matchCreateRequest, function(resp, err){
        if (err!=null)
          dbgLog("psn matchCreateRequest failed", err)
        else if (resp?.matchId!=null) {
          dbgLog($"psn match created {activityId} - {resp.matchId}")
          startPsnMatch(resp.matchId, comp)
          ecs.client_send_event(
            eid,
            ecs.event.CmdPsnExternalMatchId({
              match_id = $"{resp.matchId}",
              player_id = playerId
            })
          )
        }
      })
    }

let function joinOrCreatePsnMatch(eid, comp) {
  let isMatchCreated = comp.psn_external_match_id != ""
  let playerId = getPlayerId()
  if (playerId)
    comp.playerIdInSession = playerId

  let isMatchLeader = comp.psn_external_match_leader == comp.playerIdInSession
  if (!isMatchCreated && isMatchLeader) {
    createPsnMatch(eid, comp)
  }
  else if (isMatchCreated && !isMatchLeader)
    joinPsnMatch(comp.psn_external_match_id, comp)
}

ecs.register_es("psn_match_client_es",
  {
    function onInit(eid, comp){
      if (!(has_network() || debug))
        return
      joinOrCreatePsnMatch(eid, comp)
    },
    function onChange(eid, comp){
      joinOrCreatePsnMatch(eid, comp)
    },
    [EventTeamRoundResult] = onEventTeamRoundResult,
    function onDestroy(_eid, comp){
      leavePsnMatch(comp, PSN_MATCH_LEAVE_REASON_QUIT)
    },
    [EventSessionFinished] = function(_eid, comp){
      dbgLog("EventSessionFinished: leaving match")
      leavePsnMatch(comp, PSN_MATCH_LEAVE_REASON_FINISHED)
    },
    [EventOnDisconnectedFromServer] = function(_eid, comp){
      dbgLog("EventDisconnectedFromServer: leaving match")
      leavePsnMatch(comp, PSN_MATCH_LEAVE_REASON_DISCONNECTED)
    }
  },
  {
    comps_track = [
      ["psn_external_match_id", ecs.TYPE_STRING],
      ["psn_external_match_leader", ecs.TYPE_STRING],
      ["psn_activity_id", ecs.TYPE_STRING, ""],
      ["psn_activity_requires_teams", ecs.TYPE_BOOL, false]
    ],
    comps_rw = [
      ["psn_local_user_leaved_match", ecs.TYPE_BOOL],
      ["playerIdInSession", ecs.TYPE_STRING]
    ]
  },
  {tags = debug ? "" : "gameClient"}
)
