import "%dngscripts/ecs.nut" as ecs
require("%scripts/game/es/team.nut")

let {kwarg} = require("%sqstd/functools.nut")
let { TEAM_UNASSIGNED } = require("team")
let debug = require("%enlSqGlob/library_logs.nut").with_prefix("[SPAWN]")
let {logerr} = require("dagor.debug")
let {FLT_MAX, sin, cos, PI} = require("math")
let {Point3, TMatrix, cvt} = require("dagor.math")
let dagorRandom = require("dagor.random")
let {traceray_normalized, rayhit_normalized} = require("dacoll.trace")
let {traceray_navmesh, project_to_nearest_navmesh_point_no_obstacles, check_path, POLYFLAG_GROUND, POLYFLAG_JUMP} = require("pathfinder")
let {EventPlayerRebalanced} = require("gameevents")
let {EventTeamMemberLeave, EventTeamMemberJoined, CmdPossessEntity} = require("dasevents")
let {get_team_eid} = require("%dngscripts/common_queries.nut")
let {find_human_respawn_base, find_vehicle_respawn_base} = require("%scripts/game/utils/respawn_base.nut")
let {get_sync_time} = require("net")
let { apply_customization=@(_t,_l,c,_p) c } = require_optional("playerCustomization")

let teamMembersQuery = ecs.SqQuery("teamMembersQuery", {comps_ro=[["team__memberCount", ecs.TYPE_FLOAT], ["team__id", ecs.TYPE_INT]]})

local function rebalance(teamId, playerEid) {
  let teamEid = get_team_eid(teamId) ?? INVALID_ENTITY_ID
  if (!ecs.obsolete_dbg_get_comp_val(teamEid, "team__allowRebalance", true))
    return teamId

  local minTeam = TEAM_UNASSIGNED
  let myTeamPlayers = ecs.obsolete_dbg_get_comp_val(teamEid, "team__memberCount", 0.0)
  local minTeamPlayers = FLT_MAX

  teamMembersQuery.perform(function(_eid, comp) {
    if (comp["team__id"] != teamId && comp["team__memberCount"] < minTeamPlayers) {
      minTeamPlayers = comp["team__memberCount"]
      minTeam = comp["team__id"]
    }
  })

  debug($"myTeamPlayers {myTeamPlayers} > minTeamPlayers {minTeamPlayers}")

  if (myTeamPlayers > minTeamPlayers + 1.0) {
    debug($"switching to {minTeam} team")
    let prevTeam = teamId;
    teamId = minTeam;
    ecs.g_entity_mgr.broadcastEvent(EventTeamMemberLeave({eid=playerEid, team=prevTeam}))
    ecs.g_entity_mgr.broadcastEvent(EventTeamMemberJoined({eid=playerEid, team=teamId}))
    ecs.obsolete_dbg_set_comp_val(playerEid, "team", teamId)
    ecs.g_entity_mgr.sendEvent(playerEid, EventPlayerRebalanced(prevTeam, teamId))
  }

  return teamId
}

let function calcNewbieArmor(battlesPlayed) {
  let minBattlesToArmor = 2
  let maxBattlesToArmor = 5
  let maxArmor = 0.12

  return battlesPlayed >= 0 ? cvt(battlesPlayed, minBattlesToArmor, maxBattlesToArmor, maxArmor, 0.0) : 0.0
}

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

let function selectRandomTemplate(templates) {
  local totalWt = 0.0
  let templateList = []
  foreach (key, wt in templates) {
    totalWt += wt
    templateList.append({ key = key, wt = totalWt })
  }
  if (templateList.len()) {
    let curWt = dagorRandom.gfrnd() * totalWt;
    foreach (templ in templateList)
      if (curWt <= templ.wt)
        return templ.key;
  }
  return null
}

let function getTeamWeaponPresetTemplateName(team) {
  let teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  let templates = ecs.obsolete_dbg_get_comp_val(teamEid, "team__weaponTemplates")
  let templ = templates ? selectRandomTemplate(templates) : null
  if (templ)
    return templ
  return ecs.obsolete_dbg_get_comp_val(teamEid, "team__weaponTemplate")
}

