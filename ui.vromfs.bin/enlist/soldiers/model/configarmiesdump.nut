from "%enlSqGlob/ui_library.nut" import *

let { configs } = require("%enlist/meta/configs.nut")
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { file } = require("io")
let { dir_exists } = require("dagor.fs")

const USSR    = "common_ussr"
const GERMANY = "common_ger"
const USA     = "common_usa"
const JAPAN   = "common_jap"

let sidesArmies = {
  moscow_allies     = USSR
  moscow_axis       = GERMANY
  berlin_allies     = USSR
  berlin_axis       = GERMANY
  normandy_allies   = USA
  normandy_axis     = GERMANY
  tunisia_allies    = USA
  tunisia_axis      = GERMANY
  stalingrad_allies = USSR
  stalingrad_axis   = GERMANY
  pacific_allies    = USA
  pacific_axis      = JAPAN
}

let itemTypesOrder = ["medkits", "medic_medkits", "medbox", "repair_kit",
  "building_tool", "melee", "shovel", "axe", "sword",
  "grenade", "explosion_pack", "molotov", "tnt_block_exploder", "impact_grenade", "smoke_grenade",
  "incendiary_grenade", "antipersonnel_mine", "antitank_mine", "lunge_mine", "mine",
  "backpack", "small_backpack",
  "binoculars_usable","flask_usable",
  "semiauto", "carbine_tanker", "shotgun", "boltaction", "semiauto_sniper",
  "boltaction_noscope", "rifle_grenade_launcher", "antitank_rifle",
  "infantry_launcher", "launcher", "mgun", "submgun", "carbine_pistol", "assault_rifle",
  "assault_rifle_stl", "flaregun", "mortar", "flamethrower", "sideweapon",
  "bayonet", "scope", "grenade_launcher"
].reduce(@(res, k, idx) res.rawset(k, idx + 1), {}) //warning disable: -unwanted-modification

let vehicleSubtypesOrder = {
  tank = 1
  fighter_aircraft = 2
  assault_aircraft = 3
  bike = 4
}

let keysOrder = [
  "itemtype"
  "itemsubtype"
  "gametemplate"
  "country"
  "tier"
  "crew"
  "ammoholder"
  "ammotemplate"
  "ammonum"
  "additionalAmmoTemplates"
  "additionalAmmoNums"
  "equipSchemeId"
  "upgradesId"
  "sign"
  "isFixed"
  "isShowDebugOnly"
  "isZeroHidden"
  "slot"
  "slotTemplates"
]

let keysValues = {
  country = {
    germany     = "GERMANY"
    italy       = "ITALY"
    usa         = "USA"
    ussr        = "USSR"
    ussr_female = "USSR_FEMALE"
    britain     = "BRITAIN"
    morocco     = "MOROCCO"
    japan       = "JAPAN"
  }
  sign = {
    [1] = "SIGN_PREMIUM",
    [2] = "SIGN_EVENT",
    [3] = "SIGN_BP",
  }
}

// keep only tracked fields
let function posterize(data) {
  let res = {}
  foreach (key in keysOrder)
    if (key in data)
      res[key] <- data[key]
  return res
}

let function sortEquipment(tbl, aidx, bidx) {
  let a = tbl[aidx]
  let b = tbl[bidx]
  return (a?.slot ?? "") <=> (b?.slot ?? "")
    || (a?.itemsubtype ?? "") <=> (b?.itemsubtype ?? "")
    || aidx <=> bidx
}

let function sortItems(tbl, aidx, bidx) {
  let a = tbl[aidx]
  let b = tbl[bidx]
  return (a?.isShowDebugOnly ?? false) <=> (b?.isShowDebugOnly ?? false)
    || (a?.sign ?? 0) <=> (b?.sign ?? 0)
    || (itemTypesOrder?[a.itemtype] ?? 0) <=> (itemTypesOrder?[b.itemtype] ?? 0)
    || (a?.unlocklevel ?? 0) <=> (b?.unlocklevel ?? 0)
    || (a?.tier ?? 0) <=> (b?.tier ?? 0)
    || aidx <=> bidx
}

let function sortVehicles(tbl, aidx, bidx) {
  let a = tbl[aidx]
  let b = tbl[bidx]
  return (a?.isShowDebugOnly ?? false) <=> (b?.isShowDebugOnly ?? false)
    || (a?.sign ?? 0) <=> (b?.sign ?? 0)
    || (vehicleSubtypesOrder?[a.itemsubtype] ?? 0) <=> (vehicleSubtypesOrder?[b.itemsubtype] ?? 0)
    || (a?.unlocklevel ?? 0) <=> (b?.unlocklevel ?? 0)
    || (a?.tier ?? 0) <=> (b?.tier ?? 0)
    || aidx <=> bidx
}

