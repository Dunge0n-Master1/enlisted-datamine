import "%dngscripts/ecs.nut" as ecs
let { TEAM_UNASSIGNED } = require("team")
let {EventAnyEntityDied, EventTeamLost} = require("dasevents")

let teamAliveMembersQuery = ecs.SqQuery("teamAliveMembersQuery", {comps_ro=[["team", ecs.TYPE_INT],["isAlive", ecs.TYPE_BOOL]],comps_rq=["countAsAlive"]}, "isAlive")

let function onEntityDied(evt, _eid, comp) {
  let victimEid = evt.victim
  let team = ecs.obsolete_dbg_get_comp_val(victimEid, "team", TEAM_UNASSIGNED)
  if (team != comp["team__id"])
    return
  local deathPenalty = comp["team__deathPenalty"]
  deathPenalty += comp["team__memberEids"].len() * comp["team__deathPenaltyByMember"]
  deathPenalty = max(deathPenalty, comp["team__minDeathPenalty"])
  if (deathPenalty > 0)
    if (deathPenalty >= comp["team__score"]) {
      comp["team__score"] = 0
      if (comp["team__zeroScoreFailTimer"] < 0) {
        ecs.g_entity_mgr.broadcastEvent(EventTeamLost({team=comp["team__id"]}))
        return
      }
    }
    else
      comp["team__score"] -= deathPenalty

  if (comp["team__zeroScoreFailTimer"] > 0) {
    local team_alive_player_count = 0
    teamAliveMembersQuery.perform(function(...) {
      team_alive_player_count++
    }, "and(eq(isAlive,true),eq(team,{0}))".subst(comp["team__id"]))
    if (comp["team__score"] <= 0 && team_alive_player_count == 0) {
      ecs.g_entity_mgr.broadcastEvent(EventTeamLost({team=comp["team__id"]}))
    }
  }
}

ecs.register_es("team_on_death_es",
  {
    [EventAnyEntityDied] = onEntityDied,
  },
  {
    comps_rw = [
      ["team__score", ecs.TYPE_FLOAT],
    ]

    comps_ro = [
      ["team__id", ecs.TYPE_INT],
      ["team__deathPenalty", ecs.TYPE_FLOAT],
      ["team__memberEids", ecs.TYPE_EID_LIST],
      ["team__deathPenaltyByMember", ecs.TYPE_FLOAT, 0],
      ["team__minDeathPenalty", ecs.TYPE_FLOAT, 0],
      ["team__zeroScoreFailTimer", ecs.TYPE_FLOAT],
    ]
  },
  {tags = "server"}
)