let possessedAppendTemplateQuery = ecs.SqQuery("possessedAppendTemplateQuery", {comps_ro=[ ["possessedAppendTemplate", ecs.TYPE_STRING] ]})
let function getAppendTemplate() {
  local appendTemplate = ""
  possessedAppendTemplateQuery.perform(function(_eid, comp) {
    let append = comp.possessedAppendTemplate
    appendTemplate = appendTemplate.len() > 0 ? $"{appendTemplate}+{append}" : append
  })
  return appendTemplate
}
let concatTemplates = @(...) "+".join(vargv)

let function getTeamUnitTemplateName(team, playerEid) {
  let appendTemplate = getAppendTemplate()
  debug($"getTeamUnitTemplateName: append template: {appendTemplate}")
  let playerPossessedTemplate = ecs.obsolete_dbg_get_comp_val(playerEid, "possessedTemplate", "")
  if (playerPossessedTemplate.len() > 0)
    return concatTemplates(playerPossessedTemplate, appendTemplate)
  let teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  let templates = ecs.obsolete_dbg_get_comp_val(teamEid, "team__unitTemplates")
  let templ = templates ? selectRandomTemplate(templates) : null
  if (templ)
    return concatTemplates(templ, appendTemplate)
  let unitTemplate = ecs.obsolete_dbg_get_comp_val(teamEid, "team__unitTemplate")
  return concatTemplates(unitTemplate, appendTemplate)
}

let function createInventory(inventory) {
  let itemContainer = ecs.CompEidList()
  foreach (item in inventory)
    itemContainer.append(ecs.EntityId(ecs.g_entity_mgr.createEntity(item.gametemplate, {})))
  return [ itemContainer, ecs.TYPE_EID_LIST ]
}

let function initItemContainer(eid) {
  let itemContainer = ecs.obsolete_dbg_get_comp_val(eid, "itemContainer")?.getAll() ?? []
  foreach (itemEid in itemContainer)
    if (ecs.g_entity_mgr.doesEntityExist(itemEid))
      ecs.obsolete_dbg_set_comp_val(itemEid, "item__lastOwner", ecs.EntityId(eid))
}

let playersByTeamQuery = ecs.SqQuery("teamPlayersQuery", {comps_ro = [["possessed", ecs.TYPE_EID], ["team", ecs.TYPE_INT]], comps_rq = ["player"]})

let function getPlayerPositionsByTeam(team) {
  let positions = [[],[]]
  playersByTeamQuery.perform(function(_eid, comp) {
    if (!ecs.g_entity_mgr.doesEntityExist(comp.possessed))
      return
    let tm = ecs.obsolete_dbg_get_comp_val(comp.possessed, "transform")
    let isAlive = ecs.obsolete_dbg_get_comp_val(comp.possessed, "isAlive", false)
    positions[isAlive ? 0 : 1].append(tm.getcol(3))
  }, $"eq(team,{team})")
  return positions
}

