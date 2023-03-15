require daslib/enum_trait
require ecs
require ecs.common
require app
require EnlistedNet
require inventory
require game.utils.net_utils
require game.es.events
require game.events_game
require common_shooter.events_common_shooter
require common_shooter.es.human_weap_common
require common_shooter.es.human.human_reload_common
require EnlistedHuman
require EnlistedActor
require EnlistedWeapon
require DagorSystem
require DagorMath
require DagorRandom
require DaWeaponProps
require Gun
require HumanPhys
require enlisted.events_enlisted


def interrupt_reload_immediately_impl(human_weap__reloadStartTime : float;
                                      var human_weap__reloadFinishTime : float&;
                                      var human_weap__reloadAtTime : float&;
                                      var human_weap__isReloadRequested : bool&)
  human_weap__reloadFinishTime = human_weap__reloadStartTime
  human_weap__reloadAtTime = human_weap__reloadStartTime
  human_weap__isReloadRequested = false


[es]
def human_weap_interrupt_reload_immediately_es(evt : CmdInterruptReloadImmediately;
                                               human_weap__reloadStartTime : float;
                                               var human_weap__reloadFinishTime : float&;
                                               var human_weap__reloadAtTime : float&;
                                               var human_weap__isReloadRequested : bool&)
  interrupt_reload_immediately_impl(human_weap__reloadStartTime,
                                    human_weap__reloadFinishTime,
                                    human_weap__reloadAtTime,
                                    human_weap__isReloadRequested)


def interrupt_single_reload(gun_eid : ecs::EntityId;
                            at_time : float;
                            entity_mods__reloadMult : float;
                            human_weap__reloadStartTime : float;
                            var human_weap__reloadFinishTime : float&;
                            var human_weap__reloadAtTime : float&;
                            var human_weap__isReloadRequested : bool&;
                            immediately : bool = false)
  var res = false
  query(gun_eid) <| $ [es] (gun_anim__reloadStyle : int;
                            single_reload__prepareTime : float = 0.1;
                            single_reload__loopTime : float = 1.0;
                            single_reload__postTime : float = 0.1;
                            single_reload__jammedPostTime : float = 1.0;
                            gun__reloadFinishMult : float = 0.9f;
                            gun__ammo : int = 0)
    if gun__ammo <= 0
      return

    if immediately
      interrupt_reload_immediately_impl(human_weap__reloadStartTime,
                                        human_weap__reloadFinishTime,
                                        human_weap__reloadAtTime,
                                        human_weap__isReloadRequested)
      res = true
      return

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
    if at_time >= loopStart && at_time < loopEnd
      let finishMult = gun__reloadFinishMult
      let loopCur = at_time - loopStart
      let loop = safediv(loopCur, loopTime)
      let restTime = (ceil(loop) - loop) * loopTime + postTime
      human_weap__reloadFinishTime = at_time + restTime * finishMult
      human_weap__reloadAtTime = at_time + restTime
      res = true

  return res


[es(after=gun_init_es)]
def unload_ammo_es(evt : CmdUnloadAmmo;
                   gun__shell_prop_ids : GunShellPropIds&;
                   var gun__ammo : int&;
                   var gun__ammoToReloadCount : int&;
                   var gun__curShellId : ShellPropIds&;
                   var gun : Gun&;
                   var gun__manuallyUnloaded : bool&)
  gun__ammo = 0
  gun__ammoToReloadCount = 0
  gun__curShellId = gun__shell_prop_ids[0]
  gun.curState.loaded = false
  gun__manuallyUnloaded = evt.unloadManually


[es]
def load_ammo_es(evt : CmdLoadAmmo;
                 var gun : Gun;
                 var gun__ammo : int&;
                 var gun__manuallyUnloaded : bool&)
  gun__ammo = evt.ammoNum
  gun.curState.loaded = (gun__ammo > 0)
  gun__manuallyUnloaded = false


