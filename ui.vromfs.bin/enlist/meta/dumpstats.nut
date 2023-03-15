import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

// using system module currenlty only available on PC to create folders.
// TODO: replace witk mkdir when added to quirrel
let { system = null } = require_optional("system")
let { DBGLEVEL } = require("dagor.system")
if (system == null || DBGLEVEL <= 0)
  return

let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { getWeaponData, getVehicleData
} = require("%enlist/soldiers/model/collectWeaponData.nut")
let { vehicleSpecsDB, requireVehicleSpec } = require("%enlist/vehicles/physSpecs.nut")
let { getItemDetails, PLANE_DETAILS, TANK_DETAILS, ARMOR_ORDER, getArmaments
} = require("%enlSqGlob/ui/itemsInfo.nut")
let { round_by_value } = require("%sqstd/math.nut")
let { floatToStringRounded } = require("%sqstd/string.nut")
let { logerr } = require("dagor.debug")
let io = require("io")


let armorCtor = @(data, detail) "; ".join(ARMOR_ORDER
  .filter(@(key) key in data)
  .map(@(armorType) $"{armorType}: {data[armorType]} {detail?.measure}"))

local function defaultCtor(data, detail) {
  local { key, mult = 1, measure = "", altLimit = 0.0,
    altMeasure = "", precision = 1 } = detail
  let dataType = typeof data
  if (dataType == "table" || dataType == "array") {
    logerr($"Trying to export {dataType} in {key}. Custom text constructor is needed")
    return ""
  }

  if (altLimit != 0.0 && data >= altLimit)
    measure = altMeasure
  else
    data *= mult

  let printData = floatToStringRounded(data, precision)
  data = round_by_value(data, precision).tointeger()

  return measure != ""
    ? "{0}{1}".subst(printData, loc($"itemDetails/{measure}", { val=data }))
    : printData
}

let VEHICLE_TEXT_CONSTRUCTORS = {
  "armor__body" : armorCtor
  "armor__turret" : armorCtor
  "armament" : function(data, _) {
    local guns = getArmaments(data)
    if (!guns)
      return "none"
    guns = guns
      .map(@(gun) "{0}{1} - {2}{3}"
        .subst(
          loc("guns/{0}".subst(gun?["gun__locName"])),
          gun.count > 1 ? $" x{gun.count}" : "",
          gun["gun__maxAmmo"],
          loc("itemDetails/count")))
    return "; ".join(guns)
  }
}

let function getVehicleStats(vehicle, header) {
  let db = ecs.g_entity_mgr.getTemplateDB()
  let template = db.getTemplateByName(vehicle)
  let localizedName = loc(template?.getCompValNullable("item__name"))

  let vehicleSpecs = vehicleSpecsDB.value?[vehicle] ?? {}
  let vehicleData = getVehicleData(vehicle).__update(vehicleSpecs)
  let stats = ", ".join(header.map(function(detail) {
    let data = vehicleData?[detail.key]
    if (data == null)
      return ""
    if (detail.key in VEHICLE_TEXT_CONSTRUCTORS)
      return VEHICLE_TEXT_CONSTRUCTORS[detail.key](data, detail)
    return defaultCtor(data, detail)
  }))
  return $"{localizedName}, {stats}\n"
}


let arrayCtor = @(data, detail) " - ".join(typeof data == "array"
  ? data.map(@(d) defaultCtor(d, detail))
  : [defaultCtor(data, detail)])

let function tableCtor(data, detail) {
  let { mult = 1, measure = "", altMeasure = "", precision = 1 } = detail
  if (mult == 0)
    return null
  return "; ".join(data.values()
  .filter(@(p) (p?.x ?? 0) != 0 || (p?.y ?? 0) != 0)
  .sort(@(a, b) (a?.y ?? 0) <=> (b?.y ?? 0))
  .map(function(col) {
    let ref = col?.y ?? 0
    local val = (col?.x ?? 0) * mult
    let printVal = floatToStringRounded(val, precision)
    val = round_by_value(val, precision).tointeger()

    let text = measure != ""
      ? "{0}{1}".subst(ref, loc($"itemDetails/{measure}", { val = ref }))
      : ref

    let altText = altMeasure != ""
      ? "{0}{1}".subst(printVal, loc($"itemDetails/{altMeasure}", { val = val }))
      : printVal

    return $"{altText} at {text}"
  }))
}

