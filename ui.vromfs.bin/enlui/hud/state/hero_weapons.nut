import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *
let { anyItemComps, mkItemDescFromComp } = require("items.nut")
let {EWS_PRIMARY, EWS_GRENADE, EWS_NUM } = require("%enlSqGlob/weapon_slots.nut")
let { INVALID_ITEM_ID } = require("humaninv")
let { CmdTrackHeroWeapons } = require("gameevents")
let { grenadesEids } = require("inventory_grenades_es.nut")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")

const EES_EQUIPED = 0
const EES_HOLSTERING = 1
const EES_EQUIPING = 2
const EES_DOWN = 3

let weaponSlotsRaw = array(EWS_NUM).reduce(@(res, _, idx) res.rawset(idx, mkFrameIncrementObservable(null)), {})
let weaponSlots = weaponSlotsRaw.map(@(v) v.state)
let weaponSlotsStatic = array(EWS_NUM).reduce(@(res, _, idx) res.rawset(idx, null), {})
let { weaponSlotsGen, weaponSlotsGenSetValue } = mkFrameIncrementObservable(0, "weaponSlotsGen")
let { heroModsByWeaponSlotRaw, heroModsByWeaponSlotRawModify } = mkFrameIncrementObservable(array(EWS_NUM), "heroModsByWeaponSlotRaw")

let heroModsByWeaponSlot = Computed(function(){
  let res = array(EWS_NUM)
  foreach (slotNum, modsByEids in heroModsByWeaponSlotRaw.value) {
    let mods = {}
    let iconAttachments = []
    local modWeapon
    foreach (mod in (modsByEids ?? [])){
      let {iconName=null, isWeapon=false, attachedItemModSlotName=null} = mod
      if (attachedItemModSlotName==null)
        continue
      mods[attachedItemModSlotName] <- mod
      if (isWeapon) {
        iconAttachments.append({
          animchar = iconName
          slot = attachedItemModSlotName
          active = true
          scale = 2.0 // We want to emphasize attachments
        })
        modWeapon = mods[attachedItemModSlotName]
      }
    }
    if (mods.len()>0)
      res[slotNum] = {mods, iconAttachments, modWeapon}
  }
  return res
})


let isThrowMode = Watched(false)
ecs.register_es("hero_throw_mode_es",
  {
    [["onInit", ecs.EventComponentChanged]] = @(_, comp) isThrowMode(comp.human_weap__throwMode)
    onDestroy = @(...) isThrowMode(false)
  },
  {
    comps_rq = ["watchedByPlr"]
    comps_track = [["human_weap__throwMode", ecs.TYPE_BOOL]]
  }
)

let canStartMeleeCharge = Watched(false)
ecs.register_es("hero_can_start_melee_charge_es",
  {
    [["onInit", "onChange"]] = @(_, comp) canStartMeleeCharge(comp.human_melee_charge__canStart)
    onDestroy = @(...) canStartMeleeCharge(false)
  },
  {
    comps_rq = ["watchedByPlr"]
    comps_track = [["human_melee_charge__canStart", ecs.TYPE_BOOL]]
  }
)

let curGrenadeThrowerEid = Watched(ecs.INVALID_ENTITY_ID)
let curHeroWishedGrenade = Watched(INVALID_ITEM_ID)


let heroCurrentGunSlot = Watched(0)
ecs.register_es("hero_curgunslot_ui_es",
  {
    [["onInit", ecs.EventComponentChanged]] = @(_, __, comp) heroCurrentGunSlot(comp.human_weap__currentGunSlot)
    onDestroy = @(...) heroCurrentGunSlot(0)
  },
  {
    comps_rq = ["watchedByPlr"]
    comps_track = [
      ["human_weap__currentGunSlot", ecs.TYPE_INT],
    ]
  }
)