[es]
def human_weap_interrupt_single_reload_es(info : ParallelUpdateFrameDelayed;
                                          human_attached_gun__attachedGunEid : ecs::EntityId;
                                          human_weap__currentGunEid : ecs::EntityId;
                                          entity_mods__reloadMult : float = 1.0;
                                          human_weap__singleReload : bool;
                                          human_net_phys : HumanActor&;
                                          human_weap__reloadStartTime : float;
                                          var human_weap__reloadFinishTime : float&;
                                          var human_weap__reloadAtTime : float&;
                                          var human_weap__isReloadRequested : bool&)
  if !human_weap__singleReload
    return

  let isShootControlBit = human_net_phys.phys.appliedCT |> is_control_bit_set(HumanPhysControlType HCT_SHOOT)
  if human_weap__reloadFinishTime > info.curTime && isShootControlBit
    let gunEid = (human_attached_gun__attachedGunEid != INVALID_ENTITY_ID
                 ? human_attached_gun__attachedGunEid
                 : human_weap__currentGunEid)
    if gunEid != INVALID_ENTITY_ID
      let immediately = has(gunEid, "reload__shootImmediatelyInterruptSingleReload")
      interrupt_single_reload(gunEid, info.curTime,
                              entity_mods__reloadMult, human_weap__reloadStartTime,
                              human_weap__reloadFinishTime, human_weap__reloadAtTime,
                              human_weap__isReloadRequested, immediately)


struct GunReloadData
  reloadStyle : GunReloadStyle
  prereq : bool
  reloadTime : float


