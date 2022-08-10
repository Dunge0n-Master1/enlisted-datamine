import "%dngscripts/ecs.nut" as ecs
let { TEAM_UNASSIGNED } = require("team")
let debug = require("%enlSqGlob/library_logs.nut").with_prefix("[SPAWN]")
let {CmdSpawnEntityForPlayer} = require("dasevents")
let {get_sync_time} = require("net")
let {get_team_eid} = require("%dngscripts/common_queries.nut")
let {spawnSoldier,rebalance} = require("%scripts/game/utils/spawn.nut")

let function onSpawn(evt, eid, comp) {
  local team = evt.team
  let possessed = evt.possessed

  if (possessed != INVALID_ENTITY_ID)
    team = rebalance(team, eid)

  if (team == TEAM_UNASSIGNED) {
    debug($"onSpawnSquad: Cannot create player possessed entity for team {team}")
    return
  }

  let teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  debug($"onSpawn: Team = {team}")

  if (teamEid == INVALID_ENTITY_ID) {
    debug($"onSpawnSquad: Cannot create player possessed entity for team {team} because of teamEid is invalid")
    return
  }

  spawnSoldier({team = team, playerEid = eid, possessed = possessed})

  if (comp["scoring_player__firstSpawnTime"] <= 0.0)
    comp["scoring_player__firstSpawnTime"] = get_sync_time()
}

ecs.register_es("spawn_es", {
    [CmdSpawnEntityForPlayer] = onSpawn,
  },
  { comps_rw = [["scoring_player__firstSpawnTime", ecs.TYPE_FLOAT]],
    comps_no = ["customSpawn"]
  })
