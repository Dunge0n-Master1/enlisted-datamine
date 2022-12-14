import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let DataBlock = require("DataBlock")
let { Point2, Point3} = require("dagor.math")
let { round_by_value } = require("%sqstd/math.nut")

let cachedBlocks = {}
let zeroPoint2 = Point2(0.0, 0.0)
let zeroPoint3 = Point3(0.0, 0.0, 0.0)

let TYPE_INT = 1
let TYPE_FLOAT = 2
let TYPE_POINT2 = 3
let TYPE_ARRAY = 4
let TYPE_STRING = 5
let TYPE_POINT3 = 6

let ITEM_DATA_FIELDS = {
  ["item__weight"] = TYPE_FLOAT,
  ["item__healAmount"] = TYPE_FLOAT,
  ["item__reviveAmount"] = TYPE_FLOAT,
}

let ITEM_GUN_DATA_FIELDS = {
  ["flamethrower__maxFlameLength"] = TYPE_FLOAT,
  ["flamethrower__streamDamagePerSecond"] = TYPE_FLOAT,
  ["gun__shotFreq"] = TYPE_FLOAT,
  ["gun__shotFreqRndK"] = TYPE_FLOAT,
  ["gun__kineticDamageMult"] = TYPE_FLOAT,
  ["gun__recoilAmount"] = TYPE_FLOAT,
  ["gun__recoilDirAmount"] = TYPE_FLOAT,
  ["gun_spread__maxDeltaAngle"] = TYPE_FLOAT,
  ["gun__shells"] = TYPE_ARRAY,
  ["gun__ammoHolders"] = TYPE_ARRAY,
  ["gun__reloadTime"] = TYPE_FLOAT,
  ["gun__firingModeNames"] = TYPE_ARRAY,
  ["magazine_type"] = TYPE_STRING,
  ["single_reload__prepareTime"] = TYPE_FLOAT,
  ["single_reload__loopTime"] = TYPE_FLOAT,
  ["single_reload__postTime"] = TYPE_FLOAT,
}

let VEHICLE_DATA_FIELDS = {
  ["vehicle_seats__seats"] = TYPE_ARRAY,
  ["damage_model__blk"] = TYPE_STRING,
  ["turret_control__turretInfo"] = TYPE_ARRAY,
}

let SHELLS_DATA_FIELDS = {
  bullets = TYPE_INT
  caliber = TYPE_FLOAT
  speed = TYPE_FLOAT
  maxDistance = TYPE_FLOAT
  hitPowerMult = TYPE_FLOAT
  cartridgeMass = TYPE_FLOAT
  reloadTime = TYPE_FLOAT
  explodeHitPower = TYPE_FLOAT
  explodeArmorPower = TYPE_FLOAT
  spawn = { minCount = TYPE_INT, maxCount = TYPE_INT }
  armorpower = {
    ArmorPower0m = TYPE_POINT2,    ArmorPower100m = TYPE_POINT2,
    ArmorPower500m = TYPE_POINT2,  ArmorPower1000m = TYPE_POINT2,
    ArmorPower1500m = TYPE_POINT2, ArmorPower7000m = TYPE_POINT2
  }
  hitpower = {
    HitPower10m = TYPE_POINT2,  HitPower40m = TYPE_POINT2,  HitPower100m = TYPE_POINT2,
    HitPower150m = TYPE_POINT2, HitPower200m = TYPE_POINT2, HitPower300m = TYPE_POINT2,
    HitPower350m = TYPE_POINT2, HitPower400m = TYPE_POINT2, HitPower450m = TYPE_POINT2,
    HitPower600m = TYPE_POINT2, HitPower650m = TYPE_POINT2, HitPower1000m = TYPE_POINT2,
    HitPower1500m = TYPE_POINT2
  }
  cumulativeDamage = {
    armorPower = TYPE_FLOAT
  }
  splashDamage = {
    radius = TYPE_POINT2
    penetration = TYPE_POINT2
    damage = TYPE_FLOAT
    dmgOffset = TYPE_POINT3
  }

}

