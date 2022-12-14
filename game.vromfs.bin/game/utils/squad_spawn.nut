import "%dngscripts/ecs.nut" as ecs

let {kwarg, KWARG_NON_STRICT} = require("%sqstd/functools.nut")
let debug = require("%enlSqGlob/library_logs.nut").with_prefix("[SPAWN]")
let logerr = require("dagor.debug").logerr
let {Point3, TMatrix} = require("dagor.math")
let weapon_slots = require("%enlSqGlob/weapon_slots.nut")
let math = require("math")
let {traceray_normalized} = require("dacoll.trace")
let {createInventory, validatePosition, validateTm} = require("%scripts/game/utils/spawn.nut")

const spawnZoneExtents = 3.0

let function calcBotCountInVehicleSquad(vehicle, squadLen) {
  let db = ecs.g_entity_mgr.getTemplateDB()
  let vehicleTempl = db.getTemplateByName(vehicle)
  if (vehicleTempl == null) {
    debug($"Vehicle '{vehicle}' not found in templates DB")
    return 0
  }
  let seats = vehicleTempl.getCompValNullable("vehicle_seats__seats")
  if (seats == null) {
    debug($"Vehicle '{vehicle}' has no seats")
    return 0
  }
  return min(seats.len(), squadLen) - 1
}

let vehicleTransformQuery = ecs.SqQuery("vehicleTransformQuery", { comps_ro = [["transform", ecs.TYPE_MATRIX]] comps_rq = ["vehicle"] })

let function validateVehiclePosition(tm) {
  local wishPos = tm.getcol(3)

  let vehiclesPos = []
  vehicleTransformQuery.perform(function(_eid, comp) { vehiclesPos.append(comp["transform"].getcol(3)) })

  local isWorking = true
  for (local iter = 0; iter < 5 && isWorking; ++iter) {
    isWorking = false
    foreach (pos in vehiclesPos) {
      local dist = wishPos - pos
      dist.y = 0.0
      local len = dist.length()
      if (len == 0.0) {
        len = 1.0
        dist = Point3(1.0, 0.0, 0.0)
      }
      if (len < 5.0) {
        dist = dist * (1.0 / len)
        wishPos = wishPos + dist * 5.0
        isWorking = true
      }
    }
  }
  let resTm = TMatrix(tm)
  resTm.setcol(3, wishPos)
  return validatePosition(resTm, tm.getcol(3), spawnZoneExtents)
}

let excludeCompsFilter = {inventory=1, equipment=1, bodyScale=1}
let excludeVehicleCompsFilter = {disableDMParts=1}

let function wrapComps(inComps, exclude=null) {
  let comps = {}
  foreach (key, value in inComps) {
    if (exclude?[key] != null)
      continue
    if (typeof value == "array")
      comps[key] <- [value, ecs.TYPE_ARRAY]
    else if (typeof value == "table")
      comps[key] <- [value, ecs.TYPE_OBJECT]
    else
      comps[key] <- value
  }
  return comps
}

let function mkBaseComps(soldier) {
  let comps = {}

  foreach (key, value in soldier)
    if (excludeCompsFilter?[key] == null)
      comps[key] <- value

  let initialEquip = {}
  let initialEquipComponents = {}

  let equipment = soldier?.equipment
  if (equipment != null)
    foreach (slot, equip in equipment) {
      initialEquip[equip.gametemplate] <- slot
      initialEquipComponents[equip.gametemplate] <- { }
    }

  comps["human_equipment__initialEquip"] <- initialEquip
  comps["human_equipment__initialEquipComponents"] <- initialEquipComponents

  let bodyHeight = soldier?.bodyScale?.height ?? 1.0
  let bodyWidth = soldier?.bodyScale?.width ?? 1.0

  comps["animchar__scale"]          <- bodyHeight
  comps["animchar__depScale"]       <- Point3(bodyWidth, bodyHeight, bodyWidth)
  comps["animchar__transformScale"] <- Point3(bodyWidth, 1.0, bodyWidth)

  comps["soldier__id"] <- soldier.id
  comps["soldier__sClass"] <- soldier?.sClass ?? ""
  comps["soldier__sKind"] <- soldier?.sKind ?? ""
  comps["soldier__sClassRare"] <- soldier?.sClassRare ?? 0

  return comps
}

