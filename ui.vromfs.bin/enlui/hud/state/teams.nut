import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")
let {teams, teamsSetKeyVal, teamsDeleteKey} = mkFrameIncrementObservable({}, "teams")

let localPlayerTeamInfo = Computed(function(){
  foreach (team in teams.value) {
    if (team?["team__id"] != null && team?["team__id"] == localPlayerTeam.value)
      return team
  }
  return null
})
let localPlayerTeamIcon = Computed(@() localPlayerTeamInfo.value?["team__icon"])
let localPlayerTeamSquadsCanSpawn = Computed(@() localPlayerTeamInfo.value?["team__squadsCanSpawn"] ?? true)
let localPlayerTeamArmies = Computed(function(prev) {
  let res = localPlayerTeamInfo.value?["team__armies"] ?? []
  return prev != FRP_INITIAL && isEqual(res, prev) ? prev : res
})


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
let fullCompsList = [].extend(teams_comps.comps_ro, teams_comps.comps_track)

ecs.register_es("teams_ui_state_es",
  {
    [["onInit", "onChange"]] = function(_, eid, comp){
      let entry = {}
      foreach (v in fullCompsList)
        entry[v[0]] <- comp?[v[0]]?.getAll() ?? comp[v[0]]
      teamsSetKeyVal(eid, entry)
    },
    onDestroy = @(_, eid, __) teamsDeleteKey(eid)
  },
  teams_comps
)

return {
  teams
  localPlayerTeamIcon
  localPlayerTeamInfo
  localPlayerTeamSquadsCanSpawn
  localPlayerTeamArmies
}