let MODEL_DATA_FIELDS = {
  VehiclePhys = {
    Mass = { Empty = TYPE_FLOAT, Fuel = TYPE_FLOAT, TakeOff = TYPE_FLOAT }
    engine = { horsePowers = TYPE_FLOAT, minRPM = TYPE_FLOAT, maxRPM = TYPE_FLOAT }
  }
  DamageParts = {
    body_front = { armorThickness = TYPE_FLOAT }
    body_side = { armorThickness = TYPE_FLOAT }
    body_back = { armorThickness = TYPE_FLOAT }
    body_bottom = { armorThickness = TYPE_FLOAT }
    superstructure_front = { armorThickness = TYPE_FLOAT }
    superstructure_side = { armorThickness = TYPE_FLOAT }
    superstructure_back = { armorThickness = TYPE_FLOAT }
    superstructure_bottom = { armorThickness = TYPE_FLOAT }
    turret_front = { armorThickness = TYPE_FLOAT }
    turret_side = { armorThickness = TYPE_FLOAT }
    turret_top = { armorThickness = TYPE_FLOAT }
    turret_back = { armorThickness = TYPE_FLOAT }
    turret_01_front = { armorThickness = TYPE_FLOAT }
    turret_01_side = { armorThickness = TYPE_FLOAT }
    turret_01_top = { armorThickness = TYPE_FLOAT }
    turret_01_back = { armorThickness = TYPE_FLOAT }
  }
}

let GUN_DATA_FIELDS = {
  ["gun__blk"] = TYPE_STRING,
  ["gun__locName"] = TYPE_STRING, // =item.name
  ["gun__reloadTime"] = TYPE_FLOAT,
  ["gun__shotFreq"] = TYPE_FLOAT,
  ["gun__shotFreqRndK"] = TYPE_FLOAT,
  ["gun__maxAmmo"] = TYPE_FLOAT,
  ["gun__shellsAmmo"] = TYPE_ARRAY,
  ["turret__yawSpeed"] = TYPE_FLOAT,
  ["turret__pitchSpeed"] = TYPE_FLOAT,
}

let function readTemplate(template, scheme) {
  if (template == null || typeof scheme != "table")
    return null

  let res = {}
  foreach (key, val in scheme) {
    local value
    switch (val) {
      case TYPE_INT:
        value = template.getCompValNullable(key)
        if (value != null)
          value = value.tointeger()
        break
      case TYPE_FLOAT:
        value = template.getCompValNullable(key)
        if (value != null)
          value = value.tofloat()
        break
      case TYPE_POINT2:
        let point = template.getCompValNullable(key)
        if (point != null && (point?.x ?? 0) != 0 && (point?.y ?? 0) != 0)
          value = Point2(point.x, point.y)
        break
      case TYPE_ARRAY:
        value = template.getCompValNullable(key)?.getAll()
        break
      case TYPE_STRING:
        value = template.getCompValNullable(key)
        if (type(value) != "string")
          value = null
        break
    }
    if (value != null)
      res[key] <- value
  }
  return res
}

let function readBlock(blockData, scheme) {
  if (blockData == null || typeof scheme != "table")
    return null

  let res = {}
  foreach (key, val in scheme) {
    local value
    switch (val) {
      case TYPE_INT:
        value = blockData.getInt(key, 0) || null
        break
      case TYPE_FLOAT:
        value = blockData.getReal(key, 0.0) || null
        break
      case TYPE_POINT2:
        value = blockData.getPoint2(key, zeroPoint2)
        if (value.x == 0.0 && value.y == 0.0)
          value = null
        break
      case TYPE_POINT3:
        value = blockData.getPoint3(key, zeroPoint3)
        if (value.x == 0.0 && value.y == 0.0 && value.z == 0.0)
          value = null
        break
      default:
        foreach (blk in (blockData % key) ?? []) {
          let data = readBlock(blk, val)
          if (data != null)
            value = (value ?? {}).__merge(data)
        }
    }
    if (value != null)
      res[key] <- value
  }
  return res
}

let function extractBlockData(blockPath, scheme) {
  if (blockPath == null)
    return null

  local value = cachedBlocks?[blockPath]
  if (value != null)
    return value

  let blockData = DataBlock()
  blockData.load(blockPath)
  value = readBlock(blockData, scheme)
  cachedBlocks[blockPath] <- value
  return value
}

let function flattenTable(source, prefix = null) {
  let flatten = {}
  foreach (key, val in source) {
    let id = prefix != null ? $"{prefix}__{key}" : key
    if (typeof val == "table")
      flatten.__update(flattenTable(val, id))
    else
      flatten[id] <- val
  }
  return flatten
}