let function mkHPComps(soldier) {
  let comps = {}

  let db = ecs.g_entity_mgr.getTemplateDB()
  let templ = db.getTemplateByName(soldier.gametemplate)
  if (templ == null)
    logerr($"not found template {soldier.gametemplate}")
  else {
    let maxHpTemplValue = templ.getCompValNullable("hitpoints__maxHp")
    let hpThresholdTemplValue = templ.getCompValNullable("hitpoints__hpThreshold")
    if (maxHpTemplValue != null && hpThresholdTemplValue != null) {
      let baseMaxHpMult = soldier?.baseMaxHpMult ?? 1.0
      let templateModMaxHpMult = templ.getCompValNullable("entity_mods__maxHpMult")
      let modMaxHpMult = soldier?["entity_mods__maxHpMult"] ?? templateModMaxHpMult ?? 1.0
      let maxHp = maxHpTemplValue * baseMaxHpMult * modMaxHpMult
      let hpRegenMult = templ.getCompValNullable("entity_mods__hpToRegen")
      let hpThreshold = hpThresholdTemplValue * (soldier?["entity_mods__hpToRegen"] ?? hpRegenMult ?? 1.0)

      comps["hitpoints__hp"] <- maxHp
      comps["hitpoints__maxHp"] <- maxHp
      comps["hitpoints__hpThreshold"] <- hpThreshold
    }
    else
      logerr($"hitpoints__maxHp or hitpoints__hpThreshold not contained in template {soldier.gametemplate}")
  }

  return comps
}

let function mkAmmoMapComps(soldier) {
  let weapInfo = soldier?["human_weap__weapInfo"]
  if (weapInfo == null)
    return {}

  let ammoMap = {}
  foreach (slotId, weap in weapInfo) {
    local ammoTemplateNames = [weap.reserveAmmoTemplate].extend(weap?.additionalReserveAmmoTemplates ?? [])

    foreach (ammoTemplateName in ammoTemplateNames) {
      let ammoTemplate = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(ammoTemplateName);
      let allowRequestAmmo = ammoTemplate?.getCompValNullable("allowRequestAmmo") ?? false

      if (slotId != weapon_slots.EWS_GRENADE &&
        slotId != weapon_slots.EWS_MELEE &&
        ammoTemplateName &&
        ammoTemplateName != "" &&
        allowRequestAmmo) {
          ammoMap[ammoTemplateName] <- { template = ammoTemplateName }
      }
    }
  }

  return {ammoProtoToTemplateMap = ammoMap}
}

let mkItemContainer = @(soldier) {itemContainer = createInventory(soldier?.inventory ?? [])[0]}

let spawnSoldier = kwarg(function(soldier, comps, squadParams, shouldBePossessed = false, soldierIndexInSquad = 0, useVehicleEid = ecs.INVALID_ENTITY_ID) {
  local templateName = soldier?.gametemplate ?? "usa_base_soldier"
  let addTemplatesOnSpawn = squadParams?.addTemplatesOnSpawn

  comps = comps.
    __merge(mkBaseComps(soldier)).
    __update(mkAmmoMapComps(soldier)).
    __update(mkHPComps(soldier)).
    __update(mkItemContainer(soldier))

  if (addTemplatesOnSpawn != null)
    templateName = $"{templateName}+{addTemplatesOnSpawn}"

  // Use special spawner because we want to create all equipment before soldier createion
  // The helps to reduce inital replication trafic
  ecs.g_entity_mgr.createEntity("soldier_spawner_with_equimpent", {
    soldierTemplate     = [templateName, ecs.TYPE_STRING]
    soldierComponents   = [comps, ecs.TYPE_OBJECT]
    shouldBePossessed   = shouldBePossessed
    playerEid           = ecs.EntityId(squadParams.playerEid)
    squadEid            = ecs.EntityId(squadParams.squadEid)
    useVechicle         = ecs.EntityId(useVehicleEid)
    soldierIndexInSquad = soldierIndexInSquad
  })
})