ecs.register_es("hero_ui_grenade_es",
  {
    [["onInit", "onChange"]] = function(_, eid, comp){
      if (comp["gun__wishAmmoItemType"] != INVALID_ITEM_ID) {
        curHeroWishedGrenade(comp["gun__wishAmmoItemType"])
        curGrenadeThrowerEid(eid)
      }
      else{
        curHeroWishedGrenade(INVALID_ITEM_ID)
        curGrenadeThrowerEid(ecs.INVALID_ENTITY_ID)
      }
    }
    function onDestroy(...){
      curHeroWishedGrenade(INVALID_ITEM_ID)
      curGrenadeThrowerEid(ecs.INVALID_ENTITY_ID)
    }
  },
  {
    comps_rq = ["grenade_thrower_gun", "watchedPlayerItem"]
    comps_track = [["gun__wishAmmoItemType", ecs.TYPE_INT, INVALID_ITEM_ID],]
  }
)
let memoizedDesc = memoize(@(_name, eid, comp) mkItemDescFromComp(eid, comp), 1)
ecs.register_es("hero_ui_weapons_es",
  {
    [["onInit", "onChange", CmdTrackHeroWeapons]] = function(_, eid, comp){
      let weaponMod = comp["weaponMod"] != null
      let idx = comp["slot_attach__weaponSlotIdx"]
      if (idx < 0 || idx >= EWS_NUM)
        return
      if (weaponMod) {
        let modCurAmmo = comp["gun__ammo"]
        let modTotalAmmo = comp["gun__totalAmmo"]
        let modsDesc = memoizedDesc(comp["item__name"], eid, comp)
        heroModsByWeaponSlotRawModify(function(v) {
          if (v[idx] == null)
            v[idx] = {}
          v[idx][eid] <- {
            modCurAmmo
            modTotalAmmo
            isWeapon = (modTotalAmmo + modCurAmmo) > 0
          }.__update(modsDesc)
          return v
        })
        return
      }
      let staticDesc = memoizedDesc(comp["item__name"], eid, comp)
      let desc = {
        isReloading = comp["gun_anim__reloadProgress"] > 0.0
        additionalAmmo = comp?["gun__additionalAmmo"] ?? 0
        eid
        subsidiaryGunEid = comp["subsidiaryGunEid"]
        firingMode = comp["gun__firingModeName"]
        curAmmo = comp["gun__ammo"]
        totalAmmo = comp["gun__totalAmmo"]
        curAmmoHolderIndex = comp["gun__curAmmoHolderIndex"]
        ammoByHolders = comp["gun__ammoByHolders"]?.getAll() ?? []
        iconByHolders = comp["gun__iconByHolders"]?.getAll() ?? []
      }
      weaponSlotsStatic[idx] <- staticDesc
      weaponSlotsRaw[idx].setValue(desc)
      weaponSlotsGenSetValue(weaponSlotsGen.value+1)
    }
    onDestroy = function(eid, comp) {
      let idx = comp["slot_attach__weaponSlotIdx"]
      if (idx < 0 || idx > EWS_NUM)
        return
      let weaponMod = comp["weaponMod"] != null
      if (weaponMod) {
        heroModsByWeaponSlotRawModify(function(v) {
            if (eid not in v?[idx])
              return v
            delete v[idx][eid]
            return v
          })
        return
      }
      weaponSlotsStatic[idx] <- null
      weaponSlotsRaw[idx].setValue(null)
      weaponSlotsGenSetValue(weaponSlotsGen.value + 1)
    }
  },
  {
    comps_rq = anyItemComps.comps_rq,
    comps_no = ["binocular", "flask", "grenade_thrower"]
    comps_ro = [
      ["weaponMod", ecs.TYPE_TAG, null],
      ["slot_attach__weaponSlotIdx", ecs.TYPE_INT, null],
    ].extend(anyItemComps.comps_ro)
    comps_track = [
      ["slot_attach__weaponSlotIdx", ecs.TYPE_INT],
      ["gun_anim__reloadProgress", ecs.TYPE_FLOAT, 0.0],
      ["gun__ammo", ecs.TYPE_INT, 0],
      ["gun__additionalAmmo", ecs.TYPE_INT, null],
      ["gun__firingModeName", ecs.TYPE_STRING, ""],
      ["subsidiaryGunEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
      ["gun__totalAmmo", ecs.TYPE_INT, 0],
      ["gun__curAmmoHolderIndex", ecs.TYPE_INT, 0],
      ["gun__ammoByHolders", ecs.TYPE_INT_LIST, null],
      ["gun__iconByHolders", ecs.TYPE_STRING_LIST, null],
    ]
  }
)

ecs.register_es("hero_state_subsidiary_gun_ui_es",
  { [[ecs.EventComponentsAppear, ecs.EventComponentsDisappear]] = @(_, eid, __) ecs.g_entity_mgr.sendEvent(eid, CmdTrackHeroWeapons()), },
  {
    comps_rq = ["gun", "watchedPlayerItem"]
    comps_ro = [ ["subsidiaryGunEid", ecs.TYPE_EID] ]
  }
)

let fastThrowExclusive = Watched(false)
ecs.register_es("hero_state_fast_throw_mode_es",
  {
    [["onInit", "onChange"]] = @(_eid, comp) fastThrowExclusive(comp["human_weap__fastThrowExclusive"])
  },
  {
    comps_rq = ["watchedByPlr"]
    comps_track = [["human_weap__fastThrowExclusive", ecs.TYPE_BOOL]]
  }
)

let currentGunEid = Watched(ecs.INVALID_ENTITY_ID)

ecs.register_es("watched_player_current_gun_eid_track", {
  [["onInit","onChange"]] = function(_eid,comp) {
    currentGunEid(comp.human_weap__currentGunEid)
  }
},
{ comps_track=[["human_weap__currentGunEid", ecs.TYPE_EID]] comps_rq = ["watchedByPlr"] })


let curWeapon = Computed(function() {
  weaponSlotsGen.value  //warning disable: -result-not-utilized
  return weaponSlots?[heroCurrentGunSlot.value].value
})

let curWeaponStaticInfo = Computed(function() {
  weaponSlotsGen.value  //warning disable: -result-not-utilized
  return weaponSlotsStatic?[heroCurrentGunSlot.value]
})

let needReload = Computed(function(){
  let cw = curWeapon.value
  if (cw==null)
    return false
  let {maxAmmo=0, curAmmo, isReloading, totalAmmo} = cw
  let maxLoadedAmmo = max(maxAmmo, 1)
  let fullness = curAmmo.tofloat()/maxLoadedAmmo
  return (fullness < 0.1 || (maxLoadedAmmo > 1 && curAmmo==1)) && totalAmmo > curAmmo && !isReloading
})


let curWeaponIsReloadable = Computed(@() curWeaponStaticInfo.value?.isReloadable ?? ((curWeaponStaticInfo.value?.maxAmmo ?? 0) > 0))
let curWeaponFiringMode = Computed(@() curWeapon.value?.firingMode ?? "")
let showWeaponBlock = Computed(@() curWeaponStaticInfo.value != null)
let curWeaponIsDualMag = Computed(@() curWeaponStaticInfo.value?.isDualMagGun ?? false)

let curWeaponAdditionalAmmo = Computed(@() curWeapon.value?.additionalAmmo ?? 0)
let curGunMod = Computed(@() heroModsByWeaponSlot.value?[heroCurrentGunSlot.value].modWeapon)
let isModActive = Computed(@() curGunMod.value?.eid != null && curGunMod.value.eid == curWeapon.value?.subsidiaryGunEid)
let curWeaponHasAltShot = Computed(@() curGunMod.value!=null)
let curWeaponAmmo = Computed(@() (isModActive.value ? curGunMod.value?.modCurAmmo : curWeapon.value?.curAmmo) ?? 0)
let curWeaponAltAmmo = Computed(@() (isModActive.value ? curWeapon.value?.curAmmo : curGunMod.value?.modCurAmmo) ?? 0)
let curWeaponTotalAmmo = Computed(@() (isModActive.value ? curGunMod.value?.modTotalAmmo : curWeapon.value?.totalAmmo) ?? 0)
let curWeaponAltTotalAmmo = Computed(@() (isModActive.value ? curWeapon.value?.totalAmmo : curGunMod.value?.modTotalAmmo) ?? 0)
let curWeaponWeapType = Computed(@() curWeaponStaticInfo.value?.weapType)
let curWeaponChargeTime = Computed(@() curWeaponStaticInfo.value?.chargeTime ?? 0)
let curWeaponIsGrenade = Computed(@() EWS_GRENADE==heroCurrentGunSlot.value)
let curWeaponCurAmmoHolderIndex = Computed(@() curWeapon.value?.curAmmoHolderIndex ?? 0)
let curWeaponAmmoByHolders = Computed(@() curWeapon.value?.ammoByHolders ?? [])
let curWeaponIconByHolders = Computed(@() curWeapon.value?.iconByHolders ?? [])
let hasPrimaryWeapon = Computed(function() {
  weaponSlotsGen.value  //warning disable: -result-not-utilized
  return weaponSlots?[EWS_PRIMARY].value != null
})
let curWeaponHasScope = Computed(@() heroModsByWeaponSlot.value?[heroCurrentGunSlot.value].mods.scope!=null)
let curHeroGrenadeEid = Computed(function() {
  weaponSlotsGen.value  //warning disable: -result-not-utilized
  return weaponSlots?[EWS_GRENADE].value.eid
})

return {
  currentGunEid
  needReload
  fastThrowExclusive
  heroCurrentGunSlot
  heroModsByWeaponSlot
  weaponSlotsStatic
  weaponSlots
  curHeroGrenadeEid

  hasAnyGrenade = Computed(@() grenadesEids.value.len()>0)

  hasWeapon = Computed(@() curWeapon.value != null)
  curWeaponWeapType
  curWeaponAmmo
  curWeaponTotalAmmo
  curWeaponIsDualMag
  curWeaponAdditionalAmmo
  curWeaponAltAmmo
  curWeaponAltTotalAmmo
  curWeaponIsModActive = isModActive
  curWeaponIsReloadable
  curWeaponFiringMode
  curWeaponHasAltShot
  showWeaponBlock
  curWeaponChargeTime
  curWeaponIsGrenade
  curWeaponCurAmmoHolderIndex
  curWeaponAmmoByHolders
  curWeaponIconByHolders
  hasPrimaryWeapon
  curWeaponHasScope
  canStartMeleeCharge
  EWS_NUM
  isThrowMode
}

