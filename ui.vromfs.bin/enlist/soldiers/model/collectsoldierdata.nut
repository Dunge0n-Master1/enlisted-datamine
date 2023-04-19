from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs

let { getLinkedArmyName, getLinkedSquadGuid } = require("%enlSqGlob/ui/metalink.nut")
let { mkSoldierPhotoName } = require("%enlSqGlob/ui/soldierPhoto.nut")
let { getWeapTemplates, mkEquipment, getItemAnimationBlacklist } = require("%enlist/scene/soldier_tools.nut")
let { getIdleAnimState } = require("%enlSqGlob/animation_utils.nut")
let { getSoldierItem } = require("%enlist/soldiers/model/state.nut")

let getPerksCount = @(perks) (perks?.slots ?? [])
  .reduce(@(res, slots) res + slots.filter(@(v) (v ?? "") != "").len(), 0)

  // TODO remove overrideOutfit and isLarge that currently unused
let function collectSoldierPhoto(soldier, soldiersOutfit, overrideOutfit = [], isLarge = false) {
  if (soldier?.photo != null)
    return soldier

  let { guid = null, equipScheme = {}, gametemplate = null } = soldier
  let equipmentInfo = []
  let equipment = mkEquipment(soldier, equipScheme, soldiersOutfit, overrideOutfit)
  if (equipment != null) {
    foreach (slot, equip in equipment) {
      if (!equip || !equip.gametemplate)
        continue
      equipmentInfo.append({
        slot = slot
        tpl = equip.gametemplate
      })
    }
  }

  let weapTemplates = getWeapTemplates(guid, equipScheme)
  let soldierTemplate = gametemplate
    ? ecs.g_entity_mgr.getTemplateDB().getTemplateByName(gametemplate)
    : null
  let overridedIdleAnims = soldierTemplate?.getCompValNullable("animation__overridedIdleAnims")

  let animation = getIdleAnimState({
    weapTemplates
    itemTemplates = getItemAnimationBlacklist(soldier, guid, equipScheme, soldiersOutfit)
    overridedIdleAnims
    seed = guid.hash()
  })

  return soldier.__merge({
    photo = mkSoldierPhotoName(gametemplate, equipmentInfo, animation, isLarge)
  })
}

let function collectSoldierDataImpl(
  soldier, perksDataV, curCampSquadsV, armiesV, classesCfgV, campItemsV, soldiersOutfit,
  soldiersPremiumItems, soldierSchemesV
) {
  let { guid = null, sClass = null, basetpl = null } = soldier
  if (guid == null)
    return soldier

  let armyId = getLinkedArmyName(soldier)
  let perks = perksDataV?[guid]
  let { level = 1, maxLevel = 1, exp = 0 } = perks
  let perksCount = getPerksCount(perks)

  let { kind = sClass } = classesCfgV?[sClass] //kind by default is sClass to compatibility with 16.02.2021 pserver version
  let { country = null } = (soldierSchemesV?[armyId] ?? {})
    .findvalue(@(data) basetpl == data.gametemplate)
  return collectSoldierPhoto(soldier.__merge({
    primaryWeapon = getSoldierItem(guid, "primary", campItemsV)
      ?? getSoldierItem(guid, "secondary", campItemsV)
      ?? getSoldierItem(guid, "side", campItemsV)
    country = country ?? armiesV?[armyId].country
    level = min(level, maxLevel)
    maxLevel
    exp
    perksCount
    armyId
    squadId = curCampSquadsV?[getLinkedSquadGuid(soldier)].squadId
    sKind = kind
  }), soldiersOutfit, soldiersPremiumItems)
}

return {
  collectSoldierPhoto
  collectSoldierDataImpl
}