let function spawnSolidersInSquad(squad, spawnParams, squadParams, vehicleEid = ecs.INVALID_ENTITY_ID) {
  let leaderId             = squadParams.leaderId
  let squadEid             = squadParams.squadEid
  let playerEid            = squadParams.playerEid
  let isBot                = squadParams.isBot

  let transform       = spawnParams.transform
  let noSpawnImmunity = spawnParams.noSpawnImmunity
  let spawnImmunityTime = spawnParams?.spawnImmunityTime

  let spawnTmIsValidated = spawnParams?.isValidated ?? false
  let tm = spawnTmIsValidated ? transform : validateTm(transform, spawnZoneExtents)
  let botCount = squad.len() - 1

  let commonParams = {
    ["squad_member__squad"] = ecs.EntityId(squadEid),
    ["squad_member__playerEid"] = ecs.EntityId(playerEid),
    ["lastRespawnBaseEid"] = ecs.EntityId(spawnParams.baseEid)
  }

  if (noSpawnImmunity)
    commonParams["spawn_immunity__timer"] <- 0.0
  else if (spawnImmunityTime != null)
    commonParams["spawn_immunity__timer"] <- spawnImmunityTime

  let leaderNo = squad.findindex(@(s) s?.id == leaderId) ?? leaderId

  let leaderParams =
    commonParams.
    __merge(spawnParams).
    __merge({
      ["transform"] = tm,
      ["squad_member__memberIdx"] = leaderNo,
      ["human_net_phys__isSimplifiedPhys"] = isBot,
    })

  spawnSoldier({
    soldier             = squad[leaderNo]
    comps               = leaderParams
    squadParams         = squadParams
    useVehicleEid       = vehicleEid
    shouldBePossessed   = true
    soldierIndexInSquad = 0
  })

  let numRows = math.ceil(math.sqrt(botCount + 1)).tointeger()
  let spawnDist = 1.0
  for (local i = 0; i < botCount; ++i) {
    let memberIdx = i < leaderNo ? i : (i + 1)

    let aiTm = TMatrix(tm)
    let row = ((i + 1) / numRows) * spawnDist
    let col = math.ceil(((i + 1) % numRows) * 0.5) * spawnDist * ((i % 2) * 2 - 1) // alternating -1 +1
    aiTm.setcol(3, aiTm * Point3(-row, 0.0, col));

    let botParams =
      commonParams.
      __merge(spawnParams).
      __merge({
        ["transform"] = spawnTmIsValidated ? tm : validatePosition(aiTm, tm.getcol(3), spawnZoneExtents),
        ["squad_member__memberIdx"] = memberIdx,
        ["beh_tree__enabled"] = true,
        ["human_weap__infiniteAmmoHolders"] = true,
        ["human_net_phys__isSimplifiedPhys"] = true,
      })

    spawnSoldier({
      soldier             = squad[memberIdx]
      comps               = botParams
      squadParams         = squadParams
      useVehicleEid       = vehicleEid
      soldierIndexInSquad = i + 1 /* 0 - is the leader */
    })
  }
}

local function spawnSquadEntity(squad, squadParams, mkSpawnParamsCb, cb) {
  let squadId   = squadParams.squadId
  let memberId  = squadParams.memberId
  let team      = squadParams.team
  let playerEid = squadParams.playerEid

  let spawnParams = mkSpawnParamsCb(team)

  if (!spawnParams) {
    debug($"No respawn base for player {playerEid}")
    return false
  }

  squadParams = squadParams.
    __merge({
      isBot             = ecs.obsolete_dbg_get_comp_val(playerEid, "playerIsBot", null) != null,
      leaderId          = memberId,
      playerEid         = playerEid,
    })

  ecs.g_entity_mgr.createEntity("squad", {
    ["squad__id"]             = [squadId, ecs.TYPE_INT],
    ["squad__ownerPlayer"]    = [playerEid, ecs.TYPE_EID],
    ["squad__respawnBaseEid"] = [spawnParams.baseEid, ecs.TYPE_EID],
    ["squad__squadProfileId"] = [squadParams.squadProfileId, ecs.TYPE_STRING]
  },
  @(squadEid) cb(squad, spawnParams, squadParams.__merge({ squadEid = squadEid })))

  return true
}

