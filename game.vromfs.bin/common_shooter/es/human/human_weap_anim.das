require ecs
require app
require PhysVars
require HumanPhys
require Gun
require DagorMath
require DagorSystem
require EnlistedActor
require EnlistedHuman
require EnlistedWeapon
require common_shooter.es.gun_anim_common
require enlisted.events_enlisted


[es(on_appear, before=anim_phys_init_es)]
def human_weap_anim_init(evt : Event;
                         var human_weap_anim__boltActionVarId : int&;
                         var human_weap_anim__reloadVarId : int&;
                         var human_weap_anim__throwProgressVarId : int&;
                         var phys_vars : PhysVars)
  human_weap_anim__boltActionVarId = registerVar(phys_vars, "bolt_action", 0.0)
  human_weap_anim__reloadVarId = registerVar(phys_vars, "reload_progress", 0.0)
  human_weap_anim__throwProgressVarId = registerVar(phys_vars, "throw_progress", 0.0)


[es(no_order)]
def human_weap_reset_reload_progress_es(info : ParallelUpdateFrameDelayed;
                                        var gun_anim__reloadProgress : float&)
  gun_anim__reloadProgress = 0.0


[es(after=human_weap_reset_reload_progress_es, before=human_gun_attach_es)]
def human_weap_anim_es(info : ParallelUpdateFrameDelayed;
                       human_weap__currentGunSlot : int;
                       human_weap__gunEids : EidList;
                       human_weap__gunMods : Array;
                       human_weap_anim__boltActionVarId : int;
                       human_weap_anim__reloadVarId : int;
                       human_weap_anim__throwProgressVarId : int;
                       human_net_phys : HumanActor;
                       human_weap__reloadGunEid : ecs::EntityId;
                       human_weap__singleReload : bool;
                       human_weap__throwMode : bool;
                       human_weap__reloadAtTime : float;
                       human_weap__reloadStartTime : float;
                       human_weap__weapModActivateStartTime : float;
                       human_weap__weapModActivateFinishTime : float;
                       grenadeThrowProgress : float;
                       entity_mods__reloadMult : float = 1.0;
                       animchar__visible : bool = true;
                       var phys_vars : PhysVars;
                       var reloadProgress : float&;
                       var boltActionProgress : float&;
                       var isGunManualLoadMode : bool&)
  if !animchar__visible
    return
  let curSlot = (human_weap__throwMode
                ? int(HUWeaponSlots EWS_GRENADE)
                : human_weap__currentGunSlot)
  if curSlot < 0
    return

  var isReload = false
  reloadProgress = 0.0
  var weapModActivateProgress = -1.0
  if !human_weap__throwMode
    if info.curTime >= human_weap__reloadStartTime && info.curTime <= human_weap__reloadAtTime
      reloadProgress = cvt(info.curTime, human_weap__reloadStartTime, human_weap__reloadAtTime, 0.0, 1.0)
      isReload = true

    if human_weap__weapModActivateStartTime > 0.0
      weapModActivateProgress = cvt(info.curTime,
                                    human_weap__weapModActivateStartTime,
                                    human_weap__weapModActivateFinishTime, 0.0, 1.0)

  var physReloadProgress = reloadProgress
  var gunAnimReloadProgress = reloadProgress
  var singleReloadProgress = 0.0
  var singleReloadState = GunSingleReloadState SINGLE_RELOAD_DISABLED

  if human_weap__singleReload && reloadProgress > 0.0
    query(human_weap__gunEids[curSlot]) <| $ [es] (gun_anim__reloadStyle : int;
                                                   single_reload__prepareTime : float = 0.1;
                                                   single_reload__loopTime : float = 1.0;
                                                   single_reload__postTime : float = 0.1;
                                                   single_reload__jammedPostTime : float = 1.0)
      var prepareTime = single_reload__prepareTime
      var loopTime = single_reload__loopTime
      var postTime = single_reload__postTime

      if gun_anim__reloadStyle == int(GunReloadStyle RELOAD_STYLE_JAMMED)
        postTime = single_reload__jammedPostTime

      prepareTime *= entity_mods__reloadMult
      loopTime *= entity_mods__reloadMult
      postTime *= entity_mods__reloadMult
      let loopStart = human_weap__reloadStartTime + prepareTime
      let loopEnd = human_weap__reloadAtTime - postTime

      if info.curTime < loopStart
        singleReloadProgress = cvt(info.curTime, human_weap__reloadStartTime, loopStart, 0.0, 1.0)
        singleReloadState = GunSingleReloadState SINGLE_RELOAD_PREPARE
        physReloadProgress = singleReloadProgress * 0.5
      elif info.curTime >= loopEnd
        singleReloadProgress = cvt(info.curTime, loopEnd, human_weap__reloadAtTime, 0.0, 1.0)
        singleReloadState = GunSingleReloadState SINGLE_RELOAD_POST
        physReloadProgress = 0.5 + singleReloadProgress * 0.5
      else
        let loop = safediv(info.curTime - loopStart, loopTime)
        singleReloadProgress = loop - floor(loop)
        singleReloadState = GunSingleReloadState SINGLE_RELOAD_LOOP
        physReloadProgress = 0.5

    gunAnimReloadProgress = 0.0

  if human_weap_anim__reloadVarId >= 0
    phys_vars |> setVar(human_weap_anim__reloadVarId, physReloadProgress)

  var weaponModIsActive = false
  let gunMods = get_ecs_EidList(human_weap__gunMods[curSlot])
  var weaponModEid = INVALID_ENTITY_ID

  for gunModEid in *gunMods
    query(gunModEid) <| $ [es] (weapon_mod__active : bool)
      weaponModEid = gunModEid
      weaponModIsActive = weapon_mod__active

  query(human_weap__gunEids[curSlot]) <| $ [es] (gun : Gun const?;
                                                 grenade_thrower : GrenadeThrower const?;
                                                 grenade_thrower__projectileEntity : ecs::EntityId const?;
                                                 var grenade_thrower__throwProgress : float?;
                                                 var gun_anim__reloadProgress : float&;
                                                 var gun_anim__singleReloadState : int&;
                                                 var gun_anim__singleReloadProgress : float&;
                                                 var gun_anim__weapModEid : ecs::EntityId?;
                                                 var gun_anim__weapModState : int?)
    if gun_anim__weapModEid != null
      let active = (weaponModIsActive || (weapModActivateProgress >= 0.0))
      *gun_anim__weapModEid = active ? weaponModEid : INVALID_ENTITY_ID

    if weapModActivateProgress >= 0.0
      gun_anim__reloadProgress = weapModActivateProgress
      if gun_anim__weapModState != null
        *gun_anim__weapModState = (weaponModIsActive
                                     ? int(GunWeapModState WEAP_MOD_STATE_DEACTIVATE)
                                     : int(GunWeapModState WEAP_MOD_STATE_ACTIVATE))
    else
      gun_anim__reloadProgress = gunAnimReloadProgress
      if gun_anim__weapModState != null
        let reload = isReload && (human_weap__gunEids[curSlot] != human_weap__reloadGunEid)
        *gun_anim__weapModState = (reload
                                     ? int(GunWeapModState WEAP_MOD_STATE_RELOAD)
                                     : int(GunWeapModState WEAP_MOD_STATE_NONE))

    gun_anim__singleReloadState = int(singleReloadState)
    gun_anim__singleReloadProgress = singleReloadProgress

    if gun != null
      if human_weap_anim__boltActionVarId >= 0
        let boltAction = *gun |> gun_lerpBoltActionTime(info.curTime)
        phys_vars |> setVar(human_weap_anim__boltActionVarId, boltAction)
        isGunManualLoadMode = gun_getFiringMode(*gun, int(gun.firingModeIndex)).modeType == EFiringModeType EFM_MANUAL
        boltActionProgress = boltAction

    if !human_weap__throwMode && grenade_thrower__projectileEntity != null
      let weaponSlot = determine_current_weapon_slot(info.curTime, human_net_phys)
      var visible = getRW_bool(*grenade_thrower__projectileEntity, "gun__visible")
      if visible != null
        *visible = (weaponSlot == HUWeaponSlots EWS_GRENADE)

    if grenade_thrower != null && human_weap_anim__throwProgressVarId >= 0
      let gtp = ((human_net_phys.role == NetRole ROLE_REMOTELY_CONTROLLED_SHADOW)
                ? grenadeThrowProgress
                : calc_grenade_throw_progress(*grenade_thrower, info.curTime))
      phys_vars |> setVar(human_weap_anim__throwProgressVarId, gtp)
      if grenade_thrower__throwProgress != null
        *grenade_thrower__throwProgress = gtp
