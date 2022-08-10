import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let armyData = require("%ui/hud/state/armyData.nut")
let weaponSlots = require("%enlSqGlob/weapon_slots.nut")
let { mkSoldierPhotoName } = require("%enlSqGlob/ui/soldierPhoto.nut")
let { getIdleAnimState } = require("%enlSqGlob/animation_utils.nut")
let { GRENADES_ORDER } = require("%ui/hud/huds/player_info/grenadeIcon.nut")
let { MINES_ORDER } = require("%ui/hud/huds/player_info/mineIcon.nut")

let soldierFieldKeys = [
  "guid", "name", "surname", "callname", "sClass", "sKind", "tier", "level", "maxLevel",
  "exp", "availPerks", "perksCount", "heroTpl"
]

let function getWeaponData(weapSlotIdx, soldier) {
  let weapTemplate = soldier?["human_weap__weapTemplates"][weaponSlots.weaponSlotsKeys[weapSlotIdx]]
  let weapInfo = soldier?["human_weap__weapInfo"][weapSlotIdx]

  local tplName = weapTemplate
  if (tplName == null || weapSlotIdx == weaponSlots.EWS_GRENADE)
    tplName = weapInfo?.reserveAmmoTemplate

  let db = ecs.g_entity_mgr.getTemplateDB()
  let template = tplName == null ? null : db.getTemplateByName(tplName)

  let gunMods = []
  weapInfo?.gunMods.each(function(modTplName, _slotTag) {
    let modTemplate = db.getTemplateByName(modTplName)
    gunMods.append({
      templateName = modTplName
      name = loc(modTemplate?.getCompValNullable("item__name") ?? modTplName)
    })
  })

  return {
    templateName = tplName
    isPrimary = weapSlotIdx == weaponSlots.EWS_PRIMARY || weapSlotIdx == weaponSlots.EWS_SECONDARY
    name = loc(template?.getCompValNullable("item__name") ?? $"weaponSlot/{weapSlotIdx}")
    gunMods
  }
}

let function collectSoldierData(soldier, armyId, squadId, country) {
  let res = {}
  foreach (key in soldierFieldKeys)
    if (key in soldier)
      res[key] <- soldier[key]

  let db = ecs.g_entity_mgr.getTemplateDB()
  let { equipment = [], inventory = [] } = soldier

  let equipmentInfo = []
  let itemTemplates = []
  foreach (slot, equip in equipment) {
    equipmentInfo.append({
      slot = slot,
      tpl = equip.gametemplate
    })
    let itemTemplate = db.getTemplateByName(equip.gametemplate)
    if (itemTemplate != null)
      itemTemplates.append(itemTemplate)
  }

  let grenades = []
  let mines = []
  local targetHealCount = 0
  local hasFlask = false
  foreach (item in inventory) {
    let itemTemplate = db.getTemplateByName(item.gametemplate)
    if (itemTemplate == null)
      continue

    let gType = itemTemplate.getCompValNullable("item__grenadeType")
    if (gType != null && gType != "shell")
      grenades.append(gType)
    let glType = itemTemplate.getCompValNullable("item__grenadeLikeType")
    if (glType != null)
      grenades.append(glType)
    let mType = itemTemplate.getCompValNullable("item__mineType")
    if (mType != null)
      mines.append(mType)
    let heal = itemTemplate.getCompValNullable("item__healAmount") ?? 0
    if (heal > 0)
      ++targetHealCount
    let isFlask = itemTemplate.getCompValNullable("flask")
    if (isFlask != null)
      hasFlask = true
  }
  let grenadeType = grenades.reduce(@(a, b)
    (GRENADES_ORDER?[a] ?? 0) <= (GRENADES_ORDER?[b] ?? 0) ? a : b)
  let mineType = mines.reduce(@(a, b)
    (MINES_ORDER?[a] ?? 0) <= (MINES_ORDER?[b] ?? 0) ? a : b)

  let guid = soldier?.guid.hash()
  let soldierTemplate = db.getTemplateByName(soldier.gametemplate)
  let overridedIdleAnims = soldierTemplate?.getCompValNullable("animation__overridedIdleAnims")
  let animation = getIdleAnimState({
    weapTemplates = soldier?["human_weap__weapTemplates"]
    itemTemplates
    overridedIdleAnims
    seed = guid
  })

  return res.__update({
    armyId
    squadId
    country
    weapons = array(weaponSlots.EWS_NUM, null).map(@(_, idx) getWeaponData(idx, soldier))
    photo = mkSoldierPhotoName(soldier?.gametemplate, equipmentInfo, animation)
    photoLarge = mkSoldierPhotoName(soldier?.gametemplate, equipmentInfo, animation, true)
    grenadeType
    mineType
    targetHealCount
    hasFlask
  })
}

let soldiers = Computed(function() {
  let res = {}
  let squadsList = armyData.value?.squads
  if (squadsList == null)
    return res

  let armyId = armyData.value.armyId
  let country = armyData.value.country
  foreach (squad in squadsList) {
    foreach (soldier in squad.squad)
      res[soldier.guid] <- collectSoldierData(soldier, armyId, squad.squadId, country)
  }
  return res
})

return soldiers