let function collectItemTemplates(all, renames) {
  foreach (armyId, templates in configs.value?.items_templates ?? {}) {
    if (armyId not in sidesArmies)
      // skip common armies
      continue

    let renamesArmy = {}
    renames[armyId] <- renamesArmy
    let targetArmy = sidesArmies[armyId]
    if (targetArmy not in all)
      all[targetArmy] <- { equipment = {}, weapons = {}, vehicles = {} }
    let targetData = all[targetArmy]
    foreach (basetpl, tmpl in templates) {
      if (tmpl.itemtype == "soldier")
        continue

      let trimmed = trimUpgradeSuffix(basetpl)
      if (trimmed != basetpl)
        continue

      let target = tmpl.itemtype == "vehicle" ? targetData.vehicles
        : tmpl.itemtype in itemTypesOrder && "slot" not in tmpl ? targetData.weapons
        : targetData.equipment
      let template = posterize(tmpl)

      if (basetpl not in target)
        target[basetpl] <- template
      else if (!isEqual(target[basetpl], template)) {
        local idx = 1
        do {
          let tpl = $"{basetpl}_{idx}"
          if (tpl not in target) {
            target[tpl] <- template
            renamesArmy[basetpl] <- tpl
            break
          }
          if (isEqual(target[tpl], template))
            break
          ++idx
        } while(true)
      }
    }
  }
}

let function sortTemplateKeys(tbl, sortFn) {
  let keys = tbl.keys()
  keys.sort(@(a, b) sortFn(tbl, a, b))
  return keys
}

// non recursive function, used only for known ItemTemplate structure!
let function dumpValue(key, value) {
  if (key in keysValues) {
    let lookup = keysValues[key]
    if (value in lookup)
      return $"      {key} = {lookup[value]}"
  }
  if (typeof value == "string")
    return $"      {key} = \"{value}\""
  if (typeof value == "table") {
    let rows = []
    foreach (slot, tmpl in value)
      rows.append($"        \"{slot}\" => \"{tmpl}\"")
    let res = ";\n".join(rows)
    return $"      {key} <- \{\{\n{res}\n      \}\}"
  }
  if (typeof value == "array") {
    if (typeof value[0] == "string") {
      let res = "; ".join(value.map(@(s) $"\"{s}\""))
      return $"      {key} <- [\{ string[] {res} \}]"
    }
    if (typeof value[0] == "integer") {
      let res = "; ".join(value)
      return $"      {key} <- [\{ int[] {res} \}]"
    }
    let res = "; ".join(value)
    return $"      {key} <- [\{ auto[] {res} \}]"
  }
  return $"      {key} = {value}"
}

let function mkTemplate(basetpl, template) {
  let rows = []
  foreach (key in keysOrder)
    if (key in template)
      rows.append(dumpValue(key, template[key]))
  let res = ",\n".join(rows)
  return $"    \"{basetpl}\" => [[ ItemTemplate\n{res}\n    ]]"
}

let function saveTemplates(keys, values, variable, hasUpgrades = false) {
  local filePath = $"../profileServer/item_templates"
  let fileName = $"{variable}.das"
  filePath = dir_exists(filePath) ? $"{filePath}/{fileName}" : fileName
  let output = file(filePath, "wt+")
  output.writestring("require item_templates.upgrades.genUpgrades\nrequire item_templates.item_template\nrequire profile\n\n")
  output.writestring($"let shared\n  {variable} <- {hasUpgrades ? "addUpgradesToTemplates(" : ""}\{\{\n")
  let templates = []
  foreach (basetpl in keys)
    templates.append(mkTemplate(basetpl, values[basetpl]))
  output.writestring(";\n".join(templates))
  output.writestring($"\n  \}\}{hasUpgrades ? ")" : ""}\n")
  output.close()
  console_print($"Saved to {filePath}")
}

let tableSortFunc = {
  equipment = {
    sort = sortEquipment
  }
  weapons = {
    sort = sortItems
    hasUpgrades = true
  }
  vehicles = {
    sort = sortVehicles
    hasUpgrades = true
  }
}

let function mkRenameArmies(armyId, templates) {
  let rows = []
  foreach (from, to in templates)
    rows.append($"      \"{from}\" => \"{to}\"")
  let res = ";\n".join(rows)
  return $"    \"{armyId}\" => \{\{\n{res}\n    \}\}"
}

let function saveRenames(renames, variable) {
  local filePath = $"../profileServer/actions"
  let fileName = $"{variable}.das"
  filePath = dir_exists(filePath) ? $"{filePath}/{fileName}" : fileName
  let output = file(filePath, "wt+")
  output.writestring($"let shared\n  {variable} <- \{\{\n")
  let armies = []
  foreach (armyId, templates in renames)
    if (templates.len() > 0)
      armies.append(mkRenameArmies(armyId, templates))
  output.writestring(";\n".join(armies))
  output.writestring($"  \}\}\n")
  output.close()
  console_print($"Renaming table is saved to {filePath}")
}

let function dumpItemTemplates() {
  let all = {}
  let renames = {}
  collectItemTemplates(all, renames)
  foreach (armyId, targetData in all) {
    foreach (field, desc in tableSortFunc) {
      let values = targetData[field]
      let keys = sortTemplateKeys(values, desc.sort)
      saveTemplates(keys, values, $"{armyId}_{field}", desc?.hasUpgrades ?? false)
    }
  }
  saveRenames(renames, "mutateProfileCommon")
}

console_register_command(dumpItemTemplates, "meta.dumpItemTemplates")
