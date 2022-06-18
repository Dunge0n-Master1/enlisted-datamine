import "%dngscripts/ecs.nut" as ecs
let { TEAM_UNASSIGNED } = require("team")
let { EventPlayerPossessedEntityDied } = require("dasevents")
let { get_sync_time } = require("net")

let function onPlayerEntityDied(_eid, comp) {
  comp["scoring_player__deathTime"] = get_sync_time()
  if (comp.team != TEAM_UNASSIGNED)
    comp["scoring_player__deaths"] += 1
}


ecs.register_es("scoring_player", {
    [EventPlayerPossessedEntityDied] = onPlayerEntityDied
  },
  {
    comps_rw = [
      ["scoring_player__deathTime", ecs.TYPE_FLOAT],
      ["scoring_player__deaths", ecs.TYPE_INT],
    ]

    comps_ro = [
      ["possessed", ecs.TYPE_EID],
      ["team", ecs.TYPE_INT]
    ]
  },
  {tags = "server"}
)
