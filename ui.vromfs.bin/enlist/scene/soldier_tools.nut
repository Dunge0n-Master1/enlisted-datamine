import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { Point3 } = require("dagor.math")
let { curCampSoldiers, objInfoByGuid, getSoldierItem, getSoldierItemSlots,
  getModSlots, curSquadSoldiersInfo
} = require("%enlist/soldiers/model/state.nut")
let { getIdleAnimState } = require("%enlSqGlob/animation_utils.nut")
let weaponSlots = require("%enlSqGlob/weapon_slots.nut")
let weaponSlotNames = require("%enlSqGlob/weapon_slot_names.nut")
let curGenFaces = require("%enlist/faceGen/gen_faces.nut")
let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let { allItemTemplates, findItemTemplate
} = require("%enlist/soldiers/model/all_items_templates.nut")
let { campItemsByLink } = require("%enlist/meta/profile.nut")
let { soldierOverrides, isSoldierDisarmed, isSoldierSlotsSwap, getSoldierIdle,
  getSoldierHeadTemplate, getSoldierFace, faceGenOverrides, getSoldierFaceGen
} = require("soldier_overrides.nut")

let DB = ecs.g_entity_mgr.getTemplateDB()

let WEAP_SLOT_TYPES = { primary = true, secondary = true, side = true, tertiary = true,
  melee = true, grenade = true }

let INVENTORY_SLOT_TYPES = { inventory = true, grenade = true, mine = true, flask_usable = true,
  binoculars_usable = true, inventory_hidden = true }

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
    if (slot.item != null && slot.item != ecs.INVALID_ENTITY_ID) {
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
    if (eq.template!="")
      cur_human_equipment[slot].item = ecs.g_entity_mgr.createEntity(eq.template, comps)
  }
  ecs.obsolete_dbg_set_comp_val(eid, "human_equipment__slots", cur_human_equipment)
}

let function setEquipment(eid, equipment) {
  let sl = ecs.obsolete_dbg_get_comp_val(eid, "human_equipment__slots")
  let equipSlots = sl.getAll()
  let animcharDisabledParams = calcFaceGenDisableParams(equipment)
  local updateEquipmentSlots = false
  foreach (slot, eq in equipment) {
    if (equipSlots[slot].item != null && equipSlots[slot].item != ecs.INVALID_ENTITY_ID)
      ecs.g_entity_mgr.destroyEntity(equipSlots[slot].item)

    if (!eq || !eq.template)
      continue

    let comps = {
      ["slot_attach__attachedTo"] = [eid, ecs.TYPE_EID],
    }
    if (eq.template && eq.template!="") {
      if (sl?[slot] != null) {
        if (slot == "face")
          initFacegenParams(eq, animcharDisabledParams, comps)
        sl[slot].item = ecs.g_entity_mgr.createEntity(eq.template, comps)
        updateEquipmentSlots = true
      }
    }
  }
  if (updateEquipmentSlots)
    ecs.obsolete_dbg_set_comp_val(eid, "human_equipment__slots", sl)
}

let isWeaponSlot = @(slotType, scheme) slotType in INVENTORY_SLOT_TYPES
  || (scheme?[slotType].ingameWeaponSlot ?? "") in WEAP_SLOT_TYPES