let function calcBestSpawnTmForTeam(team, offset, wishTm) {
  let positions = getPlayerPositionsByTeam(team)
  foreach (p in positions)
    if (p.len() > 0) {
      let bestTm = TMatrix(wishTm)
      bestTm.setcol(3, p[dagorRandom.grnd() % p.len()] + offset)
      return bestTm
    }
  return wishTm
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

let gatherHelperParamsMap = {
  ["isTeamSpawn"]               = ["respbase__team_spawn", ecs.TYPE_BOOL, false],
  ["teamOffset"]                = ["respbase__team_offset", ecs.TYPE_POINT3, Point3(0.0, 0.0, 0.0)],
}

let gatherSpawnParamsQuery = ecs.SqQuery("gatherSpawnParamsQuery", {comps_ro = gatherSpawnParamsMap.values()})
let gatherHelperParamsQuery = ecs.SqQuery("gatherHelperParamsQuery", {comps_ro = gatherHelperParamsMap.values()})

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
let gatherHelperParams = @(eid) gatherParamsFromEntity(eid, gatherHelperParamsQuery, gatherHelperParamsMap)

let function mkSpawnParamsByTeamImpl(team, findBaseCb) {
  let teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  let searchForSafest = ecs.obsolete_dbg_get_comp_val(teamEid, "team__findSafestSpawn", false)

  let baseEid = findBaseCb(team, searchForSafest)
  if (baseEid == INVALID_ENTITY_ID)
    return null

  let params = {
    baseEid = baseEid
    team = team
  }

  params.__update(ecs.obsolete_dbg_get_comp_val(teamEid, "team__overrideUnitParam").getAll() ?? {})
  params.__update(gatherSpawnParams(baseEid))

  let helperParams = gatherHelperParams(baseEid)

  if (helperParams.isTeamSpawn)
    params.transform = calcBestSpawnTmForTeam(team, helperParams.teamOffset, params.transform)

  if (!params.isValidated) {
    if (params?.keys()?.contains("respawner__spawnBiasRad")) {
      let spawnBiasRad = params["respawner__spawnBiasRad"]
      let biasAngle = dagorRandom.rnd_float(0.0, 2.0 * PI)
      let biasPos = Point3(spawnBiasRad * cos(biasAngle), 0.0, spawnBiasRad * sin(biasAngle))
      params.transform.setcol(3, params.transform.getcol(3) + biasPos)
    }
    params.transform = validateTm(params.transform)
  }

  return params
}

let mkSpawnParamsByTeam = @(team)
  mkSpawnParamsByTeamImpl(team, find_human_respawn_base)

let function markRespawnBase(team, baseEid) {
  let teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  if (!ecs.obsolete_dbg_get_comp_val(teamEid, "team__markRespawnBase", false) || baseEid == INVALID_ENTITY_ID)
    return
  ecs.obsolete_dbg_set_comp_val(baseEid, "team", team)
  ecs.obsolete_dbg_set_comp_val(baseEid, "lastSpawnOnTime", get_sync_time())
}

let playerQuery = ecs.SqQuery("playerQuery", {comps_ro = [["scoring_player__battlesPlayed", ecs.TYPE_INT, -1], ["player__metaItems", ecs.TYPE_ARRAY]]})

let function spawnSoldier(team, playerEid, possessed = INVALID_ENTITY_ID, spawnParams = null) {
  let params = spawnParams ?? mkSpawnParamsByTeam(team)
  if (!params) {
    logerr($"spawnSoldier: no respawn base for team {team} with possessed {possessed}")
    return
  }

  let baseEid = params?.baseEid ?? INVALID_ENTITY_ID

  local templateName = getTeamUnitTemplateName(team, playerEid)
  let weaponTempl = getTeamWeaponPresetTemplateName(team)
  if (weaponTempl)
    templateName = $"{templateName}+{weaponTempl}"

  markRespawnBase(team, baseEid)

  local metaItems = []
  local battlesPlayed = 0
  playerQuery.perform(playerEid, function(_eid, comp) {
    metaItems = comp["player__metaItems"].getAll()
    battlesPlayed = comp["scoring_player__battlesPlayed"]
  })

  let at = params.transform.getcol(3)
  debug($"spawnSoldier: create single soldier squad for team {team} at ({at.x},{at.y},{at.z})")

  let initialParams = {
    ["squad_member__memberIdx"] = 0,
    ["entity_mods__defArmor"] = calcNewbieArmor(battlesPlayed),
    ["human_net_phys__isSimplifiedPhys"] = ecs.obsolete_dbg_get_comp_val(playerEid, "playerIsBot", null) != null
  }

  let finalParams = apply_customization(templateName, metaItems, initialParams.__merge(params), playerEid)
  ecs.g_entity_mgr.createEntity(templateName, finalParams, function (soldierEid) {
    ecs.g_entity_mgr.sendEvent(playerEid, CmdPossessEntity({possessedEid=soldierEid}))
    initItemContainer(soldierEid)
  })
}

return {
  spawnSoldier = kwarg(spawnSoldier)
  validatePosition
  validateTm
  mkSpawnParamsByTeam
  mkVehicleSpawnParamsByTeam = @(team) mkSpawnParamsByTeamImpl(team, find_vehicle_respawn_base)
  mkSpawnParamsByTeamEx = mkSpawnParamsByTeamImpl
  getTeamWeaponPresetTemplateName
  getTeamUnitTemplateName
  createInventory
  initItemContainer
  rebalance
  calcNewbieArmor
  gatherParamsFromEntity
}
