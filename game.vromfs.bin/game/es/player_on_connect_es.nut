import "%dngscripts/ecs.nut" as ecs
let { TEAM_UNASSIGNED } = require("team")
let debug = require("%enlSqGlob/library_logs.nut").with_prefix("[PLAYER]")
let {get_team_eid} = require("%dngscripts/common_queries.nut")
let assign_team = require("%scripts/game/utils/team.nut")
let {INVALID_CONNECTION_ID, add_entity_in_net_scope, get_sync_time} = require("net")
let {INVALID_USER_ID} = require("matching.errors")

let {EventTeamMemberJoined, EventOnPlayerConnected, CmdSpawnEntityForPlayer} = require("dasevents")

let {get_all_arg_values_by_name} = require("dagor.system")
let {isSandboxContext, getSandboxConfigValue} = require("%scripts/game/es/sandbox_read_config.nut")

let tryToAssignTeamByCommandLine = @(userid)
  get_all_arg_values_by_name("team_for_userid")?.map(@(t) t.split(",")).findvalue(@(t) t[0] == userid.tostring())?[1].tointeger()

let groupMatesQuery = ecs.SqQuery("groupMatesQuery", {
  comps_ro = [["team", ecs.TYPE_INT], ["groupId", ecs.TYPE_INT64]]
  comps_rq = ["player"]
})

let availableTeamStartFromQuery = ecs.SqQuery("availableTeamStartFromQuery", {
  comps_ro = [["availableTeamStartFrom", ecs.TYPE_INT]]
})

let function onPlayerConnected(evt, eid, comp) {
  local wishTeam = evt.wishTeam
  let reconnected = evt.reconnected
  let canSpawnEntity = evt.canSpawnEntity

  let groupId = comp.groupId
  let possessed = comp.possessed
  let team = comp.team

  if (wishTeam == TEAM_UNASSIGNED && team != TEAM_UNASSIGNED) {
    wishTeam = team
  }

  let cmdTeam = tryToAssignTeamByCommandLine(comp.userid)
  if (cmdTeam != null && cmdTeam != TEAM_UNASSIGNED) {
    wishTeam = cmdTeam
    debug($"Team {wishTeam} has been set for {comp.userid} by command line")
  }

  if (isSandboxContext()) {
    let sandboxTeam = getSandboxConfigValue("team", "")
    if (sandboxTeam!="") {
      wishTeam = sandboxTeam
      debug($"Team {wishTeam} has been set for {comp.userid} by sandbox config")
    }
  }

  debug($"Player {eid} with team {team} and groupId {groupId} has been connected and wish to join {wishTeam} team.")

  let availableTeamStartFrom = availableTeamStartFromQuery.perform(@(_eid, comp) comp.availableTeamStartFrom) ?? 0
  if (availableTeamStartFrom > 0 && wishTeam != TEAM_UNASSIGNED) {
    wishTeam += availableTeamStartFrom
    debug($"Player {eid} with team {team} and groupId {groupId} got a new {wishTeam} team. Because avaliable teams count starting from {availableTeamStartFrom}.")
  }

  groupMatesQuery(function(gmEid, gmComp) {
    if (gmEid != eid && gmComp.groupId == groupId && gmComp.team != TEAM_UNASSIGNED) {
      wishTeam = gmComp.team
      return true
    }
  })

  if (wishTeam == TEAM_UNASSIGNED) {
    let [teamId, teamEid] = assign_team()
    debug($"Player {eid} wish to join any team due to wishTeam is {wishTeam}. Assign team {teamId}.")

    wishTeam = teamId
    if (comp.connid != INVALID_CONNECTION_ID)
      add_entity_in_net_scope(teamEid, comp.connid)
  }

  if (reconnected && ecs.g_entity_mgr.doesEntityExist(possessed)) {
    if (!ecs.obsolete_dbg_get_comp_val(possessed, "isAlive", false)) {
      ecs.g_entity_mgr.destroyEntity(possessed)
      comp.possessed = ecs.INVALID_ENTITY_ID
    }
    if (team == TEAM_UNASSIGNED
        || ecs.obsolete_dbg_get_comp_val(get_team_eid(team),"team__allowRebalance", false))
      comp.team = wishTeam
  }
  else
    comp.team = wishTeam

  if (comp.team == team)
    debug($"Player {eid} team {comp.team} it the same.")
  else
    debug($"Player {eid} team has been changed from {team} to {comp.team}")

  if (!reconnected)
    comp.startedAtTime = get_sync_time()
  comp.connectedAtTime = get_sync_time()

  // on reconnect to aborted connection (i.e. disconnect of old connection wasn't handled) possessed entity might still exist
  if (canSpawnEntity && !ecs.g_entity_mgr.doesEntityExist(possessed)) {
    debug($"Spawn spuad for team {comp.team} and player {eid}")
    ecs.g_entity_mgr.sendEvent(eid, CmdSpawnEntityForPlayer({team=comp.team, possessed=ecs.INVALID_ENTITY_ID}));
  }

  if (comp.team != TEAM_UNASSIGNED)
    ecs.g_entity_mgr.broadcastEvent(EventTeamMemberJoined({eid=eid, team=comp.team}))
}

ecs.register_es("player_on_connect_script_es", {
  [EventOnPlayerConnected] = onPlayerConnected,
},
{
  comps_rw=[
    ["team", ecs.TYPE_INT],
    ["possessed", ecs.TYPE_EID],
    ["connectedAtTime", ecs.TYPE_FLOAT],
    ["startedAtTime", ecs.TYPE_FLOAT]
  ]
  comps_ro=[
    ["groupId", ecs.TYPE_INT64],
    ["userid", ecs.TYPE_UINT64, INVALID_USER_ID],
    ["connid", ecs.TYPE_INT, INVALID_CONNECTION_ID]
  ]
  comps_rq=["player"]
})
