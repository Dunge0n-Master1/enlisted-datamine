import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { logerr } = require("dagor.debug")
let { Point3 } = require("dagor.math")
let { curCampSoldiers, objInfoByGuid, getSoldierItem, getSoldierItemSlots,
  getModSlots, curSquadSoldiersInfo
} = require("%enlist/soldiers/model/state.nut")
let { getIdleAnimState } = require("%enlSqGlob/animation_utils.nut")
let weaponSlots = require("%enlSqGlob/weapon_slots.nut")
let weaponSlotNames = require("%enlSqGlob/weapon_slot_names.nut")
let curGenFaces = require("%enlist/faceGen/gen_faces.nut")
let { getLinkedArmyName, getFirstLinkByType, hasLinkByType } = require("%enlSqGlob/ui/metalink.nut")
let { allItemTemplates, findItemTemplate
} = require("%enlist/soldiers/model/all_items_templates.nut")
let { campItemsByLink } = require("%enlist/meta/profile.nut")
let { soldierOverrides, isSoldierDisarmed, isSoldierSlotsSwap, getSoldierIdle,
  getSoldierHeadTemplate, getSoldierFace, faceGenOverrides, getSoldierFaceGen
} = require("soldier_overrides.nut")

let DB = ecs.g_entity_mgr.getTemplateDB()

let WEAPON_SLOTS = {
  primary = true, secondary = true, side = true, tertiary = true,
  melee = true, grenade = true }

let INVENTORY_SLOTS = { inventory = true, grenade = true, mine = true }

let IGNORE_SECOND_PASS = { backpack = true, parachute = true }

let soldierViewGen = Watched(0)
let soldierViewNext = @(...) soldierViewGen(soldierViewGen.value + 1)
soldierOverrides.subscribe(soldierViewNext)
faceGenOverrides.subscribe(soldierViewNext)
curSquadSoldiersInfo.subscribe(soldierViewNext)
let appearanceToRender = Watched(null)

let initSoldierQuery = ecs.SqQuery("initSoldierQuery", {
  comps_rw = [
    ["animchar__res", ecs.TYPE_STRING],
    ["guid", ecs.TYPE_STRING],
    ["guid_hash", ecs.TYPE_INT],
    ["human_weap__weapInfo", ecs.TYPE_ARRAY],
    ["animchar__scale", ecs.TYPE_FLOAT],
    ["animchar__depScale", ecs.TYPE_POINT3],
    ["animchar__transformScale", ecs.TYPE_POINT3],
    ["appearance__rndSeed", ecs.TYPE_INT]
  ]
})

let function initFacegenParams(face_equip, animchar_disabled_params, init_comps) {
  let template = DB.getTemplateByName(face_equip.template)
  let animchar = template?.getCompValNullable("animchar__res")
  let { faceId = null } = face_equip
  if (animchar && faceId != null) {
    let params = getSoldierFaceGen(animchar, faceId) ?? curGenFaces?[animchar][faceId.tostring()]
    if (params != null) {
      init_comps["animcharParams"] <- params
      foreach (param in animchar_disabled_params)
        if (init_comps?["animcharParams"][param] != null)
          delete init_comps["animcharParams"][param]
    } else
      log($"Soldier {animchar} have no {faceId} face gen params")
  }
}

let function calcFaceGenDisableParams(equipment) {
  let animcharDisabledParams = []
  foreach (eq in equipment){
    if (!eq || !eq.template)
      continue
    let template = DB.getTemplateByName(eq.template)
    animcharDisabledParams.extend(template?.getCompValNullable("disabledFaceGenParams").getAll() ?? [])
  }
  return animcharDisabledParams
}

let function reinitEquipment(eid, equipment) {
  let animcharDisabledParams = calcFaceGenDisableParams(equipment)
  let cur_human_equipment = ecs.obsolete_dbg_get_comp_val(eid, "human_equipment__slots")

  let filteredEquipment = {}
  foreach (slotId, slot in cur_human_equipment) {
    if (slot.item != null && slot.item != INVALID_ENTITY_ID) {
      let templateArray = ecs.g_entity_mgr.getEntityTemplateName(slot.item)?.split("+") ?? []
      let oldTemplateBase = templateArray?[0]
      if (oldTemplateBase && oldTemplateBase == equipment?[slotId].template)
        continue
      else
        ecs.g_entity_mgr.destroyEntity(slot.item)
    }
    filteredEquipment[slotId] <- equipment?[slotId]
  }

  foreach (slot, eq in filteredEquipment) {
    if (!eq || !eq.template)
      continue

    let comps = {
      ["slot_attach__attachedTo"] = [eid, ecs.TYPE_EID],
    }
    if (slot == "face")
      initFacegenParams(eq, animcharDisabledParams, comps)
    if(eq.template!="")
      cur_human_equipment[slot].item = ecs.g_entity_mgr.createEntity(eq.template, comps)
  }
  ecs.obsolete_dbg_set_comp_val(eid, "human_equipment__slots", cur_human_equipment)
}

