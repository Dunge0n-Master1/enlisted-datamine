import "%dngscripts/ecs.nut" as ecs
let { TEAM_UNASSIGNED } = require("team")
let { EventBotSpawned, mkEventBotSpawned } = require("%enlSqGlob/sqevents.nut")
let random = require("dagor.random")
let {get_team_eid} = require("%dngscripts/common_queries.nut")
let {find_respawn_base_for_team} = require("das.respawn")
let {spawn} = require("%scripts/game/utils/spawn_bot.nut")
let {fill_walkable_positions_around} = require("navmesh")

let botWaveTimerId = "botWaveTimerId"

let function onWaveTimer(_evt, eid, comp) {
  let teamToSpawnFor = comp["team"]
  let respBaseTeam = ecs.obsolete_dbg_get_comp_val(eid, "bot_spawner__respTeam", teamToSpawnFor)

  ecs.set_timer({eid=eid, id=botWaveTimerId, interval = comp["bot_spawner__wavePeriod"], repeat = false})
  let respBase = find_respawn_base_for_team(respBaseTeam)
  if (respBase == ecs.INVALID_ENTITY_ID)
    return

  if (teamToSpawnFor == TEAM_UNASSIGNED)
    return
  let teamEid = get_team_eid(teamToSpawnFor)
  if (teamEid == null)
    return

  let transform = ecs.obsolete_dbg_get_comp_val(respBase, "transform")
  let attractPoints = comp["bot_spawner__attractPoints"].getAll()
  let spawnDist = comp["bot_spawner__attractDist"]
  let maxAlive = comp["bot_spawner__maxAlive"]
  local spawnedAliveEntities = comp["bot_spawner__spawnedAliveEntities"].getAll()
  if (maxAlive > 0) {
    let res = []
    foreach (v in spawnedAliveEntities){
      if (ecs.obsolete_dbg_get_comp_val(v, "isAlive", false))
        res.append(v)
    }
    spawnedAliveEntities = res
    if (spawnedAliveEntities.len() >= maxAlive)
      return
  }

  let wishPosition = attractPoints[random.rnd() % attractPoints.len()]
  let potentialPosition = array(1)
  if (fill_walkable_positions_around(wishPosition, potentialPosition, spawnDist, 1.0))
    spawn({
      spawnerEid = eid,
      teamEid = teamEid,
      team = teamToSpawnFor,
      template = comp["bot_spawner__template"],
      transform = transform,
      potentialPosition = potentialPosition,
      onBotSpawned = @(new_eid) ecs.g_entity_mgr.sendEvent(eid, mkEventBotSpawned({ eid = new_eid }))
    })
}

let function onInit(eid, _comp){
  ecs.clear_timer({eid=eid, id=botWaveTimerId})
  ecs.set_timer({eid=eid, id=botWaveTimerId, interval=0.5, repeat=false})
}

let comps = {
  comps_rw  = [["bot_spawner__spawnedAliveEntities", ecs.TYPE_ARRAY]],
  comps_ro = [
    ["bot_spawner__attractPoints", ecs.TYPE_ARRAY],
    ["bot_spawner__attractDist", ecs.TYPE_FLOAT],
    ["bot_spawner__maxAlive", ecs.TYPE_INT, -1],
    ["team", ecs.TYPE_INT],
    ["bot_spawner__template",ecs.TYPE_STRING],
    ["bot_spawner__wavePeriod",ecs.TYPE_FLOAT],
    ["bot_spawner__shouldSpawnSquads", ecs.TYPE_BOOL, false],
  ]
}
ecs.register_es("bot_spawner_timer_es", {
  Timer = onWaveTimer,
}, comps, {tags="server"})

ecs.register_es("bot_spawner_on_spawn_es",
  {
    [EventBotSpawned] = function(evt, _eid, comp){
      comp["bot_spawner__spawnedAliveEntities"].append(evt.data.eid)
    }
  },
  {comps_rw  = [["bot_spawner__spawnedAliveEntities", ecs.TYPE_ARRAY]]},
  {tags="server"}
)

ecs.register_es("bot_spawner_init_es", {
    onInit = onInit
  }, { comps_rq  = ["bot_spawner__spawnedAliveEntities", "bot_spawner__template"]},
  {tags="server"})


