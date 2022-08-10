import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {TEAM_UNASSIGNED} = require("team")

let teamQuery = ecs.SqQuery("teamQuery", {comps_ro = [["team", ecs.TYPE_INT]]})
let getTeam = @(eid) teamQuery.perform(eid, @(_eid, comp) comp["team"]) ?? TEAM_UNASSIGNED

return {
  getTeam
}