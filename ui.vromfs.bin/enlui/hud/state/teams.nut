import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {makeEcsHandlers} = require("%ui/mk_ecshandlers.nut")
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")

let teams = mkWatched(persist, "teams", {})

let localPlayerTeamInfo = Computed(function(){
  foreach (team in teams.value) {
    if (team?["team__id"] != null && team?["team__id"] == localPlayerTeam.value)
      return team
  }
  return null
})
let localPlayerTeamMemberCount = Computed(@() localPlayerTeamInfo.value?["team__memberCount"])
let localPlayerTeamIcon = Computed(@() localPlayerTeamInfo.value?["team__icon"])
let localPlayerTeamSquadsCanSpawn = Computed(@() localPlayerTeamInfo.value?["team__squadsCanSpawn"] ?? true)
let localPlayerTeamArmies = Computed(function(prev) {
  let res = localPlayerTeamInfo.value?["team__armies"] ?? []
  return prev != FRP_INITIAL && isEqual(res, prev) ? prev : res
})

let teamsState = {
  teams
  localPlayerTeamIcon
  localPlayerTeamMemberCount
  localPlayerTeamInfo
  localPlayerTeamSquadsCanSpawn
  localPlayerTeamArmies
}

let teams_comps = {
  comps_ro = [
    ["team__id", ecs.TYPE_INT],
    ["team__name", ecs.TYPE_STRING, ""],
    ["team__icon", ecs.TYPE_STRING, ""],
    ["team__armies", ecs.TYPE_STRING_LIST],
  ]
  comps_track = [
    ["team__memberCount", ecs.TYPE_FLOAT, 0.0],
    ["team__hasSpawns", ecs.TYPE_BOOL, true],
    ["team__briefing", ecs.TYPE_STRING, ""],
    ["team__narrator", ecs.TYPE_OBJECT, {}],
    ["team__squadsCanSpawn", ecs.TYPE_BOOL, true],
    ["team__eachSquadMaxSpawns", ecs.TYPE_INT, 0],
  ]
}

ecs.register_es("teams_ui_state_es",
  makeEcsHandlers(teams, teams_comps),
  teams_comps
)

return teamsState