let ITEMS_TEXT_CONSTRUCTORS = {
  "gun__firingModeNames" : @(data, _) data.len() == 0 ? null
    : "; ".join(data.map(@(name) loc($"firing_mode/{name}")))
  "splashDamage" :  function(val, _) {
    let dist = loc("itemDetails/splashDamage", { from = val.radius.x, to = val.radius.y })
    let dmg = loc("itemDetails/splashDamage/damage", { to = val.damage })
    return $"{dist } {dmg}"
  }
  "rateOfFire" : arrayCtor
  "kineticArmorPower" : tableCtor
  "hitpower" : tableCtor
}

let function getItemStats(item, header) {
  let db = ecs.g_entity_mgr.getTemplateDB()
  let template = db.getTemplateByName(item)
  let localizedName = loc(template?.getCompValNullable("item__name"))

  let weaponData = getWeaponData(item)
  let stats = ", ".join(header.map(function(detail) {
    let data = weaponData?[detail.key]
    if (data == null)
      return ""
    if (detail.key in ITEMS_TEXT_CONSTRUCTORS)
      return ITEMS_TEXT_CONSTRUCTORS[detail.key](data, detail)
    return defaultCtor(data, detail)
  }))
  return $"{localizedName}, {stats}\n"
}


// have to use \\ in path here for system(mkdir) to work. Otherwise folders were not getting created
let getSaveFolderPath = @(army) $".meta_stats\\{army}"

let function saveStatsToFile(army, file_name, header, items, text_generator) {
  let path = $"{getSaveFolderPath(army)}\\{file_name}"
  let file = io.file(path, "wt")

  let headerString = ", ".join(header.map(@(v) loc(v?.locId ?? $"itemDetails/{v.key}")))
  file.writestring($"Name:, {headerString}\n")

  items.keys().sort().each(@(v) file.writestring(text_generator(v, header)))

  file.close()

  console_print($"Saved to {path}")
}

let function createFolders(army) {
  //TODO: replace system with quirrel's or dagor's folder function when they are added/bound
  system($"mkdir {getSaveFolderPath(army)}")
}

let aircraftSubitemType = {
  fighter_aircraft = true
  assault_aircraft = true
}

// filter out cloth and other unnecessary items
let itemTypeWhitelist = {
  medkits = true
  repair_kit = true
  building_tool = true
  grenade = true
  mine = true
  scope = true
  bayonet = true
  radio = true
  melee = true
  shovel_weapon = true
  molotov = true
  lunge_mine = true
  antitank_mine = true
  antipersonnel_mine = true
  explosion_pack = true
  smoke_grenade = true
  impact_grenade = true
  flask_usable = true
  binoculars_usable = true
}

let function dumpStats() {
  foreach (armyId, armyItems in allItemTemplates.value) {
    if (armyId == "common_army")
      continue
    let tanks = {}
    let planes = {}
    let items = {}

    armyItems.each(function(v) {
      if (v?.itemtype == "vehicle") {
        requireVehicleSpec(v.gametemplate)
        if (v?.itemsubtype in aircraftSubitemType)
          planes[v.gametemplate] <- true
        else
          tanks[v.gametemplate] <- true
      }
      else if (v?.ammoholder != null || v?.ammotemplate != null || v?.itemtype in itemTypeWhitelist) {
        items[v.gametemplate] <- true
      }
    })

    createFolders(armyId)

    if (tanks.len() != 0)
      saveStatsToFile(armyId, "_tanks.csv", TANK_DETAILS, tanks, getVehicleStats)
    if (planes.len() != 0)
      saveStatsToFile(armyId, "_planes.csv", PLANE_DETAILS, planes, getVehicleStats)
    if (items.len() != 0)
      saveStatsToFile(armyId, "_items.csv", getItemDetails(true), items, getItemStats)
  }
}

console_register_command(dumpStats, "meta.dumpStats")