[es(tag=server)]
def human_weap_request_reload_es(evt : CmdRequestReload;
                                 eid : ecs::EntityId;
                                 itemContainer : ecs::EidList;
                                 human_weap__infiniteAmmoHolders : bool;
                                 var human_weap__reloadGunEid : ecs::EntityId&;
                                 var human_weap__reloadAtTime : float&;
                                 var human_weap__reloadFinishTime : float&;
                                 var human_weap__reloadStartTime : float&;
                                 var human_weap__reloadMode : int&;
                                 var human_weap__singleReload : bool&;
                                 var human_weap__singleReloadAmmoCount : int&;
                                 var human_weap__reloadPrevTime : float&;
                                 var human_weap__isReloadRequested : bool&;
                                 var human_weap__isDualMagReload : bool&;
                                 entity_mods__jamChanceMult : float = 1.0;
                                 entity_mods__reloadMult : float = 1.0)
  let atTime = evt.atTime
  let gunEid = evt.gunEid

  if !human_weap_can_reload(eid, gunEid)
    return

  if human_weap__reloadAtTime > atTime
    if human_weap__singleReload
      interrupt_single_reload(gunEid, atTime,
                              entity_mods__reloadMult, human_weap__reloadStartTime,
                              human_weap__reloadFinishTime, human_weap__reloadAtTime,
                              human_weap__isReloadRequested)
    return

  query(gunEid) <| $ [es] (gun__ammo : int;
                           gun__maxAmmo : int;
                           gun__reloadTime : float;
                           gun__jammedReloadTime : float = -1.0;
                           gun__altReloadTime : float = -1.0;
                           gun__altJammedReloadTime : float = -1.0;
                           gun__dualMagReloadTime : float = -1.0;
                           gun__jamChance : float = 0.0;
                           gun__reloadFinishMult : float = 0.9;
                           gun__isDualMagReady : bool = false;
                           var gun__ammoOnSwitch : int&;
                           var gun__ammoToReloadCount : int&;
                           var gun_anim__reloadStyle : int&)
    // Do not reload full ammo
    if gun__ammo >= gun__maxAmmo && gun__ammo > 0
      return

    human_weap__reloadMode = int(human_weap__infiniteAmmoHolders ? ReloadAmmoMode INFINITE : ReloadAmmoMode CONSUME)
    if human_weap__infiniteAmmoHolders && gun__ammoOnSwitch == 0
      // If the player switched, while having an empty magazine, consume, so that the player can't easily exploit infinite ammo mode
      gun__ammoOnSwitch = gun__maxAmmo
      human_weap__reloadMode = int(ReloadAmmoMode CONSUME)

    find_ammo_for_gun(gunEid, itemContainer, INVALID_ITEM_ID, gun__ammo) <| $(ammoForGun : AmmoItemForGunResult)
      if ammoForGun.itemIndex < 0
        return

      gun_anim__reloadStyle = int(GunReloadStyle RELOAD_STYLE_SIMPLE)
      let isDualMagReload = (gun__isDualMagReady && gun__ammo == 0)

      var reloadTime = 0.0
      if !ammoForGun.singleReload
        let haveAmmoInChamber = gun__ammo > 0 || get_human_weap_force_alt()
        let shouldJam = (gfrnd() < (gun__jamChance * entity_mods__jamChanceMult)) || get_human_weap_force_jam()

        let gunReload = [[GunReloadData[typeinfo(enum_length type<GunReloadStyle>)]
          [[GunReloadData reloadStyle=GunReloadStyle RELOAD_STYLE_DUAL_MAG,
                          prereq=isDualMagReload,
                          reloadTime=gun__dualMagReloadTime]];
          [[GunReloadData reloadStyle=GunReloadStyle RELOAD_STYLE_ALT_JAMMED,
                          prereq=(haveAmmoInChamber && shouldJam),
                          reloadTime=gun__altJammedReloadTime]];
          [[GunReloadData reloadStyle=GunReloadStyle RELOAD_STYLE_ALT,
                          prereq=haveAmmoInChamber,
                          reloadTime=gun__altReloadTime]];
          [[GunReloadData reloadStyle=GunReloadStyle RELOAD_STYLE_JAMMED,
                          prereq=shouldJam,
                          reloadTime=gun__jammedReloadTime]];
          [[GunReloadData reloadStyle=GunReloadStyle RELOAD_STYLE_SIMPLE,
                          prereq=true,
                          reloadTime=gun__reloadTime]]]]

        for r in gunReload
          if r.prereq && (r.reloadTime >= 0.0)
            reloadTime = r.reloadTime
            gun_anim__reloadStyle = int(r.reloadStyle)
            break
      else
        query(gunEid) <| $ [es] (single_reload__prepareTime : float = 0.1;
                                 single_reload__loopTime : float = 1.0;
                                 single_reload__postTime : float = 0.1;
                                 single_reload__jammedPostTime : float = -1.0)
          var postTime = single_reload__postTime
          let shouldJam = gfrnd() < gun__jamChance * entity_mods__jamChanceMult || get_human_weap_force_jam()
          if single_reload__jammedPostTime >= 0.0 && shouldJam
            gun_anim__reloadStyle = int(GunReloadStyle RELOAD_STYLE_JAMMED)
            postTime = single_reload__jammedPostTime

          let singleReloadAmmoCount = float(ammoForGun.singleReloadAmmoCount)
          let maxReqBullets = int(ceil(safediv(float(gun__maxAmmo - gun__ammo), singleReloadAmmoCount)))
          reloadTime = single_reload__prepareTime + single_reload__loopTime * float(maxReqBullets) + postTime

      reloadTime *= entity_mods__reloadMult
      human_weap__reloadGunEid = gunEid
      human_weap__reloadAtTime = atTime + reloadTime
      human_weap__reloadFinishTime = atTime + reloadTime * gun__reloadFinishMult
      human_weap__reloadStartTime = atTime
      human_weap__isDualMagReload = isDualMagReload
      human_weap__singleReload = ammoForGun.singleReload
      human_weap__singleReloadAmmoCount = ammoForGun.singleReloadAmmoCount
      human_weap__reloadPrevTime = atTime
      human_weap__isReloadRequested = true
      gun__ammoToReloadCount = ammoForGun.ammoCount

      sendEvent(eid, [[EventWeapOnReload]])


