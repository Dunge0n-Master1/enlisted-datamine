import "%dngscripts/ecs.nut" as ecs
let {CmdSpawnEntity} = require("dasevents")
let {get_sync_time} = require("net")
let {spawnSoldier} = require("%scripts/game/utils/spawn.nut")

let function onSpawn(evt, eid, comp) {
  spawnSoldier({team = evt.team, playerEid = eid, spawnParams = {transform = evt.tm, team = evt.team, respawnReason=evt.reason}})

  if (comp["scoring_player__firstSpawnTime"] <= 0.0)
    comp["scoring_player__firstSpawnTime"] = get_sync_time()
}

ecs.register_es("spawn_at_transform_es", {
    [CmdSpawnEntity] = onSpawn,
  },
  { comps_rw = [["scoring_player__firstSpawnTime", ecs.TYPE_FLOAT]],
    comps_no = ["customSpawn"]
  })

