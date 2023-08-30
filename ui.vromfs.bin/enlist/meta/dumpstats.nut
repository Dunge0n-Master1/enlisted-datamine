import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { DBGLEVEL } = require("dagor.system")
if (DBGLEVEL <= 0)
  return

// NOTE: we want to dump stats in multiple languages at once
// so we switch language during dumping
// nativeLoc is used to avoid localization caching
let { nativeLoc } = require("%dngscripts/localizations.nut")
let { initLocalization, getCurrentLanguage } = require("dagor.localize")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { getWeaponData, getVehicleData
} = require("%enlist/soldiers/model/collectWeaponData.nut")
let { vehicleSpecsDB, requireVehicleSpec } = require("%enlist/vehicles/physSpecs.nut")
let mkItemLevelData = require("%enlist/soldiers/model/mkItemLevelData.nut")
let { getItemDetails, PLANE_DETAILS, TANK_DETAILS, ARMOR_ORDER, getArmaments
} = require("%enlSqGlob/ui/itemsInfo.nut")
let { round_by_value } = require("%sqstd/math.nut")
let { floatToStringRounded } = require("%sqstd/string.nut")
let { logerr } = require("dagor.debug")
let { mkdir } = require("dagor.fs")
let io = require("io")
let DataBlock = require("DataBlock")


let signToText = {
  [0] = "",
  [1] = "PREMIUM",
  [2] = "EVENT",
  [3] = "BP",
}

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
    ? "{0}{1}".subst(printData, nativeLoc($"itemDetails/{measure}", { val=data }))
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
          nativeLoc("guns/{0}".subst(gun?["gun__locName"])),
          gun.count > 1 ? $" x{gun.count}" : "",
          gun["gun__maxAmmo"],
          nativeLoc("itemDetails/count")))
    return "; ".join(guns)
  }
}

let function getVehicleStats(db, vehicle_template_name, header) {
  let template = db.getTemplateByName(vehicle_template_name)
  let localizationKey = template?.getCompValNullable("item__name")

  let vehicleSpecs = vehicleSpecsDB.value?[vehicle_template_name] ?? {}
  let vehicleData = getVehicleData(vehicle_template_name).__update(vehicleSpecs)
  let stats = ", ".join(header.map(function(detail) {
    let data = vehicleData?[detail.key]
    if (data == null)
      return ""
    if (detail.key in VEHICLE_TEXT_CONSTRUCTORS)
      return VEHICLE_TEXT_CONSTRUCTORS[detail.key](data, detail)
    return defaultCtor(data, detail)
  }))
  return { localizationKey, stats }
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
      ? "{0}{1}".subst(ref, nativeLoc($"itemDetails/{measure}", { val = ref }))
      : ref

    let altText = altMeasure != ""
      ? "{0}{1}".subst(printVal, nativeLoc($"itemDetails/{altMeasure}", { val = val }))
      : printVal

    return $"{altText} - {text}"
  }))
}

let ITEMS_TEXT_CONSTRUCTORS = {
  "gun__firingModeNames" : @(data, _) data.len() == 0 ? null
    : "; ".join(data.map(@(name) nativeLoc($"firing_mode/{name}")))
  "splashDamage" :  function(val, _) {
    let dist = nativeLoc("itemDetails/splashDamage", { from = val.radius.x, to = val.radius.y })
    let dmg = nativeLoc("itemDetails/splashDamage/damage", { to = val.damage })
    return $"{dist} {dmg}"
  }
  "rateOfFire" : arrayCtor
  "kineticArmorPower" : tableCtor
  "hitpower" : tableCtor
}

let function getItemStats(db, item_template_name, header) {
  let template = db.getTemplateByName(item_template_name)
  let localizationKey = template?.getCompValNullable("item__name")

  let weaponData = getWeaponData(item_template_name)
  let stats = ", ".join(header.map(function(detail) {
    let data = weaponData?[detail.key]
    if (data == null)
      return ""
    if (detail.key in ITEMS_TEXT_CONSTRUCTORS)
      return ITEMS_TEXT_CONSTRUCTORS[detail.key](data, detail)
    return defaultCtor(data, detail)
  }))
  return { localizationKey, stats }
}


let getSaveFolderPath = @(army) $".meta_stats/{army}"