let function setEquipment(eid, equipment) {
  let equipSlots = ecs.obsolete_dbg_get_comp_val(eid, "human_equipment__slots").getAll()
  let animcharDisabledParams = calcFaceGenDisableParams(equipment)
  foreach (slot, eq in equipment) {
    if (equipSlots[slot].item != null && equipSlots[slot].item != INVALID_ENTITY_ID)
      ecs.g_entity_mgr.destroyEntity(equipSlots[slot].item)

    if (!eq || !eq.template)
      continue

    let eqSlot = slot
    let function onCreateEquip(equipEid) {
      let sl = ecs.obsolete_dbg_get_comp_val(eid, "human_equipment__slots")
      if (sl?[eqSlot] != null) {
        sl[eqSlot].item = equipEid
        ecs.obsolete_dbg_set_comp_val(eid, "human_equipment__slots", sl)
      }
      else
        ecs.g_entity_mgr.destroyEntity(equipEid)
    }
    let comps = {
      ["slot_attach__attachedTo"] = [eid, ecs.TYPE_EID],
    }
    if (slot == "face")
      initFacegenParams(eq, animcharDisabledParams, comps)
    if(eq.template && eq.template!="")
      ecs.g_entity_mgr.createEntity(eq.template, comps, onCreateEquip)
  }
}

let function getWearInfos(soldierGuid, scheme) {
  let eInfos = []
  foreach (itemInfo in getSoldierItemSlots(soldierGuid, campItemsByLink.value)) {
    let { slotType, item } = itemInfo
    let { slotTemplates = {} } = item
    if (slotTemplates.len() <= 0 && (slotType in INVENTORY_SLOTS
        || (scheme?[slotType].ingameWeaponSlot ?? "") in WEAPON_SLOTS))
      continue

    let itemGuid = itemInfo.item.guid
    let info = objInfoByGuid.value?[itemGuid]
    if (info?.slot != null || slotTemplates.len() > 0)
      eInfos.append(info)
  }
  return eInfos
}

let function getItemAnimationBlacklist(soldier, soldierGuid, scheme, soldiersLook) {
  let itemTemplates = []
  let armyId = getLinkedArmyName(soldier ?? {})
  foreach(slotType, _ in scheme) {
    let item = getSoldierItem(soldierGuid, slotType, campItemsByLink.value)
    let { gametemplate = "" } = item
    if (gametemplate != "") {
      let itemTemplate = DB.getTemplateByName(gametemplate)
      if (itemTemplate != null)
        itemTemplates.append(itemTemplate)
    }
  }
  let eInfos = getWearInfos(soldierGuid, scheme)
  foreach (eInfo in eInfos) {
    let itemTemplate = DB.getTemplateByName(eInfo.gametemplate)
    if (itemTemplate != null)
      itemTemplates.append(itemTemplate)
  }
  let soldierLook = soldiersLook?[soldierGuid]
  if (soldierLook != null) {
    foreach (tmpl in soldierLook?.items ?? {}) {
      let eInfo = findItemTemplate(allItemTemplates, armyId, tmpl)
      if (eInfo != null && eInfo?.slot != null) {
        let itemTemplate = DB.getTemplateByName(eInfo.gametemplate)
        if (itemTemplate != null)
          itemTemplates.append(itemTemplate)
      }
    }
  }
  return itemTemplates
}

let function getWeapTemplates(soldierGuid, scheme) {
  let weapTemplates = {primary="", secondary="", tertiary=""}
  foreach(slotType, slot in scheme) {
    if (weapTemplates?[slot?.ingameWeaponSlot] != "")
      continue
    let weapon = getSoldierItem(soldierGuid, slotType, campItemsByLink.value)
    if ("gametemplate" not in weapon)
      continue

    local tpl = weapon.gametemplate
    if (slot.ingameWeaponSlot == "primary")
      tpl = "+".concat(tpl, "menu_gun")
    weapTemplates[slot.ingameWeaponSlot] = tpl
  }
  return weapTemplates
}

let function getTemplate(gametemplate) {
  let itemTemplate = DB.getTemplateByName(gametemplate)
  if (!itemTemplate)
    return null
  let recreateName = itemTemplate.getCompValNullable("item__recreateInEquipment") ?? "base_vis_item"
  return recreateName == "" ? gametemplate : $"{gametemplate}+{recreateName}"
}

