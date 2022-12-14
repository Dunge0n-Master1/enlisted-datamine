import "%dngscripts/ecs.nut" as ecs
let {kwarg} = require("%sqstd/functools.nut")
let {chooseRandom} = require("%sqstd/rand.nut")
let {defaultSpawn, setCustomSpawn} = require("%scripts/game/utils/spawn_bot.nut")
let {mkComps} = require("squad_spawn.nut")
let { applyModsToArmies } = require("%scripts/game/utils/profile_init.nut")
let defaultProfile = require("%enlSqGlob/data/bots_profile.nut")
let logerr = require("dagor.debug").logerr

let squadSpawn = kwarg(function(teamEid, team, template, transform, potentialPosition, onBotSpawned) {
  let teamArmies = ecs.obsolete_dbg_get_comp_val(teamEid, "team__armies")?.getAll() ?? []
  let teamSpawnBotArmy = ecs.obsolete_dbg_get_comp_val(teamEid, "team__spawnBotArmy")
  let profile = applyModsToArmies(defaultProfile)
  local squad = profile?[teamSpawnBotArmy].squads[0].squad
  if (!squad)
    foreach (armyId in teamArmies) {
      squad = profile?[armyId].squads[0].squad
      if (squad)
        break
    }
  if (!squad) {
    logerr($"Unable to spawn bot for squad because of not found squad data for team {teamSpawnBotArmy} or [{", ".join(teamArmies)}]")
    return
  }

  let soldier = chooseRandom(squad)
  let aiAttrs = {
    ["transform"] = [transform, ecs.TYPE_MATRIX],
    ["team"] = team,
    ["beh_tree.enabled"] = true,
    ["human_weap__infiniteAmmoHolders"] = true,
    ["human_net_phys__isSimplifiedPhys"] = true,
    ["spawn_immunity__timer"] = [0.0, ecs.TYPE_FLOAT],
    ["beh_tree__blackboard__wishPosition"] = [potentialPosition[0], ecs.TYPE_POINT3],
    ["beh_tree__blackboard__wishPositionSet"] = true,
  }

  aiAttrs.
    __update(mkComps(soldier))

  ecs.g_entity_mgr.createEntity("+".concat(soldier.gametemplate, template), aiAttrs, onBotSpawned)
})

let function spawn(params) {
  let spawnerEid = params?.spawnerEid ?? ecs.INVALID_ENTITY_ID
  if (ecs.obsolete_dbg_get_comp_val(spawnerEid, "bot_spawner__shouldSpawnSquads") ?? false)
    squadSpawn(params)
  else
    defaultSpawn(params)
}

setCustomSpawn(spawn)