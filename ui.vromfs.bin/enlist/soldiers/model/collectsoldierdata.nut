from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs

let { getLinkedArmyName, getLinkedSquadGuid } = require("%enlSqGlob/ui/metalink.nut")
let { mkSoldierPhotoName } = require("%enlSqGlob/ui/soldierPhoto.nut")
let { getWeapTemplates, mkEquipment, getItemAnimationBlacklist } = require("%enlist/scene/soldier_tools.nut")
let { getIdleAnimState } = require("%enlSqGlob/animation_utils.nut")
let { getSoldierItem } = require("%enlist/soldiers/model/state.nut")

let getPerksCount = @(perks) (perks?.slots ?? [])
  .reduce(@(res, slots) res + slots.filter(@(v) (v ?? "") != "").len(), 0)

let function collectSoldierPhoto(soldier, soldiersOutfit, objInfoByGuidV, overrideOutfit = [], isLarge = false) {
  if (soldier?.photo != null)
    return soldier

  let { guid = null } = soldier
  let actualSoldier = objInfoByGuidV?[guid]
  if (actualSoldier == null)
    return soldier.__merge({
      photo = null
    })

  let scheme = actualSoldier?.equipScheme ?? {}
  let equipmentInfo = []
  let equipment = mkEquipment(actualSoldier, scheme, soldiersOutfit, overrideOutfit)
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

  let weapTemplates = getWeapTemplates(guid, scheme)
  let soldierTemplate = actualSoldier?.gametemplate
    ? ecs.g_entity_mgr.getTemplateDB().getTemplateByName(actualSoldier.gametemplate)
    : null
  let overridedIdleAnims = soldierTemplate?.getCompValNullable("animation__overridedIdleAnims")

  let animation = getIdleAnimState({
    weapTemplates
    itemTemplates = getItemAnimationBlacklist(actualSoldier, guid, scheme, soldiersOutfit)
    overridedIdleAnims
    seed = guid.hash()
  })

  return soldier.__merge({
    photo = mkSoldierPhotoName(actualSoldier?.gametemplate, equipmentInfo, animation, isLarge)
  })
}

let function collectSoldierDataImpl(
  soldier, perksDataV, curCampSquadsV, armiesV, classesCfgV, campItemsV, objInfoByGuidV, soldiersOutfit,
  soldiersPremiumItems
) {
  let guid = soldier?.guid
  if (guid == null)
    return soldier

  let armyId = getLinkedArmyName(soldier)
  let perks = perksDataV?[guid]
  let { level = 1, maxLevel = 1, exp = 0 } = perks
  let perksCount = getPerksCount(perks)

  let { kind = soldier.sClass } = classesCfgV?[soldier.sClass] //kind by default is sClass to compatibility with 16.02.2021 pserver version
  return collectSoldierPhoto(soldier.__merge({
    primaryWeapon = getSoldierItem(guid, "primary", campItemsV)
      ?? getSoldierItem(guid, "secondary", campItemsV)
      ?? getSoldierItem(guid, "side", campItemsV)
    country = armiesV?[armyId].country
    level = min(level, maxLevel)
    maxLevel
    exp
    perksCount
    armyId
    squadId = curCampSquadsV?[getLinkedSquadGuid(soldier)].squadId
    sKind = kind
  }), soldiersOutfit, objInfoByGuidV, soldiersPremiumItems)
}

return {
  collectSoldierPhoto
  collectSoldierDataImpl
}