let function getWearInfos(soldierGuid, scheme) {
  let eInfos = []
  let itemSlots = getSoldierItemSlots(soldierGuid, campItemsByLink.value)
  foreach (itemInfo in itemSlots) {
    let { slotType, item } = itemInfo
    let { slotTemplates = {} } = item
    if (slotTemplates.len() <= 0 && isWeaponSlot(slotType, scheme))
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
  foreach (slotType, _ in scheme) {
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
  let weapTemplates = {primary="", secondary="", tertiary="", special=""}
  foreach (slotType, slot in scheme) {
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

let function mkEquipment(soldier, scheme, soldiersLook, premiumItems,
    customizationOvr = {}) {
  if (DB.size() == 0)
    return {}

  let { guid } = soldier
  let armyId = getLinkedArmyName(soldier ?? {})
  let faceOverride = getSoldierFace(guid)

  // basic soldier look
  local slotTmpls = {}
  let soldiersDefaultLook = soldiersLook?[guid] ?? {}
  foreach (slotType, templ in soldiersDefaultLook.items) {
    let itemTemplate = findItemTemplate(allItemTemplates, armyId, templ)
    if (itemTemplate != null)
      slotTmpls[slotType] <- itemTemplate
  }

  // apply items except inventory and weapon
  let itemSlots = getSoldierItemSlots(guid, campItemsByLink.value)
  foreach (itemSlot in itemSlots) {
    let { slotType } = itemSlot
    if (slotType in INVENTORY_SLOT_TYPES)
      continue
    let slot = scheme?[slotType]
    if (slot == null || (slot?.ingameWeaponSlot in WEAP_SLOT_TYPES))
      continue
    let itemTemplate = findItemTemplate(allItemTemplates, armyId, itemSlot.item.basetpl)
    if (itemTemplate != null)
      slotTmpls[slotType] <- itemTemplate
  }

  // premium outfit
  foreach (item in premiumItems?[armyId] ?? []) {
    let slotType = item?.links[guid]
    if (slotType == null)
      continue
    let itemTemplate = findItemTemplate(allItemTemplates, armyId, item.basetpl)
    if (itemTemplate != null)
      slotTmpls[slotType] <- itemTemplate
  }
  foreach (slotType, templ in customizationOvr) {
    let itemTemplate = findItemTemplate(allItemTemplates, armyId, templ)
    if (itemTemplate != null)
      slotTmpls[slotType] <- itemTemplate
  }

  // apply templates to soldier outfit
  local equipment = {}
  foreach (slotType, itemTemplate in slotTmpls) {
    let itemSlot = itemTemplate?.slot ?? slotType
    let { gametemplate } = itemTemplate
    let template = getTemplate(gametemplate)
    let data = { gametemplate, template }
    if (slotType == "head")
      data.faceId <- faceOverride ?? soldiersDefaultLook.faceId
    equipment[itemSlot] <- data
  }
  foreach (itemTemplate in slotTmpls)
    foreach (slotType, gametemplate in itemTemplate?.slotTemplates ?? {}) {
      let template = getTemplate(gametemplate)
      equipment[slotType] <- { gametemplate, template }
    }

  // aditional weapon overrides
  foreach (itemSlot in itemSlots) {
    let { slotType } = itemSlot
    if (slotType in INVENTORY_SLOT_TYPES)
      continue
    let slot = scheme?[slotType]
    if (slotType not in WEAP_SLOT_TYPES && (slot?.ingameWeaponSlot not in WEAP_SLOT_TYPES))
      continue
    let itemTemplate = findItemTemplate(allItemTemplates, armyId, itemSlot.item.basetpl)
    foreach (slotId, gametemplate in itemTemplate?.slotTemplates ?? {}) {
      let template = getTemplate(gametemplate)
      equipment[slotId] <- { gametemplate, template }
    }
  }

  if ((equipment?.head ?? "") != "" || (equipment?.skined_helmet ?? "") != "")
    equipment.hair <- null
  equipment = equipment.filter(@(v) v != "" && v != null)
  return equipment
}

let function createSoldier(
  guid, transform, soldiersLook, premiumItems = {}, callback = null, extraTemplates = [],
  isDisarmed = false, order = null, customizationOvr = {}, reInitEid = ecs.INVALID_ENTITY_ID
) {
  let soldier = objInfoByGuid.value?[guid]
  if (soldier == null)
    return ecs.INVALID_ENTITY_ID

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
  let equipment = mkEquipment(curCampSoldiers.value?[guid], scheme, soldiersLook,
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

  let { gametemplate = null } = soldier
  if (gametemplate == null)
    return ecs.INVALID_ENTITY_ID

  let soldierTemplate = DB.getTemplateByName(gametemplate)
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

  if (reInitEid != ecs.INVALID_ENTITY_ID) {
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