let function processShotFreq(itemData) {
  local rateOfFire = itemData?["gun__shotFreq"]
  if (rateOfFire == null)
    return

  rateOfFire *= 60.0
  let roundValue = rateOfFire < 100 ? 1 : 10 // beautify big values
  rateOfFire = round_by_value(rateOfFire, roundValue).tointeger()

  let rndK = itemData?["gun__shotFreqRndK"] ?? 0
  let rateOfFireMin = round_by_value(rateOfFire / (1.0 + rndK), roundValue).tointeger()
  if (rateOfFireMin != rateOfFire)
    itemData.rateOfFire <- [rateOfFireMin, rateOfFire]
  else
    itemData.rateOfFire <- rateOfFire
}

let function processHitPower(itemData) {
  if (itemData == null)
    return
  let hitPowerMult = itemData?.hitPowerMult ?? 0.0
  if (hitPowerMult > 0) {
    itemData.hitPowerMult <- hitPowerMult
    itemData.hitPowerTotal <- hitPowerMult
      * (itemData?.gun__kineticDamageMult ?? 1.0)
      * (itemData?.spawn.maxCount ?? 1.0)
  }
}

let function processArmorPower(itemData) {
  let cumulativeArmorPower = itemData?.cumulativeDamage.armorPower ?? 0
  if (cumulativeArmorPower > 0)
    itemData.cumulativeArmorPower <- cumulativeArmorPower
  else if ("armorpower" in itemData) {
    itemData.kineticArmorPower <- itemData.armorpower
    itemData.kineticArmorPowerMax <- itemData.armorpower
      .reduce(@(res, val) max(res, val.x), 0)
  }
}

let function processRecoil(itemData) {
  if (itemData == null)
    return
  let recoilAmount = itemData?["gun__recoilAmount"] ?? 0.0
  let recoilDirAmount = itemData?["gun__recoilDirAmount"] ?? 0.0
  itemData.recoilAmountVert <- 1000 * recoilAmount * recoilDirAmount
  itemData.recoilAmountHor <- 1000 * recoilAmount * (1.0 - recoilDirAmount)
}

let function processWeaponData(weaponData) {
  processShotFreq(weaponData)
  processHitPower(weaponData)
  processArmorPower(weaponData)
  processRecoil(weaponData)
}

let function getWeaponData(templateId) {
  let tmplDB = ecs.g_entity_mgr.getTemplateDB()
  local template = tmplDB.getTemplateByName(templateId)
  let weaponId = template?.getCompValNullable("item__weapTemplate")
  if (weaponId != null && weaponId != templateId)
    template = tmplDB.getTemplateByName(weaponId)

  let itemData = readTemplate(template, ITEM_DATA_FIELDS)
  if (itemData == null)
    return null

  let isNotShootableGun = template.getCompValNullable("notShootableGun")
  if (isNotShootableGun == null) {
    let itemGunData = readTemplate(template, ITEM_GUN_DATA_FIELDS)
    if (itemGunData != null) {
      itemData.__update(itemGunData)

      let shellsData = extractBlockData(itemData?["gun__shells"][0], SHELLS_DATA_FIELDS)
      if (shellsData != null)
        itemData.__update(shellsData)

      let ammoHolders = itemData?["gun__ammoHolders"][0]
      if (ammoHolders != null) {
        let holdersTemplate = tmplDB.getTemplateByName(ammoHolders)
        let ammoCount = holdersTemplate?.getCompValNullable("ammo_holder__ammoCount")
        if (ammoCount != null)
          itemData["bullets"] <- ammoCount
      }

      processWeaponData(itemData)
    }
  }

  return itemData
}

