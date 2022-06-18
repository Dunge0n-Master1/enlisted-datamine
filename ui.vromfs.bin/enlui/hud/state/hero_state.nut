import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

//!!Attention! do not anything here! it is too broad and should be splitted into separate files


let {CmdTrackHeroWeapons} = require("gameevents")
let {tostring_r} = require("%sqstd/string.nut")
let {Point2} = require("dagor.math")

const EES_EQUIPED = 0
const EES_HOLSTERING = 1
const EES_EQUIPING = 2
const EES_DOWN = 3

let weaponSlots = require("%enlSqGlob/weapon_slots.nut")
let weaponSlotNames = require("%enlSqGlob/weapon_slot_names.nut")
let {watchedHeroEid} = require("%ui/hud/state/watched_hero.nut")
let { INVALID_ITEM_ID } = require("humaninv")

let weaponsList = Watched([])  //should be array of tables  [{ weaponName = "mp-40" curAmmo = 10 totalAmmo = 100 maxLoadedAmmo=20 }]

let heroState = {
  //Attention! do not anything here! it is too broad and should be splitted into separate files
  curWeapon = Watched(null)
  needReload = Watched(false)
  weaponsList
  fastThrowExclusive = Watched(false)
}

let updateWeaponsList = @(list) weaponsList(list)

weaponsList.whiteListMutatorClosure(updateWeaponsList)

console_register_command(function() {
                            if (weaponsList.value != null) {
                              foreach (w in weaponsList.value) {
                                vlog(tostring_r(w))
                              }
                            }
                          },
                          "hud.logWeaponList"
                        )
console_register_command(@() heroState.curWeapon.update({name="Knife" curAmmo=0 totalAmmo = 0 maxAmmo=0 isCurrent=true isReloadable=false}),"hud.setKnife")
console_register_command(@(ammo=10, totalAmmo=200) heroState.curWeapon.update({name="MP-40" curAmmo=ammo totalAmmo=totalAmmo maxAmmo=32 isCurrent=true}),"hud.setGun")
console_register_command(function(ammo=3) {
                          updateWeaponsList(
                            [
                              {name="machineGun" curAmmo=10 totalAmmo = ammo maxAmmo=32 },
                              {name="muskete" curAmmo=1 totalAmmo=ammo maxAmmo=1 },
                              {name="knife" maxAmmo=0 isReloadable=false totalAmmo=ammo},
                            ]
                          )},"hud.mockWeaponsList")




let function onHeroWeapons(list) {
  updateWeaponsList(list)
  if (type(list) != "array" || list.len() == 0)
    return
  let weapon = list.findvalue(@(w) w.isCurrent)
  if (weapon == null)
    return

  heroState.curWeapon(weapon)
  let curAmmo = weapon.curAmmo
  let maxLoadedAmmo = max(weapon.maxAmmo, 1)
  let fullness = curAmmo.tofloat()/maxLoadedAmmo
  heroState.needReload((fullness < 0.1 || (maxLoadedAmmo > 1 && curAmmo==1))
    && weapon.totalAmmo > curAmmo && !weapon.isReloading)
}



let itemIconQuery = ecs.SqQuery("itemIconQuery", {
  comps_ro = [
    ["animchar__res", ecs.TYPE_STRING, ""],
    ["item__iconYaw", ecs.TYPE_FLOAT, 0.0],
    ["item__iconPitch", ecs.TYPE_FLOAT, 0.0],
    ["item__iconRoll", ecs.TYPE_FLOAT, 0.0],
    ["item__iconOffset", ecs.TYPE_POINT2, Point2(0.0, 0.0)],
    ["item__iconScale", ecs.TYPE_FLOAT, 1.0],
  ]
})

let function setIconParams(itemEid, dst) {
  itemIconQuery.perform(itemEid, function (_eid, comp) {
    dst.__update({
      iconName = comp["animchar__res"]
      iconYaw = comp["item__iconYaw"]
      iconPitch = comp["item__iconPitch"]
      iconRoll = comp["item__iconRoll"]
      iconOffsX = comp["item__iconOffset"].x
      iconOffsY = comp["item__iconOffset"].y
      iconScale = comp["item__iconScale"]
    })
  })
}

