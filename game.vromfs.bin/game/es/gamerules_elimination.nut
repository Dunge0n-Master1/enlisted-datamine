import "%dngscripts/ecs.nut" as ecs
let { TEAM_UNASSIGNED } = require("team")
let {EventAnyEntityDied, EventTeamLost, EventTeamMemberLeave} = require("dasevents")
let {find_connected_player_that_possess} = require("%dngscripts/common_queries.nut")

let lastMemberQuery = ecs.SqQuery("lastMemberQuery", {comps_rw = ["team__roundScore"], comps_ro = ["team__id"]})
let setTimerQuery = ecs.SqQuery("setTimerQuery", {comps_rq = ["team_respawner"]})
let function onLastMember(comp) {
  comp["elimination__numDeaths"] = comp["elimination__numDeaths"] + 1
  let myTeam = comp["team__id"]
  lastMemberQuery.perform(
    function(_eid, comp) {
      comp["team__roundScore"] += 1
    }, "ne(team__id,{0})".subst(myTeam))
  if (comp["elimination__numDeaths"] >= comp["elimination__maxRounds"])
    ecs.g_entity_mgr.broadcastEvent(EventTeamLost({team=comp["team__id"]}))
  else {
    // force respawn by query
    setTimerQuery.perform(function(team_eid, _team_comp) {
      ecs.set_timer({eid=team_eid, id="respawn_timer", interval=0.5, repeat=false})
    })
  }
}

let checkLastMemberQuery = ecs.SqQuery("checkLastMemberQuery", {comps_ro = ["team", "possessed"], comps_rq=["player"]})
let function checkLastMember(comp, pl_eid) {
  // iterate through players only
  if (comp["team__hasSpawns"])
    return

  local aliveMembers = 0
  checkLastMemberQuery.perform(function(p_eid, p_comp) {
    if (p_eid != pl_eid && p_comp["team"] != comp["team__id"] && ecs.obsolete_dbg_get_comp_val(comp["possessed"], "isAlive", false))
      aliveMembers++
    }
  )
  if (aliveMembers==0)
    onLastMember(comp)
}

let function onEntityDied(evt, _eid, comp) {
  let reid = evt.victim
  if (comp["team__id"] == ecs.obsolete_dbg_get_comp_val(reid, "team", TEAM_UNASSIGNED)) {
    let plEid = find_connected_player_that_possess(reid) ?? ecs.INVALID_ENTITY_ID
    checkLastMember(comp, plEid)
  }
}

let function onMemberLeft(evt, _eid, comp) {
  if (comp["team__id"] == evt.team)
    checkLastMember(comp, evt.eid)
}

let comps = {
  comps_rw = [
    ["elimination__numDeaths", ecs.TYPE_INT],
  ]
  comps_ro = [
    ["team__id", ecs.TYPE_INT],
    ["team__hasSpawns", ecs.TYPE_BOOL],
    ["elimination__maxRounds", ecs.TYPE_INT],
  ]
}

ecs.register_es("gamerules_elimination_es", {
  [EventAnyEntityDied] = onEntityDied,
  [EventTeamMemberLeave] = onMemberLeft,
}, comps, {tags = "server"})