let function spawnSquad(squad, team, playerEid, mkSpawnParamsCb, squadId = 0, memberId = 0, squadProfileId = "", addTemplatesOnSpawn = null) {
  let squadParams = {team, playerEid, squadId, memberId, squadProfileId, addTemplatesOnSpawn}
  return spawnSquadEntity(squad, squadParams, mkSpawnParamsCb, spawnSolidersInSquad)
}

let function mkVehicleComps(vehicle) {
  let comps = {}
  if (vehicle?.disableDMParts != null) {
    let disabledParts = ecs.CompStringList()
    vehicle.disableDMParts.each(@(v) disabledParts.append(v))
    comps["disableDMParts"] <- [disabledParts, ecs.TYPE_STRING_LIST]
  }
  return comps
}

let function spawnVehicle(squad, spawnParams, squadParams) {
  let team      = squadParams.team
  let vehicle   = squadParams.vehicle
  let vehicleCompsRaw = squadParams.vehicleComps

  local transform         = spawnParams.transform
  let shouldValidateTm    = spawnParams.shouldValidateTm
  let startVelDir         = spawnParams?.startVelDir
  let startRelativeSpeed  = spawnParams?.startRelativeSpeed
  let addTemplatesOnSpawn = spawnParams?.addTemplatesOnSpawn
  let squadEid            = squadParams.squadEid
  let playerEid           = squadParams.playerEid

  if (shouldValidateTm)
    transform = validateVehiclePosition(transform)
  else {
    let db = ecs.g_entity_mgr.getTemplateDB()
    let vehicleTempl = db.getTemplateByName(vehicle)
    let maxSpawnHeight = vehicleTempl?.getCompValNullable("vehicle_spawn__maxHeight") ?? -1.0
    if (maxSpawnHeight >= 0.0) {
      let spawnPos = transform[3]
      let downDir = Point3(0.0, -1.0, 0.0)
      let startHeight = spawnPos.y
      let traceResT = traceray_normalized(spawnPos, downDir, startHeight) ?? startHeight
      if (traceResT > maxSpawnHeight)
        transform[3] = Point3(spawnPos.x, startHeight - traceResT + maxSpawnHeight, spawnPos.z)
    }
  }

  let vehicleComps = wrapComps(vehicleCompsRaw, excludeVehicleCompsFilter).
    __update(mkVehicleComps(vehicleCompsRaw)).
    __update({
      team                                       = team,
      ownedBySquad                               = ecs.EntityId(squadEid),
      ownedByPlayer                              = ecs.EntityId(playerEid),
      ["vehicle_seats__restrictToTeam"]           = team,
      ["vehicle_seats__autoDetectRestrictToTeam"] = false,
      transform                                   = transform,
    })

  if (startVelDir != null && startRelativeSpeed != null)
    vehicleComps.__update({
      ["startVelDir"]        = [startVelDir, ecs.TYPE_POINT3],
      ["startRelativeSpeed"] = [startRelativeSpeed, ecs.TYPE_FLOAT],
    })

  local vehicleTemplate = vehicle
  if (addTemplatesOnSpawn != null) {
    delete spawnParams.addTemplatesOnSpawn
    vehicleTemplate = "{0}+{1}".subst(vehicle, "+".join(addTemplatesOnSpawn))
  }
  ecs.g_entity_mgr.createEntity(vehicleTemplate, vehicleComps, @(vehicleEid) spawnSolidersInSquad(squad, spawnParams, squadParams, vehicleEid))
}

let function spawnVehicleSquad(squad, team, playerEid, isBot, vehicle, mkSpawnParamsCb, vehicleComps = {}, squadId = 0, memberId = 0,
                               squadProfileId = "", possessed = ecs.INVALID_ENTITY_ID) {
  let squadParams = {team, playerEid, isBot, vehicle, vehicleComps, squadId, memberId, possessed, squadProfileId}
  return spawnSquadEntity(squad, squadParams, mkSpawnParamsCb, spawnVehicle)
}

let spawnSquadKW = kwarg(spawnSquad)

return {
  spawnSquad = @(params) spawnSquadKW(params, KWARG_NON_STRICT)
  spawnVehicleSquad = kwarg(spawnVehicleSquad)

  calcBotCountInVehicleSquad = calcBotCountInVehicleSquad

  mkComps = @(soldier) wrapComps(mkBaseComps(soldier), excludeCompsFilter).__update(mkItemContainer(soldier))
}
