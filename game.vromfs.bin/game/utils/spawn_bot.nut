import "%dngscripts/ecs.nut" as ecs
let selectRandom = require("%scripts/game/utils/random_list_selection.nut")
let {kwarg} = require("%sqstd/functools.nut")

local customSpawn = null

let defaultSpawn = kwarg(function(teamEid, team, template, transform, potentialPosition, onBotSpawned) {
  let botTemplates = ecs.obsolete_dbg_get_comp_val(teamEid, "team__botTemplates").getAll()
  let weaponTemplates = ecs.obsolete_dbg_get_comp_val(teamEid, "team__weaponTemplates").getAll()

  let finalTemplate = ecs.makeTemplate({addTemplates = [selectRandom(botTemplates), selectRandom(weaponTemplates), template]})

  let comps = {
    "transform" : [transform, ecs.TYPE_MATRIX],
    "team" : [team, ecs.TYPE_INT],
    "spawn_immunity__timer" : [0.0, ecs.TYPE_FLOAT],
    "beh_tree__blackboard__wishPosition" : [potentialPosition[0], ecs.TYPE_POINT3],
    "beh_tree__blackboard__wishPositionSet" : [true, ecs.TYPE_BOOL],
  }
  ecs.g_entity_mgr.createEntity(finalTemplate, comps, onBotSpawned)
})

return {
  spawn = @(params) (customSpawn ?? defaultSpawn)(params)

  defaultSpawn = defaultSpawn
  setCustomSpawn = function(func) { customSpawn = func }
}