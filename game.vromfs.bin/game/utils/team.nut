import "%dngscripts/ecs.nut" as ecs
let { TEAM_UNASSIGNED } = require("team")
let debug = require("%enlSqGlob/library_logs.nut").with_prefix("[TEAM]")
let random = require("dagor.random")

let assignTeamQuery = ecs.SqQuery("assignTeamQuery", {comps_ro =
  [
    ["team__memberEids", ecs.TYPE_EID_LIST],
    ["team__memberCount", ecs.TYPE_FLOAT],
    ["team__id", ecs.TYPE_INT, TEAM_UNASSIGNED],
    ["team__newTeamTemplate", ecs.TYPE_STRING, ""],
    ["team__capacity", ecs.TYPE_INT, -1],
    ["team__locked", ecs.TYPE_BOOL, false],
  ]
})

let newTeamQuery = ecs.SqQuery("newTeamQuery", {comps_rw = [["team__locked", ecs.TYPE_BOOL, false]] comps_ro = [["team__capacity", ecs.TYPE_INT]]})

let function assign_team() { // returns [teamId, teamEid]
  local maxTeamTid = 0
  let availableTeams = []
  local templateToCreate = null
  local minTeamMembers = 1 << 30
  assignTeamQuery(
    function(eid, comp) {
      let tid = comp["team__id"]
      maxTeamTid = max(maxTeamTid, tid)
      templateToCreate = comp["team__newTeamTemplate"]
      if ((comp["team__capacity"] >= 0 && comp["team__memberEids"].len() >= comp["team__capacity"]) || comp["team__locked"])
        return
      minTeamMembers = min(minTeamMembers, comp["team__memberCount"])
      availableTeams.append(eid)
    })

  if (availableTeams.len() == 0 && templateToCreate != null) {
    // create new teams
    let teamId = maxTeamTid + 1
    let comps = {
      ["team__id"] = teamId,
      ["team__should_lock"] = true
    }
    let teamEid = ecs.g_entity_mgr.createEntitySync(templateToCreate, comps)
    newTeamQuery(teamEid,
      function (_eid, comp) {
        if (comp["team__capacity"] == 1)
          comp["team__locked"] = true
      })
    debug($"Created new team with id: {teamId}, eid: {teamEid}")
    return [teamId, teamEid]
  }

  if (minTeamMembers == 1 << 30) { // empty teams?
    debug("No team found")
    return [TEAM_UNASSIGNED, INVALID_ENTITY_ID]
  }

  let filteredTeams = []
  foreach (eid in availableTeams) {
    if (ecs.obsolete_dbg_get_comp_val(eid, "team__memberCount", 0.0) == minTeamMembers)
      filteredTeams.append(eid)
  }

  let teamEid = filteredTeams[random.grnd() % filteredTeams.len()]
  let teamId = ecs.obsolete_dbg_get_comp_val(teamEid, "team__id", TEAM_UNASSIGNED)
  debug($"Found already existing team with id: {teamId}, eid: {teamEid}")
  return [teamId, teamEid]
}

return assign_team