let function appendEquipment(equipment, eInfo) {
  let { gametemplate, slot, slotTemplates = {} } = eInfo
  local res
  if (gametemplate == "")
    equipment[slot] <- null
  else {
    let template = getTemplate(gametemplate)
    if (!template)
      return logerr($"Appearance of main template {template} at slot {slot} not found")
    res = { gametemplate, template }
    equipment[slot] <- res
  }

  foreach (slotId, tmpl in slotTemplates) {
    if (tmpl == "")
      equipment[slotId] <- null
    else {
      let template = getTemplate(tmpl)
      if (!template)
        return logerr($"Appearance of multi template {tmpl} at {slotId} not found")
      equipment[slotId] <- { gametemplate = tmpl, template }
    }
  }
  return res
}

let function mkEquipment(soldier, soldierGuid, scheme, soldiersLook,
  premiumItems, customizationOvr = {}){
  if (DB.size() == 0)
    return {}

  local equipment = {}
  let soldiersDefaultLook = soldiersLook?[soldierGuid]
  if(soldiersDefaultLook == null)
    return equipment

  let armyId = getLinkedArmyName(soldier ?? {})
  let faceOverride = getSoldierFace(soldierGuid)
  local soldiersLookToShow = soldiersDefaultLook
  local soldiersDefaultItems = soldiersDefaultLook.items
  local premiumItemsToEquip = {}
  let premiumToOverride = premiumItems?[armyId]

  if(soldiersLookToShow != null && premiumToOverride != null)
    foreach(item in premiumToOverride){
      let slot = item?.links[soldierGuid]
      if(slot != null)
        premiumItemsToEquip.__update({ [slot] = item.basetpl })
    }

  let eInfos = getWearInfos(soldierGuid, scheme)
  foreach (eInfo in eInfos)
    if (eInfo?.slot != null){
      let data = appendEquipment(equipment, eInfo)
      if (!data)
        break
      if (eInfo.itemtype == "head")
        data.faceId <- faceOverride ?? getFirstLinkByType(eInfo, "faceId")
    }


  if(premiumItemsToEquip.len() > 0){
    soldiersDefaultItems = soldiersDefaultItems.__merge(premiumItemsToEquip)
    soldiersLookToShow = soldiersLookToShow.__merge({ items = soldiersDefaultItems })
  }

  if((customizationOvr ?? {}).len() > 0){
    soldiersDefaultItems = soldiersDefaultItems.__merge(customizationOvr)
    soldiersLookToShow = soldiersLookToShow.__merge({items = soldiersDefaultItems})
  }


  if (soldiersLookToShow != null) {
    foreach (tmpl in soldiersLookToShow?.items ?? {}) {
      let eInfo = findItemTemplate(allItemTemplates, armyId, tmpl)
      if (eInfo?.slot != null) {
        let data = appendEquipment(equipment, eInfo)
        if (!data)
          break
        if (eInfo.itemtype == "head")
          data.faceId <- faceOverride ?? soldiersLookToShow.faceId
      }
    }
  }


  foreach (eInfo in eInfos)
    if(eInfo?.itemtype not in IGNORE_SECOND_PASS && eInfo?.slot != null){
      let data = appendEquipment(equipment, eInfo)
      if (!data)
        break
      if (eInfo.itemtype == "head")
        data.faceId <- faceOverride ?? getFirstLinkByType(eInfo, "faceId")
    }


  foreach (eInfo in eInfos) {
    if (eInfo?.slotTemplates != null)
      foreach(slot, gametemplate in eInfo.slotTemplates){
        let itemsInfo = {
          slot
          gametemplate
          itemtemplate = gametemplate
        }
        appendEquipment(equipment, itemsInfo)
      }
  }

  equipment = equipment.filter(@(v) v != "" && v != null)

  if (equipment?.hair && (equipment?.head || equipment?.skined_helmet))
    equipment.hair <- null

  if ("backpack" not in equipment
      || (!hasLinkByType(soldier, "squad") && "parachute" in scheme))
    equipment.backpack <- null

  return equipment
}

