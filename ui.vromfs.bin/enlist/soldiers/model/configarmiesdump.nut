from "%enlSqGlob/ui_library.nut" import *

let { configs } = require("%enlist/meta/configs.nut")
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { file } = require("io")
let { dir_exists, file_exists } = require("dagor.fs")

const RENAME_FILE_PREFIX = "renameCommonTemplates"
const RENAME_FILE_PATH = "../profileServer/actions"

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

let backArmies = sidesArmies.reduce(@(res, to, from)
  res.rawset(to, res?[to].append(from) ?? [from]), {})

let itemTypesOrder = ["medkits", "medic_medkits", "medbox", "repair_kit",
  "building_tool", "melee", "shovel", "axe", "sword",
  "grenade", "explosion_pack", "molotov", "tnt_block_exploder", "impact_grenade", "smoke_grenade",
  "incendiary_grenade", "antipersonnel_mine", "antitank_mine", "lunge_mine", "mine",
  "backpack", "small_backpack", "radio", "parachute", "medpack",
  "binoculars_usable", "flask_usable",
  "semiauto", "carbine_tanker", "shotgun", "boltaction", "semiauto_sniper",
  "boltaction_noscope", "rifle_grenade_launcher", "rifle_at_grenade_launcher", "antitank_rifle",
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
  "name"
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

let getArmyCampaign = @(armyId) armyId.split("_")[0]

let capFirst = @(str) $"{str.slice(0, 1).toupper()}{str.slice(1)}"

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

let typesDesc = {
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

let mkBaseTable = @() typesDesc.map(@(_) {})

let function collectItemTemplates(all, renames) {
  let templates = configs.value?.items_templates ?? {}
  foreach (armyId, armyTemplates in templates) {
    if (armyId not in sidesArmies)
      // skip common armies
      continue

    let campId = getArmyCampaign(armyId)
    local renamesArmy = renames?[armyId]
    if (renamesArmy == null) {
      renamesArmy = mkBaseTable()
      renames[armyId] <- renamesArmy
    }

    let targetArmy = sidesArmies[armyId]
    local targetData = all?[targetArmy]
    if (targetData == null) {
      targetData = mkBaseTable()
      all[targetArmy] <- targetData
    }
    foreach (basetpl, tmpl in armyTemplates) {
      if (tmpl.itemtype == "soldier")
        continue

      let trimmed = trimUpgradeSuffix(basetpl)
      if (trimmed != basetpl)
        continue

      let field = tmpl.itemtype == "vehicle" ? "vehicles"
        : tmpl.itemtype in itemTypesOrder ? "weapons"
        : "equipment"
      let tmplTarget = targetData[field]
      let template = posterize(tmpl)

      let foundField = renamesArmy.findindex(@(renamesList) basetpl in renamesList)
      if (foundField != null) {
        let foundTpl = renamesArmy[foundField][basetpl]
        tmplTarget[foundTpl] <- template
        // check if renaming field differs
        if (foundField != field) {
          delete renamesArmy[foundField][basetpl]
          renamesArmy[field][basetpl] <- foundTpl
          console_print($"{basetpl} renamed to {foundTpl} and type changed from {foundField} to {field}")
        }
        continue
      }

      local duplicateField = null
      foreach (tmplField, tmpls in targetData)
        if (basetpl in tmpls) {
          duplicateField = tmplField
          break
        }

      if (duplicateField == null) {
        tmplTarget[basetpl] <- template
        continue
      }

      if (isEqual(targetData[duplicateField][basetpl], template))
        continue

      local backTpl = null
      foreach (tmplArmy in backArmies[targetArmy]) {
        let savedTpl = renames?[tmplArmy][duplicateField][basetpl]
        if (savedTpl == null)
          continue
        let savedTemplate = targetData?[duplicateField][savedTpl]
        if (savedTemplate != null && isEqual(savedTemplate, template)) {
          backTpl = savedTpl
          break
        }
      }
      if (backTpl != null) {
        renamesArmy[field][basetpl] <- backTpl
        continue
      }

      let newTpl = $"{basetpl}_{campId}"
      tmplTarget[newTpl] <- template
      renamesArmy[field][basetpl] <- newTpl
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
  local filePath = "../profileServer/item_templates"
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

let function renameFilePath(name) {
  let fileName = $"{name}.das"
  return dir_exists(RENAME_FILE_PATH) ? $"{RENAME_FILE_PATH}/{fileName}" : fileName
}

let function loadRenames(renames, field, variable) {
  let filePath = renameFilePath(variable)
  if (!file_exists(filePath)) {
    console_print($"Not found renaming file {filePath}")
    return
  }

  console_print($"Reading renaming table from {filePath}")
  let input = file(filePath, "rt")
  let text = input.readblob(input.len()).as_string()
  input.close()

  local armyId = null
  foreach (line in text.split("\n")) {
    let split = line.split("\"")
    switch (split.len()) {
      case 3:
        armyId = split[1]
        break

      case 5:
        if (armyId != null) {
          local renamesArmy = renames?[armyId]
          if (renamesArmy == null) {
            renamesArmy = mkBaseTable()
            renames[armyId] <- renamesArmy
          }
          let basetpl = split[1]
          let newtpl = split[3]
          renamesArmy[field][basetpl] <- newtpl
        }
        break
    }
  }
}

let function mkRenameArmies(armyId, templates) {
  let rows = []
  foreach (from in templates.keys().sort()) {
    let to = templates[from]
    rows.append($"      \"{from}\" => \"{to}\"")
  }
  let res = ";\n".join(rows)
  return $"    \"{armyId}\" => \{\{\n{res}\n    \}\}"
}

let function saveRenames(renames, field, variable) {
  let filePath = renameFilePath(variable)
  let output = file(filePath, "wt+")
  output.writestring($"let shared\n  {variable} <- \{\{\n")
  let armies = []
  foreach (armyId in renames.keys().sort()) {
    let templates = renames[armyId][field]
    if (templates.len() > 0)
      armies.append(mkRenameArmies(armyId, templates))
  }
  output.writestring(";\n".join(armies))
  output.writestring($"\n  \}\}\n")
  output.close()
  console_print($"Renaming table is saved to {filePath}")
}

let function dumpItemTemplates() {
  let all = {}
  let renames = {}
  foreach (field, _ in typesDesc)
    loadRenames(renames, field, $"{RENAME_FILE_PREFIX}{capFirst(field)}")
  collectItemTemplates(all, renames)
  foreach (armyId, targetData in all)
    foreach (field, desc in typesDesc) {
      let values = targetData[field]
      if (values.len() == 0)
        continue
      let keys = sortTemplateKeys(values, desc.sort)
      saveTemplates(keys, values, $"{armyId}_{field}", desc?.hasUpgrades ?? false)
    }
  foreach (field, _ in typesDesc)
    saveRenames(renames, field, $"{RENAME_FILE_PREFIX}{capFirst(field)}")
}

console_register_command(dumpItemTemplates, "meta.dumpItemTemplates")