let function setIconParamsByTemplate(itemEid, dst) {
  if (itemEid == INVALID_ENTITY_ID)
    return
  let itemTempl = ecs.obsolete_dbg_get_comp_val(itemEid, "item__template") ?? ecs.obsolete_dbg_get_comp_val(itemEid, "ammo_holder__templateName")
  if (itemTempl == null)
    return
  let templ = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(itemTempl)
  if (templ == null)
    return
  let iconOffset = templ.getCompValNullable("item__iconOffset") ?? Point2(0.0, 0.0)
  dst.__update({
    iconName = templ.getCompValNullable("animchar__res") ?? ""
    iconYaw = templ.getCompValNullable("item__iconYaw") ?? 0.0
    iconPitch = templ.getCompValNullable("item__iconPitch") ?? 0.0
    iconRoll = templ.getCompValNullable("item__iconRoll") ?? 0.0
    iconOffsX = iconOffset.x
    iconOffsY = iconOffset.y
    iconScale = templ.getCompValNullable("item__iconScale") ?? 1.0
  })
}

let gunQuery = ecs.SqQuery("gunQuery", {
  comps_ro = [
    ["gun__propsId", ecs.TYPE_INT, -1],
    ["gun__maxAmmo", ecs.TYPE_INT, 0],
    ["gun__ammo", ecs.TYPE_INT, 0],
    ["gun__totalAmmo", ecs.TYPE_INT, 0],
    ["gun__additionalAmmo", ecs.TYPE_INT, null],
    ["gun__disableAmmoUnload", ecs.TYPE_TAG, null],
    ["gun__wishAmmoItemType", ecs.TYPE_INT, INVALID_ITEM_ID],
    ["gun__ammoHolderEid", ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["gun__ammoHolderIds", ecs.TYPE_INT_LIST, null],
    ["gun__firingModeName", ecs.TYPE_STRING, ""],
    ["gun__reloadable", ecs.TYPE_BOOL, false],
    ["gun_mods__slots", ecs.TYPE_OBJECT, null],
    ["gun_anim__reloadProgress", ecs.TYPE_FLOAT, -1.0],
    ["gun_delayed_shot__holdTriggerDelay", ecs.TYPE_FLOAT, 0.0],
    ["item__name", ecs.TYPE_STRING, ""],
    ["item__weapSlots", ecs.TYPE_ARRAY, null],
    ["item__id", ecs.TYPE_INT, INVALID_ITEM_ID],
    ["item__weapType", ecs.TYPE_STRING, null],
    ["subsidiaryGunEid", ecs.TYPE_EID, INVALID_ENTITY_ID]
  ]
})
let weapon_proto = {
  isReloadable = false
  isCurrent = false
  isHolstering = false
  isEquiping = false
  isWeapon = false
  name = ""
  totalAmmo = 0
  curAmmo = 0
  maxAmmo = 0
}

let modQuery = ecs.SqQuery("modQuery", {
  comps_ro = [
    ["item__id", ecs.TYPE_INT, 0],
    ["item__name", ecs.TYPE_STRING, ""],
    ["gunAttachable__gunSlotName", ecs.TYPE_STRING, ""],
    ["gunAttachable__slotTag", ecs.TYPE_STRING, ""],
    ["weapon_mod__active", ecs.TYPE_BOOL, false],
    ["gun__totalAmmo", ecs.TYPE_INT, 0],
    ["gun__ammo", ecs.TYPE_INT, 0],
    ["gun", null, null]
  ]
})

let mod_proto = {
  itemPropsId = INVALID_ITEM_ID
  attachedItemName = ""
  attachedItemModSlotName = ""
  attachedItemModTag = ""
  isActivated = false
  isWeapon = false
}

let function trackHeroWeapons(_eid, comp) {
  let isChanging = comp["human_net_phys__weapEquipCurState"] == EES_HOLSTERING ||
                     comp["human_net_phys__weapEquipCurState"] == EES_EQUIPING

  let weaponDescs = []
  weaponDescs.resize(weaponSlots.EWS_NUM, null)
  for (local i = 0; i < weaponSlots.EWS_NUM; ++i) {
    local validWeaponSlots = null
    local itemId = null
    local gunMods = null
    let mainGunEid = comp["human_weap__gunEids"][i]
    local currentGunEid = INVALID_ENTITY_ID
    local gunCurAmmo = 0
    local gunTotalAmmo = 0
    gunQuery.perform(mainGunEid, function (_eid, gunComp) {
      validWeaponSlots = gunComp["item__weapSlots"]?.getAll() ?? []
      itemId = gunComp["item__id"]
      gunMods = gunComp["gun_mods__slots"]
      currentGunEid = gunComp["subsidiaryGunEid"]
      gunCurAmmo = gunComp["gun__ammo"]
      gunTotalAmmo = gunComp["gun__totalAmmo"]
    });
    currentGunEid = (currentGunEid == INVALID_ENTITY_ID) ? mainGunEid : currentGunEid
    let desc = gunQuery.perform(currentGunEid, function (_eid, gunComp) {
      let isCurrentSlot = i == comp["human_weap__currentGunSlot"]
      let isReloadable = gunComp["gun__propsId"] >= 0 && i != weaponSlots.EWS_GRENADE ? gunComp["gun__reloadable"] : false
      let weaponDesc = {
        totalAmmo = gunComp["gun__totalAmmo"]
        isDualMagGun = gunComp?["gun__additionalAmmo"] != null
        additionalAmmo = gunComp?["gun__additionalAmmo"] ?? 0
        name = gunComp["item__name"]
        curAmmo = gunComp["gun__ammo"]
        maxAmmo = gunComp["gun__maxAmmo"]
        itemPropsId = itemId
        firingMode = gunComp["gun__firingModeName"]
        isReloadable = isReloadable
        isUnloadable = gunComp["gun__disableAmmoUnload"] == null
        isReloading = gunComp["gun_anim__reloadProgress"] > 0.0
        isCurrent = isCurrentSlot
        isHolstering = isChanging && isCurrentSlot
        isEquiping = isChanging && comp["human_net_phys__weapEquipNextSlot"] == i
        isWeapon = validWeaponSlots.len() > 0
        hasAltShot = false
        validWeaponSlots = validWeaponSlots
        grenadeType = null
        weapType = gunComp["item__weapType"]
        mods = {}
        ammoHolders = []
        chargeTime = gunComp?["gun_delayed_shot__holdTriggerDelay"] ?? 0
      }

      if (isReloadable) {
        weaponDesc.ammo <- {
          itemPropsId = ecs.obsolete_dbg_get_comp_val(gunComp["gun__ammoHolderEid"], "ammo_holder__id") ?? 0
          name = ecs.obsolete_dbg_get_comp_val(gunComp["gun__ammoHolderEid"], "item__name") ?? ""
        }
        setIconParamsByTemplate(gunComp["gun__ammoHolderEid"], weaponDesc.ammo)
        weaponDesc.ammoHolders = gunComp["gun__ammoHolderIds"]?.getAll() ?? []
      }

      if (gunComp["gun__wishAmmoItemType"] != INVALID_ITEM_ID && i == weaponSlots.EWS_GRENADE) {
        local grenEid = INVALID_ENTITY_ID;
        foreach (itemEid in comp["itemContainer"]) {
          let itemPropsId = ecs.obsolete_dbg_get_comp_val(itemEid, "item__id", INVALID_ITEM_ID)
          if (itemPropsId == gunComp["gun__wishAmmoItemType"]) {
            grenEid = itemEid
            break
          }
        }
        weaponDesc.name = ecs.obsolete_dbg_get_comp_val(grenEid, "item__name", "")
        weaponDesc.grenadeType = ecs.obsolete_dbg_get_comp_val(grenEid, "item__grenadeType", null)
        weaponDesc.itemPropsId = gunComp["gun__wishAmmoItemType"]

        setIconParams(grenEid, weaponDesc)
      }
      else
        setIconParams(mainGunEid, weaponDesc)

      if (gunMods != null) {
        let iconAttachments = []
        let modEids = comp["human_weap__gunMods"][i].getAll()
        foreach (slot, _slotTag in comp["human_weap__gunModsBySlot"][i]) {
          local modEid = INVALID_ENTITY_ID
          foreach (tmpEid in modEids) {
            let slotName = ecs.obsolete_dbg_get_comp_val(tmpEid, "gunAttachable__gunSlotName")
            if ((slotName != null) && (slotName == slot)) {
              modEid = tmpEid
              break
            }
          }
          let modProps = mod_proto.__merge({
            array_tags = gunMods?[slot].getAll().keys() ?? []
            isActivated = currentGunEid != mainGunEid
          })
          local modCurAmmo = 0
          local modTotalAmmo = 0
          modQuery.perform(modEid, function (_eid, modComp) {
            modProps.__update({
              itemPropsId = modComp["item__id"]
              attachedItemName = modComp["item__name"] ?? ""
              attachedItemModSlotName = modComp["gunAttachable__gunSlotName"] ?? ""
              attachedItemModTag = modComp["gunAttachable__slotTag"] ?? ""
              isWeapon = modComp["gun"] != null
            })
            modCurAmmo = modComp["gun__ammo"]
            modTotalAmmo = modComp["gun__totalAmmo"]
          })
          weaponDesc.mods[slot] <- modProps
          setIconParamsByTemplate(modEid, weaponDesc.mods[slot])
          let mod = weaponDesc.mods[slot]
          if (mod.isWeapon) {
            iconAttachments.append({
              animchar = mod.iconName
              slot = mod.attachedItemModSlotName
              active = mod.isActivated
              scale = 2.0 /* We want to emphasize attachments */
            })
            weaponDesc.hasAltShot = true
            weaponDesc.__update({
              isModActive = modProps.isActivated
              altCurAmmo = modProps.isActivated ? gunCurAmmo : modCurAmmo
              altTotalAmmo = modProps.isActivated ? gunTotalAmmo : modTotalAmmo
            })
          }
        }
        if (iconAttachments.len() > 0)
          weaponDesc.__update({
            iconAttachments = iconAttachments
          })
      }
      return weaponDesc
    })
    weaponDescs[i] = (desc == null) ? clone weapon_proto : desc
    weaponDescs[i].currentWeaponSlotName <- weaponSlotNames[i]
  }
  onHeroWeapons(weaponDescs)
}

ecs.register_es("hero_state_weapons_ui_es",
  {
    [["onInit", ecs.EventComponentChanged,"onDestroy", CmdTrackHeroWeapons]] = trackHeroWeapons,
  },
  {
    comps_rq = ["watchedByPlr"]
    comps_track = [
      ["human_weap__gunModsBySlot", ecs.TYPE_ARRAY],
      ["human_weap__gunEids", ecs.TYPE_EID_LIST],
      ["human_weap__gunMods", ecs.TYPE_ARRAY],
      ["human_weap__currentGunSlot", ecs.TYPE_INT],
      ["human_net_phys__weapEquipCurState", ecs.TYPE_INT],
      ["human_net_phys__weapEquipNextSlot", ecs.TYPE_INT],
      ["itemContainer", ecs.TYPE_EID_LIST],
    ]
  }
)

//these are awful workarounds for incorrect weapons update above.
//We should listen ONLY to weapon entities instead of all code that listens to hero above here
ecs.register_es("hero_state_mod_ui_es",
  {
    onInit = @() ecs.g_entity_mgr.sendEvent(watchedHeroEid.value, CmdTrackHeroWeapons())
  },
  {
    comps_rq = ["weaponMod"]
  }
)
ecs.register_es("hero_state_fast_throw_mode_es",
  {
    [["onInit", "onChange"]] = @(_eid, comp) heroState.fastThrowExclusive(comp["human_weap__fastThrowExclusive"])
  },
  {
    comps_rq = ["watchedByPlr"]
    comps_track = [["human_weap__fastThrowExclusive", ecs.TYPE_BOOL]]
  }
)
let function trackWeapon(_eid, comp) {
  let hero = watchedHeroEid.value
  if (comp["gun__owner"] == hero)
    ecs.g_entity_mgr.sendEvent(hero, CmdTrackHeroWeapons())
}

ecs.register_es("hero_state_melee_workaround_ui_es",
  {
    onInit = trackWeapon
  },
  {
    comps_ro = [["gun__owner", ecs.TYPE_EID]]
    comps_rq = [["gun__melee", ecs.TYPE_BOOL]]
  }
)

ecs.register_es("hero_state_gun_workaround_ui_es",
  {
    [["onInit", "onChange","onDestroy"]] = trackWeapon,
  },
  {
    comps_rq = ["gun"]
    comps_no = ["isTurret"]
    comps_track = [
      ["gun__owner", ecs.TYPE_EID],
      ["gun__firingModeIndex", ecs.TYPE_INT],
      ["gun__ammo", ecs.TYPE_INT],
      ["gun__totalAmmo", ecs.TYPE_INT],
      ["gun__wishAmmoItemType", ecs.TYPE_INT],
      ["gun__ammoHolderEid", ecs.TYPE_EID]
    ]
  }
)

ecs.register_es("hero_state_subsidiary_gun_ui_es",
  {
    [[ecs.EventComponentsAppear, ecs.EventComponentsDisappear, "onChange"]] = trackWeapon,
  },
  {
    comps_rq = ["gun"]
    comps_ro = [["gun__owner", ecs.TYPE_EID]]
    comps_track = [
      ["subsidiaryGunEid", ecs.TYPE_EID]
    ]
})

return heroState