let function getVehicleData(templateId) {
  let tmplDB = ecs.g_entity_mgr.getTemplateDB()
  let template = tmplDB.getTemplateByName(templateId)
  let vehicleData = readTemplate(template, VEHICLE_DATA_FIELDS)
  if (vehicleData == null)
    return null

  let modelData = extractBlockData(vehicleData?["damage_model__blk"], MODEL_DATA_FIELDS)
  if (modelData != null)
    vehicleData.__update(modelData)

  if ("turret_control__turretInfo" in vehicleData) {
    let turretInfo = delete vehicleData["turret_control__turretInfo"]
    local mainCaliber = null
    foreach (turretData in turretInfo) {
      let { gun = null } = turretData
      if (gun == null)
        continue
      let [tmplName = null, tmplSuffix = null] = gun.split("+")
      let gunTemplate = tmplDB.getTemplateByName(tmplName)
      let gunData = readTemplate(gunTemplate, GUN_DATA_FIELDS)
      gunData["gun__template"] <- gun
      gunData["gun__shellsAmmo"] <- (gunData?["gun__shellsAmmo"] ?? []).reduce(@(sum, val) sum + val, 0)
      gunData["gun__maxAmmo"] <- max(gunData["gun__maxAmmo"], gunData["gun__shellsAmmo"])
      if (gunData == null)
        continue
      vehicleData.armament <- (vehicleData?.armament ?? []).append(gunData)
      if (tmplSuffix == "main_turret")
        mainCaliber = gunData
    }
    if (mainCaliber != null) {
      let reloadTime = 1.0 / (mainCaliber?["gun__shotFreq"] ?? 1.0)
      // for automatic weapons, show the magazine reload time instead of the firing interval
      vehicleData["gun__reloadTime"] <- reloadTime < 1.0 ? mainCaliber?["gun__reloadTime"] ?? 0 : reloadTime
      foreach (key in ["turret__yawSpeed", "turret__pitchSpeed"])
        vehicleData[key] <- mainCaliber?[key] ?? 0.0
    }
  }

  if ("vehicle_seats__seats" in vehicleData)
    vehicleData.crew <- (delete vehicleData["vehicle_seats__seats"]).len()

  if ("VehiclePhys" in vehicleData)
    vehicleData.__update(flattenTable(delete vehicleData.VehiclePhys))

  if ("DamageParts" in vehicleData) {
    let armorParts = delete vehicleData.DamageParts
    let armorOrders = {} // to get damage parts of minimal order
    foreach (armorKey, armorData in armorParts) {
      let val = armorData?.armorThickness ?? 0.0
      if (val <= 0)
        continue
      local counter = 0
      local [part, dir, dirAlt = null] = armorKey.split("_")
      if (dirAlt != null) {
        // multi turret vehicles
        counter = dir.tointeger()
        dir = dirAlt
      }
      let orderKey = $"{part}{dir}"
      let curOrder = armorOrders?[orderKey]
      if (curOrder == null || counter < curOrder) {
        armorOrders[orderKey] <- counter
        if (part == "superstructure")
          part = "body"
        let armorId = $"armor__{part}"
        if (armorId not in vehicleData)
          vehicleData[armorId] <- {}
        vehicleData[armorId][dir] <- max(val, vehicleData?[armorId][dir] ?? 0)
      }
    }
    let addFront = vehicleData?["armor__body"]
    if (addFront)
      addFront.front <- addFront?.front ?? addFront?.side
  }

  return vehicleData
}

let mkMulByPercent = @(field) function(weaponData, value) {
  if (field in weaponData)
    weaponData[field] *= 1.0 + 0.01 * value
}

let upgradesUpdate = {
  // weapons
  ["gun__kineticDamageMult"] = "hitPowerMult",
  ["gun__shotFreq"] = null,
  ["gun__recoilAmount"] = null,
  ["gun__recoilDirAmount"] = null,
  ["gun__reloadTime"] = null,
  // vehicles
  ["braking_force"] = null,
  ["engine_power"] = "engine__horsePowers",
  ["track_friction_side_linear"] = null,
  ["track_friction_frontal_static"] = null,
  ["track_friction_frontal_sliding"] = null,
  ["track_friction_side_rot_min_speed"] = null,
  ["track_friction_side_rot_max_speed"] = null,
  ["track_friction_side_rot_min_friction"] = null,
  ["track_friction_side_rot_max_friction"] = null,
  ["suspension_dampening"] = null,
  ["suspension_resting"] = null,
  ["suspension_min_limit"] = null,
  ["suspension_max_limit"] = null,
  ["turret_hor_speed"] = "turret__yawSpeed",
  ["turret_ver_speed"] = "turret__pitchSpeed",
}.map(@(val, key) mkMulByPercent(val ?? key))

let function applyUpgrades(weaponData, upgrades) {
  let res = clone weaponData
  foreach (key, value in upgrades ?? {})
    upgradesUpdate?[key](res, value)
  processWeaponData(res)
  return res
}

return {
  getWeaponData
  getVehicleData
  applyUpgrades
}