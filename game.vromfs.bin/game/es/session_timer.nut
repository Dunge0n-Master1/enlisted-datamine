import "%dngscripts/ecs.nut" as ecs
/*
  here we do nothing on NO players and if time is over find team with maximum Score and send Won event
  - check onUpdate each second and send event if time is over
*/
let { TEAM_UNASSIGNED } = require("team")
let {EventTeamWon} = require("dasevents")

let findBestTeamQuery = ecs.SqQuery("findBestTeamQuery", {comps_ro = [["team__roundScore", ecs.TYPE_INT], ["team__id", ecs.TYPE_INT]]})
let function onSessionTimeFinished(){
  local maxRoundScore = 0
  local bestTeamId = TEAM_UNASSIGNED
  findBestTeamQuery.perform(function(_eid, comp) {
    let rscore = comp["team__roundScore"]
    if (rscore > maxRoundScore) {
      maxRoundScore = rscore
      bestTeamId = comp["team__id"]
    }
  })
  ecs.g_entity_mgr.broadcastEvent(EventTeamWon({teamId=bestTeamId}))
}

let function onUpdate(dt, _eid, comp) {
  local timeLeft = comp["session_timer__time_left"]
  if (timeLeft < 0.0)
    return

  timeLeft -= dt
  comp["session_timer__time_left"] = timeLeft
  if (timeLeft < 0.0)
    onSessionTimeFinished()
}

ecs.register_es("session_timer_es",
  {onUpdate = onUpdate},
  {comps_rw = [["session_timer__time_left",ecs.TYPE_FLOAT]]},
  { updateInterval = 1.0, tags = "server", after="*", before="*" }
)

