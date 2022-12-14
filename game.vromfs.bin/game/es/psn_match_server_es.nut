import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *
let {get_setting_by_blk_path} = require("settings")
let {DBGLEVEL} = require("dagor.system")
let dedicated = require_optional("dedicated")
let debug = DBGLEVEL > 0 && (get_setting_by_blk_path("testPsnMatch") ?? false)
if (!debug && dedicated == null)
  return

let {INVALID_CONNECTION_ID} = require("net")
let {EventLevelLoaded} = require("gameevents")
let {INVALID_USER_ID} = require("matching.errors")


let {get_matching_mode_info = @() {extraParams = {psnActivityId="undefined"}}} = dedicated

let connectedPsnPlayersQuery = ecs.SqQuery("connectedPsnPlayers",
  {
    comps_rq = ["player"],
    comps_ro = [
      ["platform", ecs.TYPE_STRING, ""],
      ["connid", ecs.TYPE_INT],
      ["playerIdInSession", ecs.TYPE_STRING],
    ],
    comps_rw= [["psnMatchCreationAttempt", ecs.TYPE_INT],]
    comps_no=["playerIsBot"]
  }
  , debug ? "" : $"ne(connid,{INVALID_CONNECTION_ID})"
)

let filterPsnPlayers = @(comp) ["ps5", "ps4"].contains(comp.platform) || debug

let function getPSNMatchLeader(){
  let connectedPSNPayers = []
  connectedPsnPlayersQuery.perform(function(eid, comp) {
    if (filterPsnPlayers(comp))
      connectedPSNPayers.append({attempt=comp.psnMatchCreationAttempt, playerid = comp.playerIdInSession, eid})
    }
  )
  if (connectedPSNPayers.len()==0)
    return {playerid="", eid = ecs.INVALID_ENTITY_ID}
  return connectedPSNPayers.sort(@(a,b) a.attempt<=>b.attempt)[0]
}

ecs.register_es("set_psn_match_server_leader_es",
  {
    function onUpdate(_dt, eid, comp) {
      if (comp.psn_external_match_id != "") {
        ecs.recreateEntityWithTemplates({eid, removeTemplates = [{template = "psn_external_match_id_update", comps = ["psn_external_match_id_update"]}]})
        return
      }
      let leader = getPSNMatchLeader()
      if (leader.playerid != "") {
        comp["psn_external_match_leader"] = leader.playerid
        connectedPsnPlayersQuery.perform(leader.eid, @(_, usercomps) usercomps["psnMatchCreationAttempt"] = usercomps["psnMatchCreationAttempt"]+1)
      }
    },
  },
  {
    comps_ro = [["psn_external_match_id", ecs.TYPE_STRING]]
    comps_rw = [["psn_external_match_leader", ecs.TYPE_STRING]]
    comps_rq = ["psn_external_match_id_update"]
  },
  {tags="server", updateInterval = debug ? 1 : 15, before="*", after="*"}
)

ecs.register_es("set_player_id_in_session_es",
  {
    [["onInit", "onChange"]] = function(eid, comp){
      if (comp.userid == INVALID_USER_ID)
        return
      comp.playerIdInSession = $"{eid}"
    }
  },
  {
    comps_rw = [["playerIdInSession", ecs.TYPE_STRING]]
    comps_track = [["userid", ecs.TYPE_UINT64]]
    comps_rq = ["player"]
  },
  {tags="server"}
)


ecs.register_es("set_psn_match_server_activity_id_es",
  {
    [[EventLevelLoaded, "onInit"]] = function onInit(_eid, comp){
      let {extraParams = null} = get_matching_mode_info()
      let activity_id = extraParams?.psnActivityId
      let is_team_required = extraParams?.psnActivityRequiresTeams ?? false
      log($"got psn activity_id by matching: {activity_id}, teams: {is_team_required}")
      if (activity_id == null)
        return
      comp["psn_activity_id"] = activity_id
      comp["psn_activity_requires_teams"] = is_team_required
    }
  },
  {
    comps_rw = [
      ["psn_activity_id", ecs.TYPE_STRING],
      ["psn_activity_requires_teams", ecs.TYPE_BOOL]
    ]
  },
  {tags="server"}
)


ecs.register_es("set_psn_match_server_es",
  {
    [ecs.sqEvents.CmdPsnExternalMatchId] = function(evt, _eid, comp){
      if (comp.psn_external_match_id == "" && (evt?.data.match_id ?? "") != "" && comp.psn_external_match_leader == evt?.data.player_id)
        comp["psn_external_match_id"] = $"{evt?.data.match_id}"
    },
  },
  {
    comps_ro = [["psn_external_match_leader", ecs.TYPE_STRING],]
    comps_rw = [["psn_external_match_id", ecs.TYPE_STRING],]
  },
  {tags="server"}
)
