from "%enlSqGlob/ui_library.nut" import *

let { soldierClasses, getClassCfg, getKindCfg, getClassNameWithGlyph
} = require("%enlSqGlob/ui/soldierClasses.nut")
let { getItemName, trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")

let function getClassByContext(effect, context) {
  let { armyId, squadId, squadsCfg } = context
  let { squadType = "" } = squadsCfg?[armyId][squadId]
  return squadType in soldierClasses ? squadType : effect.findindex(@(_) true)
}

let firstValue = @(tbl, def = null) (tbl ?? {}).findvalue(@(_) true) ?? def

let function appendSquadSize(effect, _context) {
  let size = firstValue(effect, 0)
  return {
    name = "research/squad_size"
    description = "research/squad_size_desc"
    icon_id = "squad_size"
    params = { size }
  }
}

let function appendSoldiersReserve(effect, _context) {
  let size = effect ?? 0
  return {
    name = "research/plus_reserve"
    description = "research/plus_reserve_desc"
    icon_id = "reserve_upgrade_icon"
    params = { size }
  }
}

let function appendSquadXpBoost(effect, _context) {
  let value = (firstValue(effect, 0) * 100).tointeger()
  return {
    name = "research/squad_xp_boost"
    description = "research/squad_xp_boost_desc"
    icon_id = "squad_xp_boost_icon"
    params = { value }
  }
}

let function appendBuildingUnlocks(effect, _context) {
  let id = firstValue(effect, {}).findindex(@(_) true) ?? "0"
  return {
    name = $"research/buildings_unlock_{id}"
    description = $"research/buildings_unlock_{id}_desc"
    icon_id = $"building_unlock_{id}_icon"
  }
}

let function appendArtilleryTypeUnlocks(effect, _context) {
  let id = firstValue(effect, {}).findindex(@(_) true) ?? "0"
  return {
    name = $"research/artillery_type_unlock_{id}"
    description = $"research/artillery_type_unlock_{id}_desc"
    icon_id = $"artillery_type_unlock_{id}_icon"
    iconOverride = { scale = 0.8, pos = [0.4, 0.5] }
  }
}

let function appendArtilleryCooldownMul(effect, _context) {
  let value = (1.0 / firstValue(effect, 1.0)).tointeger()
  return {
    name = "research/artillery_cooldown_mul"
    description = "research/artillery_cooldown_mul_desc"
    icon_id = "artillery_upgrade_icon"
    params = { value }
  }
}

let function appendSquadClassLimit(effect, _context) {
  let [ kind = "", count = 0 ] = firstValue(effect, {}).topairs()?[0]
  return {
    name = "research/plus_class"
    description = "research/plus_class_desc"
    icon_id = kind
    params = {
      kind = loc(getKindCfg(kind).locId)
      count
    }
  }
}

let function appendMaxTrainingLevel(effect, context) {
  let sClass = getClassByContext(effect, context)
  local level = firstValue(effect, 0)
  let { class_training = {} } = context
  level += class_training?[sClass] ?? 0
  class_training[sClass] <- level
  context.class_training <- class_training
  ++level
  return {
    name = "research/soldier_tier"
    description = "research/soldier_tier_desc"
    icon_id = $"soldier_tier{level}"
    params = {
      kind = getClassNameWithGlyph(sClass, context?.armyId)
      level
    }
  }
}

let function appendWeaponUpgrades(effect, context) {
  let itemtpl = effect?[0]
  let basetpl = trimUpgradeSuffix(itemtpl)
  let { armyId, alltemplates } = context
  let templates = alltemplates?[armyId] ?? {}
  let tmpl = templates?[itemtpl] ?? templates?[basetpl]
  let { tier = 0, itemsubtype = "", gametemplate = "" } = tmpl
  let params = {
    item = loc(getItemName(tmpl))
    tier
  }

  if (itemsubtype == "tank" || itemsubtype == "bike")
    return {
      name = "research/upgrade_vehicle"
      description = "research/upgrade_vehicle_desc"
      gametemplate
      templateOverride = { scale = 0.9, itemOfsY = -0.2 }
      icon_id = $"soldier_tier{tier}"
      iconOverride = { scale = 0.55, pos = [0.95, 0] }
      params
    }

  if (itemsubtype == "assault_aircraft" || itemsubtype == "fighter_aircraft")
    return {
      name = "research/upgrade_vehicle"
      description = "research/upgrade_vehicle_desc"
      gametemplate
      templateOverride = { scale = 0.9, itemPitch = 180, itemYaw = 90, itemRoll = -90, itemOfsY = 0.2 }
      icon_id = $"soldier_tier{tier}"
      iconOverride = { scale = 0.55, pos = [0, 0.95] }
      params
    }

  return {
    name = "research/upgrade_weapon"
    description = "research/upgrade_weapon_desc"
    gametemplate
    templateOverride = { itemPitch = -35 }
    icon_id = $"soldier_tier{tier}"
    iconOverride = { scale = 0.55, pos = [0, 0.95] }
    params
  }
}

let function appendWeaponUpgradeDiscount(effect, context) {
  local [ itemtpl = "", value = 0 ] = effect?.topairs()[0]
  value = (value * 100).tointeger()
  let basetpl = trimUpgradeSuffix(itemtpl)
  let { armyId, alltemplates } = context
  let templates = alltemplates?[armyId] ?? {}
  let tmpl = templates?[itemtpl] ?? templates?[basetpl]
  let { itemsubtype = "", gametemplate = "" } = tmpl
  let params = {
    item = loc(getItemName(tmpl))
    value
  }

  if (itemsubtype == "tank" || itemsubtype == "bike")
    return {
      name = "research/weapon_upgrade_discount"
      description = "research/weapon_upgrade_discount_desc"
      gametemplate
      templateOverride = { scale = 0.9, itemOfsY = -0.2 }
      icon_id = "weapon_upgrade_cost_icon"
      iconOverride = { scale = 0.4, pos = [0.9, 0.1] }
      params
    }

  if (itemsubtype == "assault_aircraft" || itemsubtype == "fighter_aircraft")
    return {
      name = "research/weapon_upgrade_discount"
      description = "research/weapon_upgrade_discount_desc"
      gametemplate
      templateOverride = { scale = 0.9, itemPitch = 180, itemYaw = 90, itemRoll = -90, itemOfsY = 0.2 }
      icon_id = "weapon_upgrade_cost_icon"
      iconOverride = { scale = 0.4, pos = [0.9, 0.95] }
      params
    }

  return {
    name = "research/weapon_upgrade_discount"
    description = "research/weapon_upgrade_discount_desc"
    gametemplate
    templateOverride = { itemPitch = -35 }
    icon_id = "weapon_upgrade_cost_icon"
    iconOverride = { scale = 0.40, pos = [0.2, 0.9] }
    params
  }
}

let function appendWeaponTuning(effect, context) {
  let itemtpl = effect?.keys()[0]
  let basetpl = trimUpgradeSuffix(itemtpl)
  let { armyId, alltemplates } = context
  let templates = alltemplates?[armyId] ?? {}
  let tmpl = templates?[itemtpl] ?? templates?[basetpl]
  let { itemsubtype = "", gametemplate = "" } = tmpl
  let params = {
    item = loc(getItemName(tmpl))
  }

  if (itemsubtype == "tank" || itemsubtype == "bike")
    return {
      name = "research/weapon_tuning"
      description = "research/weapon_tuning_desc"
      gametemplate
      templateOverride = { scale = 0.9, itemOfsY = -0.2 }
      icon_id = "veteran_perk_icon"
      iconOverride = { scale = 0.4, pos = [0.95, 0.15] }
      params
    }

  if (itemsubtype == "assault_aircraft" || itemsubtype == "fighter_aircraft")
    return {
      name = "research/weapon_tuning"
      description = "research/weapon_tuning_desc"
      gametemplate
      templateOverride = { scale = 0.9, itemPitch = 180, itemYaw = 90, itemRoll = -90, itemOfsY = 0.2 }
      icon_id = $"veteran_perk_icon"
      iconOverride = { scale = 0.4, pos = [0.95, 0.8] }
      params
    }

  return {
    name = "research/weapon_tuning"
    description = "research/weapon_tuning_desc"
    gametemplate
    templateOverride = { itemPitch = -35 }
    icon_id = "veteran_perk_icon"
    iconOverride = { scale = 0.4, pos = [0.15, 0.8] }
    params
  }
}

let function appendClassXpBoost(effect, context) {
  let sClass = getClassByContext(effect, context)
  local value = firstValue(effect, 0)
  value = (value * 100).tointeger()
  return {
    name = "research/class_xp_boost"
    description = "research/class_xp_boost_desc"
    icon_id = "class_xp_boost_icon"
    params = {
      kind = getClassNameWithGlyph(sClass, context?.armyId)
      value
    }
  }
}

let function appendSlotUnlock(effect, context) {
  let sClass = getClassByContext(effect, context)
  let [ slot = "" ] = firstValue(effect, [])
  return {
    name = $"research/{slot}_slot_upgrade"
    description = $"research/{slot}_slot_upgrade_desc"
    icon_id = $"{slot}_slot_upgrade_icon"
    params = {
      kind = getClassNameWithGlyph(sClass, context?.armyId)
      slot = loc($"inventory/{slot}", "")
    }
  }
}

let function appendVeteranClass(effect, context) {
  let sClass = getClassByContext(effect, context)
  let { kind } = getClassCfg(sClass)
  return {
    name = $"research/veteran_class"
    description = "research/veteran_desc"
    icon_id = $"{kind}_veteran"
    params = {
      kind = getClassNameWithGlyph(sClass, context?.armyId)
    }
  }
}

let function appendDisassembleBonus(effect, context) {
  local [ itemtpl = "", value = 0 ] = effect?.topairs()[0]
  value = (value * 100).tointeger()
  let basetpl = trimUpgradeSuffix(itemtpl)
  let { armyId, alltemplates } = context
  let templates = alltemplates?[armyId] ?? {}
  let tmpl = templates?[itemtpl] ?? templates?[basetpl]
  let { gametemplate = "" } = tmpl
  return {
    name = "research/disassemble_bonus"
    description = "research/disassemble_bonus_desc"
    gametemplate
    templateOverride = { itemPitch = -35 }
    icon_id = "weapon_parts_boost_icon"
    iconOverride = { scale = 0.4, pos = [0.15, 0.85] }
    params = {
      item = loc(getItemName(tmpl))
      value
    }
  }
}

let RESEARCH_DATA_APPENDERS = {
  squad_size = appendSquadSize
  soldiersReserve = appendSoldiersReserve
  squad_xp_boost = appendSquadXpBoost
  building_unlock = appendBuildingUnlocks
  artillery_cooldown_mul = appendArtilleryCooldownMul
  artillery_type_unlock = appendArtilleryTypeUnlocks
  squad_class_limit = appendSquadClassLimit
  class_training = appendMaxTrainingLevel
  weapon_upgrades = appendWeaponUpgrades
  weapon_upgrade_discount = appendWeaponUpgradeDiscount
  weapon_tuning = appendWeaponTuning
  class_xp_boost = appendClassXpBoost
  slot_unlock = appendSlotUnlock
  veteran_class = appendVeteranClass
  disassemble_bonus = appendDisassembleBonus
}

local function prepareResearch(research, context) {
  // cleanup effects table
  let effect = (research?.effect ?? {})
    .filter(@(val) (val?.len() ?? val ?? 0) != 0)
  research = research.__merge({ effect })
  let effectId = effect.findindex(@(_) true)
  if (effectId in effect) {
    let appender = RESEARCH_DATA_APPENDERS[effectId]
    research.__update(appender(effect[effectId], context))
  }
  return research
}

return prepareResearch