import "%dngscripts/ecs.nut" as ecs

let {FLT_MAX} = require("math")
let {Point3, TMatrix} = require("dagor.math")
let {traceray_normalized, rayhit_normalized} = require("dacoll.trace")
let {traceray_navmesh, project_to_nearest_navmesh_point_no_obstacles, check_path, POLYFLAG_GROUND, POLYFLAG_JUMP} = require("pathfinder")
let {find_human_respawn_base} = require("das.respawn")

let function traceBinarySearch(pos, max_ht, err_term) {
  let hitT = traceray_normalized(Point3(pos.x, (max_ht + pos.y) * 0.5, pos.z), Point3(0.0, -1.0, 0.0), max_ht - pos.y)
  if (hitT != null) {
    let resHt = (max_ht + pos.y) * 0.5 - hitT
    if (resHt - pos.y < err_term)
      return Point3(pos.x, resHt, pos.z)
    return traceBinarySearch(pos, resHt, err_term)
  }
  return Point3(pos.x, max_ht, pos.z)
}

let function traceSearch(pos, top_offs) {
  let t = top_offs
  if (!rayhit_normalized(pos, Point3(0.0, -1.0, 0.0), t)) {
    let hitT = traceray_normalized(pos + Point3(0.0, top_offs, 0.0), Point3(0.0, -1.0, 0.0), top_offs)
    if (hitT != null) {
      let maxHt = pos.y + top_offs - hitT
      return traceBinarySearch(pos, maxHt, 0.4)
    }
  }
  return pos
}

let function validatePosition(tm, orig_pos, horz_extents = 0.75) {
  local wishPos = tm.getcol(3)
  let rayPos = traceray_navmesh(orig_pos, wishPos, 0.25)
  wishPos = traceSearch(rayPos, 1000.0)
  let projExtents = Point3(horz_extents, FLT_MAX, horz_extents)
  let navmeshPos = project_to_nearest_navmesh_point_no_obstacles(wishPos, projExtents)
  let resPos = check_path(navmeshPos, wishPos, 0.1, 0.5, 1.5, POLYFLAG_GROUND | POLYFLAG_JUMP) ? navmeshPos : wishPos
  let resTm = TMatrix(tm)
  resTm.orthonormalize()
  resTm.setcol(3, resPos)
  return resTm;
}

let validateTm = @(tm, horz_extents = 0.75) validatePosition(tm, tm.getcol(3), horz_extents)

let function createInventory(inventory) {
  let itemContainer = ecs.CompEidList()
  foreach (item in inventory) {
    let count = item?.count ?? 1
    for (local i = 0; i < count; i++) {
      itemContainer.append(ecs.EntityId(ecs.g_entity_mgr.createEntity(item.gametemplate, {})))
    }
  }
  return [ itemContainer, ecs.TYPE_EID_LIST ]
}

let gatherSpawnParamsMap = {
  ["transform"]                 = ["transform", ecs.TYPE_MATRIX],
  ["start_vel"]                 = ["respbase__start_vel", ecs.TYPE_POINT3, null],
  ["noSpawnImmunity"]           = ["respbase__noSpawnImmunity", ecs.TYPE_BOOL, false],
  ["spawnImmunityTime"]         = ["respbase__spawnImmunityTime", ecs.TYPE_FLOAT, null],
  ["shouldValidateTm"]          = ["respbase__shouldValidateTm", ecs.TYPE_BOOL, true],
  ["startVelDir"]               = ["respbase__startVelDir", ecs.TYPE_POINT3, null],
  ["startRelativeSpeed"]        = ["respbase__startRelativeSpeed", ecs.TYPE_FLOAT, null],
  ["addTemplatesOnSpawn"]       = ["respbase__addTemplatesOnSpawn", ecs.TYPE_STRING_LIST, null],
  ["isValidated"]               = ["respbase__validated", ecs.TYPE_BOOL, false],
}

let gatherSpawnParamsQuery = ecs.SqQuery("gatherSpawnParamsQuery", {comps_ro = gatherSpawnParamsMap.values()})

let function gatherParamsFromEntity(eid, query, map) {
  let params = {}
  query.perform(eid, function(_eid, comp) {
    foreach (paramName, compName in map) {
      let compValue = comp[compName[0]]
      if (compValue != null)
        params[paramName] <- compValue?.getAll != null ? compValue.getAll() : compValue
    }
  })
  return params
}

let gatherSpawnParams = @(eid) gatherParamsFromEntity(eid, gatherSpawnParamsQuery, gatherSpawnParamsMap)

let function mkSpawnParamsByTeamImpl(team, findBaseCb) {
  let baseEid = findBaseCb(team)
  if (baseEid == ecs.INVALID_ENTITY_ID)
    return null

  let params = {
    baseEid = baseEid
    team = team
  }

  params.__update(gatherSpawnParams(baseEid))

  if (!params.isValidated)
    params.transform = validateTm(params.transform)

  return params
}

let mkSpawnParamsByTeam = @(team)
  mkSpawnParamsByTeamImpl(team, find_human_respawn_base)

return {
  validatePosition
  validateTm
  mkSpawnParamsByTeam
  mkSpawnParamsByTeamEx = mkSpawnParamsByTeamImpl
  createInventory
}
