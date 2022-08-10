import "%dngscripts/ecs.nut" as ecs
let {TEAM_UNASSIGNED} = require("team")

let findCapzoneQuery = ecs.SqQuery("findCapzoneQuery", {comps_ro = [["groupName", ecs.TYPE_STRING],
                                      ["active", ecs.TYPE_BOOL],["capzone__progress", ecs.TYPE_FLOAT],
                                      ["capzone__mustBeCapturedByTeam", ecs.TYPE_INT, TEAM_UNASSIGNED],
                                      ["capzone__activateAfterCap", ecs.TYPE_STRING, ""],
                                      ["capzone__capTeam", ecs.TYPE_INT]] comps_rq=["capzone"]})

let isZoneCapturedByTeam =
  @(comps, teamId) teamId == comps["capzone__capTeam"] &&
                   teamId == comps["capzone__mustBeCapturedByTeam"] &&
                   comps["capzone__progress"] >= 0.99

let function allZonesInGroupCapturedByTeam(skipEid, teamId, groupName){
  local allZonesCaptured = true
  findCapzoneQuery(function(qEid, comps) {
    if (comps["active"] &&
        skipEid != qEid &&
        groupName == comps["groupName"] &&
        !isZoneCapturedByTeam(comps, teamId))
      allZonesCaptured = false
  })
  return allZonesCaptured
}

let isLastSectorForTeam = @(teamId) !(findCapzoneQuery(function(_, comps) {
  if (!isZoneCapturedByTeam(comps, teamId) && comps["capzone__activateAfterCap"] != "")
    return true
}) ?? false)

return {
  allZonesInGroupCapturedByTeam,
  isLastSectorForTeam
}