let function saveStatsToFile(army, file_name, header, items, text_generator) {
  let path = $"{getSaveFolderPath(army)}/{file_name}"
  let file = io.file(path, "wt")

  let headerString = ", ".join(header.map(@(v) nativeLoc(v?.locId ?? $"itemDetails/{v.key}")))
  file.writestring($"Template name:, Localization key:, Localized name:, Type:, Tier:, Max tier:, Access:, {headerString}, Description:\n")

  let db = ecs.g_entity_mgr.getTemplateDB()

  let itemTexts = items.map(function(item_info, template_name) {
    let { localizationKey, stats } = text_generator(db, template_name, header)
    let typeText = item_info.type != null ? nativeLoc($"itemtype/{item_info.type}", "") : ""
    let descText = nativeLoc($"{localizationKey}/desc", "")
    let acessText = signToText[item_info.sign ?? 0]
    let tierText = item_info.tier ?? ""
    let tierMaxText = item_info.tierMax ?? ""
    return $"{template_name}, {localizationKey}, {nativeLoc(localizationKey)}, {typeText}, {tierText}, {tierMaxText}, {acessText}, {stats}, \"{descText}\"\n"
  })

  items.keys().sort().each(@(item_key) file.writestring(itemTexts[item_key]))

  file.close()

  console_print($"Stats saved to {path}")
}


let aircraftSubitemType = {
  fighter_aircraft = true
  assault_aircraft = true
}

// filter out clothes and other unnecessary items
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

let function gatherUsedTemplates(armyItems) {
  let tanks = {}
  let planes = {}
  let items = {}

  let templateData = @(v) { type = v?.itemtype, tier = v?.tier, sign = v?.sign, tierMax = mkItemLevelData(v).value.tierMax }

  armyItems.each(function(v) {
    if (v?.itemtype == "vehicle") {
      requireVehicleSpec(v.gametemplate)
      if (v?.itemsubtype in aircraftSubitemType)
        planes[v.gametemplate] <- templateData(v)
      else
        tanks[v.gametemplate] <- templateData(v)
    }
    else if (v?.ammoholder != null || v?.ammotemplate != null || v?.itemtype in itemTypeWhitelist) {
      items[v.gametemplate] <- templateData(v)
    }
  })

  return { tanks, planes, items }
}

let languagesToDump = [
  "English"
  "Chinese"
  "HChinese"
]

let function dumpStats(file_name_prefix = "") {
  foreach (armyId, armyItems in allItemTemplates.value) {
    let { tanks, planes, items } = gatherUsedTemplates(armyItems)

    let anythingToDump = tanks.len() + planes.len() + items.len() > 0
    if (!anythingToDump)
      continue

    mkdir(getSaveFolderPath(armyId))

    if (tanks.len() != 0)
      saveStatsToFile(armyId, $"{file_name_prefix}_tanks.csv", TANK_DETAILS, tanks, getVehicleStats)
    if (planes.len() != 0)
      saveStatsToFile(armyId, $"{file_name_prefix}_planes.csv", PLANE_DETAILS, planes, getVehicleStats)
    if (items.len() != 0)
      saveStatsToFile(armyId, $"{file_name_prefix}_items.csv", getItemDetails(true), items, getItemStats)
  }
  console_print($"Stats Dump Finished!")
}

let function getLocLoadSettingsBlk() {
  let locBlk = DataBlock()
  // copy of blk init from dng_load_localization()
  locBlk.addStr("english_us", "English")
  locBlk.addStr("default_audio", "English")
  locBlk.addStr("default_lang", "English")

  let langsBlk = locBlk.addNewBlock("locTable")
  langsBlk.addStr("file", "lang/common/common.csv")
  langsBlk.addStr("file", "lang/pkg_dev/pkg_dev.csv")

  return locBlk
}

let function dumpMultipleLanguagesStats() {
  let currentLang = getCurrentLanguage()
  let locBlk = getLocLoadSettingsBlk()
  foreach (lang in languagesToDump) {
    initLocalization(locBlk, lang)
    dumpStats($"_{lang}")
  }
  initLocalization(locBlk, currentLang)
}

console_register_command(dumpStats, "meta.dumpStats")
console_register_command(dumpMultipleLanguagesStats, "meta.dumpStatsMultipleLanguages", "Dump stats for multiple languages (English, Chinese, HChinese by default)")
