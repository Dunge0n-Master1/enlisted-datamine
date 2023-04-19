from "%enlSqGlob/ui_library.nut" import *

let { configs } = require("%enlist/meta/configs.nut")
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { file } = require("io")
let { dir_exists } = require("dagor.fs")

const USSR = "ussr_common"
const GERMANY = "ger_common"
const USA = "usa_common"
const JAPAN = "jap_common"

let sidesArmies = {
  moscow_allies     = USSR
  moscow_axis       = GERMANY
  berlin_allies     = USSR
  berlin_axis       = GERMANY
  normandy_allies   = USA
  normandy_axis     = GERMANY
  tunisia_alles     = USA
  tunisia_axis      = GERMANY
  stalingrad_allies = USSR
  stalingrad_axis   = GERMANY
  pacific_allies    = USA
  pacific_axis      = JAPAN
}

let countryConst = {
  germany = "GERMANY"
  italy = "ITALY"
  usa = "USA"
  ussr = "USSR"
  ussr_female = "USSR_FEMALE"
  britain = "BRITAIN"
  morocco = "MOROCCO"
  japan = "JAPAN"
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
  return (itemTypesOrder?[a.itemtype] ?? 0) <=> (itemTypesOrder?[b.itemtype] ?? 0)
    || (a?.unlocklevel ?? 0) <=> (b?.unlocklevel ?? 0)
    || (a?.tier ?? 0) <=> (b?.tier ?? 0)
    || aidx <=> bidx
}

let function sortVehicles(tbl, aidx, bidx) {
  let a = tbl[aidx]
  let b = tbl[bidx]
  return (vehicleSubtypesOrder?[a.itemsubtype] ?? 0) <=> (vehicleSubtypesOrder?[b.itemsubtype] ?? 0)
    || (a?.unlocklevel ?? 0) <=> (b?.unlocklevel ?? 0)
    || (a?.tier ?? 0) <=> (b?.tier ?? 0)
    || aidx <=> bidx
}

let function collectItemTemplates() {
  let all = {}
  foreach (armyId, templates in configs.value?.items_templates ?? {}) {
    if (armyId not in sidesArmies)
      // skip common army
      continue
    let targetArmy = sidesArmies[armyId]
    if (targetArmy not in all)
      all[targetArmy] <- { equipment = {}, items = {}, vehicles = {} }
    let targetData = all[targetArmy]
    foreach (basetpl, template in templates) {
      if (template.itemtype == "soldier")
        continue

      let trimmed = trimUpgradeSuffix(basetpl)
      if (trimmed != basetpl)
        continue

      if (template.itemtype == "vehicle")
        targetData.vehicles[basetpl] <- template
      else if (template.itemtype in itemTypesOrder && "slot" not in template)
        targetData.items[basetpl] <- template
      else
        targetData.equipment[basetpl] <- template
    }
  }
  return all
}

let function sortTemplateKeys(tbl, sortFn) {
  let keys = tbl.keys()
  keys.sort(@(a, b) sortFn(tbl, a, b))
  return keys
}

// non recursive function, used only for known ItemTemplate structure!
let function dumpValue(key, value) {
  if (key == "country" && value in countryConst)
    return $"      {key} = {countryConst[value]}"
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
      return $"      {key} <- [\{ auto[] {res} \}]"
    }
    let res = "; ".join(value)
    return $"      {key} <- [\{ auto[] {res} \}]"
  }
  return $"      {key} = {value}"
}

let function mkTemplate(basetpl, template) {
  let rows = []
  foreach (key, value in template)
    rows.append(dumpValue(key, value))
  let res = ",\n".join(rows)
  return $"    \"{basetpl}\" => [[ ItemTemplate\n{res}\n    ]]"
}

let function saveTemplates(keys, values, variable) {
  local filePath = $"../profileServer/item_templates"
  let fileName = $"{variable}.das"
  filePath = dir_exists(filePath) ? $"{filePath}/{fileName}" : fileName
  let output = file(filePath, "wt+")
  output.writestring("require item_templates.item_template\nrequire profile\n\n")
  output.writestring($"let shared\n  {variable} <- \{\{\n")
  let templates = []
  foreach (basetpl in keys)
    templates.append(mkTemplate(basetpl, values[basetpl]))
  output.writestring(";\n".join(templates))
  output.writestring("\n  }}\n")
  output.close()
  console_print($"Saved to {filePath}")
}

let tableSortFunc = {
  equipment = sortEquipment
  items = sortItems
  vehicles = sortVehicles
}

let function dumpItemTemplates() {
  let all = collectItemTemplates()
  foreach (armyId, targetData in all) {
    foreach (field, sortFunc in tableSortFunc) {
      let values = targetData[field]
      let keys = sortTemplateKeys(values, sortFunc)
      saveTemplates(keys, values, $"{armyId}_{field}")
    }
  }
}

console_register_command(dumpItemTemplates, "meta.dumpItemTemplates")