[es(tag=server, no_order, track=gun__ammo, on_appear)]
def server_update_is_ammo_loaded_es(evt : ecs::Event;
                                    gun__ammo : int;
                                    var gun__isAmmoLoaded : bool&)
  // gun.ammo is sensitive information that's available only to gun owner, however,
  // everyone needs to know if some gun is at least loaded with something or not. That's in
  // order to display chambered ammo for remotely controlled shadow entities correctly.
  // gun.isAmmoLoaded is used just for that and it's visible to anyone.
  gun__isAmmoLoaded = (gun__ammo > 0)


[es(tag=gameClient, after=gun_init_es, on_appear)]
def init_gun_cur_shell_id_es(evt : ecs::Event;
                             gun__shell_prop_ids : GunShellPropIds;
                             shell_props : ShellPropIds;
                             var gun__curShellId : ShellPropIds&)
  gun__curShellId = (int(shell_props.shellId) >= 0
                       ? shell_props
                       : gun__shell_prop_ids[0])


[es(tag=gameClient, after=gun_init_es, track=gun__isAmmoLoaded, on_appear)]
def client_track_ammo_holder_es(evt : ecs::Event;
                                gun__owner : ecs::EntityId;
                                gun__ammo : int;
                                gun__isAmmoLoaded : bool;
                                var gun : Gun&)
  var isRemoteShadow = false
  query(gun__owner) <| $ [es] (human_net_phys : HumanActor)
    isRemoteShadow = human_net_phys.role == NetRole ROLE_REMOTELY_CONTROLLED_SHADOW
  // gun__ammo is updating locally only for controlled player, for others it can came only by replication from the server
  // but we filter gun__ammo replication to not spectated players, because it saves some net traffic
  // gun__isAmmoLoaded is another component, replicated for every player, it only shows that gun is not empty
  // we don't use gun__isAmmoLoaded for local (!isRemoteShadow) player because it's value outdated compared to local ammo counter
  if isRemoteShadow
    gun.curState.loaded = gun__isAmmoLoaded
  else
    // Set loaded on creation
    gun.curState.loaded = (gun__ammo > 0)


[es(before=human_weap_update_es)]
def human_weap_reload_es(info : ParallelUpdateFrameDelayed;
                         eid : ecs::EntityId;
                         human_weap__currentGunEid : ecs::EntityId;
                         var human_weap__reloadAtTime : float&;
                         var human_weap__reloadStartTime : float&;
                         var human_weap__reloadFinishTime : float&;
                         var human_weap__reloadDelayTime : float&)
  let canReloadGun = human_weap_can_reload(eid, human_weap__currentGunEid)
  if !canReloadGun && human_weap__reloadFinishTime > info.curTime
    human_weap__reloadDelayTime += info.dt
  elif human_weap__reloadDelayTime > 0.0
    human_weap__reloadAtTime = human_weap__reloadAtTime + human_weap__reloadDelayTime
    human_weap__reloadStartTime = human_weap__reloadStartTime + human_weap__reloadDelayTime
    human_weap__reloadFinishTime = human_weap__reloadFinishTime + human_weap__reloadDelayTime
    human_weap__reloadDelayTime = 0.0


// Drop reload progress when weapon is switched.
[es(tag=server)]
def human_weap_reload_on_select_es(evt : EventOnSelectWeap;
                                   var human_weap__reloadAtTime : float&;
                                   var human_weap__reloadFinishTime : float&;
                                   var human_weap__reloadStartTime : float&;
                                   var human_weap__isReloadRequested : bool&)
  human_weap__reloadAtTime = -1.0
  human_weap__reloadFinishTime = -1.0
  human_weap__reloadStartTime = -1.0
  human_weap__isReloadRequested = false


[es(tag=server, track=human_net_phys__isClimbing)]
def human_weap_reload_interrupt_on_climbing(evt : Event; eid : EntityId; human_net_phys__isClimbing : bool)
  if human_net_phys__isClimbing
    sendEvent(eid, [[CmdInterruptReloadImmediately]])
