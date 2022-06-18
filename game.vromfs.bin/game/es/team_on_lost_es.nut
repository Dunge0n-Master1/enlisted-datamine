import "%dngscripts/ecs.nut" as ecs
let {EventTeamLost, EventTeamRoundResult, broadcastNetEvent, EventTeamWon} = require("dasevents")

let function onTeamLost(evt, _eid, comp) {
  let team = comp["team__id"]
  broadcastNetEvent(EventTeamRoundResult({team, isWon=(team != evt.team)}))
}

let function onTeamWon(evt, _eid, comp) {
  let team = comp["team__id"]
  broadcastNetEvent(EventTeamRoundResult({team, isWon=(team == evt.teamId)}))
}


ecs.register_es("team_on_lost_es",
  {
    [EventTeamLost] = onTeamLost,
    [EventTeamWon] = onTeamWon,
  },
  { comps_ro = [ ["team__id", ecs.TYPE_INT],]},
  {tags = "server"}
)