let function createSoldier(
  guid, transform, soldiersLook, premiumItems = {}, callback = null, extraTemplates = [],
  isDisarmed = false, order = null, customizationOvr = {}, reInitEid = INVALID_ENTITY_ID
) {
  let soldier = objInfoByGuid.value?[guid]
  if (soldier == null)
    return INVALID_ENTITY_ID

  local scheme = soldier?.equipScheme ?? {}
  if (isSoldierDisarmed(guid) || isDisarmed)
    scheme = {}
  else if (isSoldierSlotsSwap(guid)) {
    let primaryKey = "primary" in scheme
      ? "primary"
      : scheme.findindex(@(val) val?.ingameWeaponSlot == "primary")
    let primary = scheme?[primaryKey]

    let secondaryKey = "secondary" in scheme
      ? "secondary"
      : scheme.findindex(@(val) val?.ingameWeaponSlot == "secondary")
    let secondary = scheme?[secondaryKey]

    if (primary && secondary)
      scheme = scheme.__merge({ [primaryKey] = secondary, [secondaryKey] = primary })
  }

  let soldierItems = getSoldierItemSlots(guid, campItemsByLink.value)
  let weapTemplates = getWeapTemplates(guid, scheme)
  let equipment = mkEquipment(curCampSoldiers.value?[guid], guid, scheme, soldiersLook,
    premiumItems, customizationOvr)

  let weapInfo = []
  weapInfo.resize(weaponSlots.EWS_NUM)

  let overrideHead = getSoldierHeadTemplate(guid)
  if (overrideHead) {
    let template = getTemplate(overrideHead)
    equipment.face <- (equipment?.face ?? {}).__update({
      gametemplate = overrideHead
      template
    })
  }

  for (local slotNo = 0; slotNo < weaponSlots.EWS_NUM; ++slotNo) {
    let weapon = {}
    weapInfo[slotNo] = weapon
    let slotName = weaponSlotNames[slotNo]
    let slots = getModSlots(
      objInfoByGuid.value?[soldierItems.findvalue(@(item) item.slotType == slotName)?.item.guid])
    foreach (slot in slots) {
      let slotTemplateId = objInfoByGuid.value?[slot.equipped].gametemplate
      let slotTemplate = slotTemplateId ? DB.getTemplateByName(slotTemplateId) : null
      if (!slotTemplate)
        continue
      if ("gunMods" not in weapon)
        weapon.gunMods <- {}
      weapon.gunMods[slot.slotType] <- slotTemplate.getCompVal("gunAttachable__slotTag")
    }
  }

  let soldierTemplate = DB.getTemplateByName(soldier.gametemplate)
  let overridedIdleAnims = soldierTemplate?.getCompValNullable("animation__overridedIdleAnims")
  let itemTemplates = getItemAnimationBlacklist(curCampSoldiers.value?[guid], guid, scheme, soldiersLook)
  let guid_hash = guid.hash()
  let animation = getSoldierIdle(guid) ?? getIdleAnimState({
    weapTemplates
    itemTemplates
    overridedIdleAnims
    seed = guid_hash
    order
  })
  let bodyHeight = soldier?.bodyScale.height ?? 1.0
  let bodyWidth = soldier?.bodyScale.width ?? 1.0
  let result_template = "+".join(["customizable_menu_animchar","human_weap"].extend(extraTemplates))

  let animcharRes = soldierTemplate?.getCompValNullable("animchar__res")
  let collRes = soldierTemplate?.getCompValNullable("collres__res")

  if (reInitEid != INVALID_ENTITY_ID) {
    local canBeRecreated = false
    initSoldierQuery.perform(reInitEid, function(_eid, comp){
      if (animcharRes != comp.animchar__res){
        ecs.g_entity_mgr.destroyEntity(reInitEid)
        return
      }
      canBeRecreated = true
      comp.guid = guid
      comp.guid_hash = guid_hash
      comp.human_weap__weapInfo = [weapInfo, ecs.TYPE_ARRAY]
      comp.animchar__scale = bodyHeight
      comp.animchar__depScale = Point3(bodyWidth, bodyHeight, bodyWidth)
      comp.animchar__transformScale = Point3(bodyWidth, 1.0, bodyWidth)
      comp.appearance__rndSeed = soldier?.appearanceSeed ?? 0
    })
    if (canBeRecreated){
      callback?(reInitEid)
      reinitEquipment(reInitEid, equipment)
      return reInitEid
    }
  }
  return ecs.g_entity_mgr.createEntity(result_template, {
      ["animchar__res"] = animcharRes,
      ["collres__res"] = collRes,
      ["transform"] = transform,
      ["guid"] = guid,
      ["guid_hash"] = guid_hash,
      ["animchar__animStateNames"] = [{ lower = animation, upper = animation }, ecs.TYPE_OBJECT],
      ["human_weap__weapTemplates"] = [weapTemplates, ecs.TYPE_OBJECT],
      ["human_weap__weapInfo"] = [weapInfo, ecs.TYPE_ARRAY],
      ["animchar__scale"] = bodyHeight,
      ["animchar__depScale"] = Point3(bodyWidth, bodyHeight, bodyWidth),
      ["animchar__transformScale"] = Point3(bodyWidth, 1.0, bodyWidth),
      ["appearance__rndSeed"] = soldier?.appearanceSeed ?? 0
    },
    function(newEid) {
      callback?(newEid)
      setEquipment(newEid, equipment)
    }
  )
}

return {
  soldierViewGen
  mkEquipment
  getWeapTemplates
  getItemAnimationBlacklist
  setEquipment
  createSoldier = kwarg(createSoldier)
  appearanceToRender
}