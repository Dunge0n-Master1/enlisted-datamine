require ecs
require app
require DagorMath
require common_shooter.es.gun_anim_common
require common_shooter.events_common_shooter
require common_shooter.es.human.human_reload_common
require common_shooter.es.human.gun_reload_common
require common_shooter.es.human_weap_common
require enlisted.events_enlisted



def gun_reload_try_enable_state(gun_eid : EntityId; state : int; length : float; can_loop : bool = false)
  var isEnabled = false
  query(gun_eid) <| $ [es] (gun_reload__isReloading : bool;
                            var gun_reload__stateStartTime : float&;
                            var gun_reload__stateEndTime : float&;
                            var gun_reload__state : int&;
                            var gun_reload__isNextStateSelected : bool&)
    if !gun_reload__isReloading || gun_reload__isNextStateSelected || gun_reload__state > state || (gun_reload__state == state && !can_loop)
      return

    let currentTime = get_sync_time()
    gun_reload__stateStartTime = currentTime
    gun_reload__stateEndTime = currentTime + length
    gun_reload__state = state
    isEnabled = true
    gun_reload__isNextStateSelected = true

  return isEnabled


[es]
def gun_reload_reset_next_state_selected(evt : CmdStartNextReloadState;
                                         var gun_reload__isNextStateSelected : bool&)
  gun_reload__isNextStateSelected = false


[es(after=gun_reload_reset_next_state_selected)]
def gun_reload_state_prepare(evt : CmdStartNextReloadState;
                             eid : EntityId;
                             gun__owner : EntityId;
                             gun_reload_state__prepareTime : float)
  let reloadSpeedMult = get_float(gun__owner, "entity_mods__reloadMult") ?? 1.0
  let stateTime = gun_reload_state__prepareTime * reloadSpeedMult
  gun_reload_try_enable_state(eid, int(GunReloadState PREPARE), stateTime)


[es(after=gun_reload_state_prepare)]
def gun_reload_state_bullet_multiple_load(evt : CmdStartNextReloadState;
                                          eid : EntityId;
                                          gun_reload__state : int;
                                          gun__owner : EntityId;
                                          gun_reload_state__bulletMultipleCount : int)
  if gun_reload__state == int(GunReloadState BULLET_MULTIPLE)
    query(gun__owner) <| $ [es] (var itemContainer : EidList&)
      reload_with_bullets(gun__owner, itemContainer, eid, gun_reload_state__bulletMultipleCount, ReloadAmmoMode CONSUME)


[es(after=gun_reload_state_bullet_multiple_load)]
def gun_reload_state_bullet_multiple(evt : CmdStartNextReloadState;
                                     eid : EntityId;
                                     gun__owner : EntityId;
                                     gun__ammo : int;
                                     gun__maxAmmo : int;
                                     gun__ammoHolderIds : IntList;
                                     gun__wishAmmoItemType : int;
                                     gun_reload__shouldInterrupt : bool;
                                     gun_reload_state__bulletMultipleTime : float;
                                     gun_reload_state__bulletMultipleCount : int)
  assume bulletsToInsert = gun_reload_state__bulletMultipleCount
  let hasCapacityToInsert = gun__maxAmmo - gun__ammo >= bulletsToInsert
  let hasEnoughAmmo = has_holder_with_enough_bullets(gun__owner, bulletsToInsert, gun__wishAmmoItemType, gun__ammoHolderIds, gun__maxAmmo)
  if hasCapacityToInsert && hasEnoughAmmo && !gun_reload__shouldInterrupt
    let reloadSpeedMult = get_float(gun__owner, "entity_mods__reloadMult") ?? 1.0
    let stateTime = gun_reload_state__bulletMultipleTime * reloadSpeedMult
    gun_reload_try_enable_state(eid, int(GunReloadState BULLET_MULTIPLE), stateTime, true)


[es(after=gun_reload_state_bullet_multiple)]
def gun_reload_state_bullet_single_load(evt : CmdStartNextReloadState;
                                        eid : EntityId;
                                        gun__owner : EntityId;
                                        gun_reload__state : int)
  if gun_reload__state == int(GunReloadState BULLET_SINGLE)
    query(gun__owner) <| $ [es] (var itemContainer : EidList&)
      reload_with_bullets(gun__owner, itemContainer, eid, 1, ReloadAmmoMode CONSUME)


[es(after=gun_reload_state_bullet_single_load)]
def gun_reload_state_bullet_single(evt : CmdStartNextReloadState;
                                   eid : EntityId;
                                   gun__owner : EntityId;
                                   gun__ammo : int;
                                   gun__maxAmmo : int;
                                   gun__ammoHolderIds : IntList;
                                   gun__wishAmmoItemType : int;
                                   gun_reload__shouldInterrupt : bool;
                                   gun_reload_state__bulletSingleTime : float)
  let bulletsToInsert = 1
  let hasCapacityToInsert = gun__maxAmmo - gun__ammo >= bulletsToInsert
  let hasEnoughAmmo = has_holder_with_enough_bullets(gun__owner, bulletsToInsert, gun__wishAmmoItemType, gun__ammoHolderIds, gun__maxAmmo)
  if hasCapacityToInsert && hasEnoughAmmo && !gun_reload__shouldInterrupt
    let reloadSpeedMult = get_float(gun__owner, "entity_mods__reloadMult") ?? 1.0
    let stateTime = gun_reload_state__bulletSingleTime * reloadSpeedMult
    gun_reload_try_enable_state(eid, int(GunReloadState BULLET_SINGLE), stateTime, true)


[es(after=gun_reload_state_post_reset_anim_state)]
def gun_reload_state_post(evt : CmdStartNextReloadState;
                          eid : EntityId;
                          gun__owner : EntityId;
                          gun_reload_state__postTime : float)
  let reloadSpeedMult = get_float(gun__owner, "entity_mods__reloadMult") ?? 1.0
  let stateTime = gun_reload_state__postTime * reloadSpeedMult
  gun_reload_try_enable_state(eid, int(GunReloadState POST), stateTime)


def gun_reload_finish(eid)
  query(eid) <| $ [es] (var gun_reload__isReloading : bool&;
                        var gun_reload__shouldInterrupt : bool&;
                        var gun_reload__state : int&)
    gun_reload__shouldInterrupt = false
    gun_reload__state = int(GunReloadState NONE)
    gun_reload__isReloading = false


[es(after=gun_reload_state_post)]
def gun_reload_state_finished(evt : CmdStartNextReloadState;
                              eid : EntityId;
                              gun_reload__isNextStateSelected : bool)
  if gun_reload__isNextStateSelected
    return

  gun_reload_finish(eid)




[es(after=human_weap_anim_es, before=gun_anim_updater_es, REQUIRE=multiStateReloadSystem)]
def gun_reload_calc_progress(info : ParallelUpdateFrameDelayed;
                             eid : EntityId;
                             gun_reload__state : int;
                             gun_reload__stateStartTime : float;
                             gun_reload__stateEndTime : float;
                             var gun_anim__reloadProgress : float&)
  if gun_reload__state == int(GunReloadState NONE)
    gun_anim__reloadProgress = 0.0
    return

  gun_anim__reloadProgress = cvt(info.curTime,
                                 gun_reload__stateStartTime,
                                 gun_reload__stateEndTime,
                                 0.0, 1.0)

  if info.curTime > gun_reload__stateEndTime
    sendEvent(eid, [[CmdStartNextReloadState]])


[es(tag=server)]
def on_human_requested_reload(evt : CmdRequestReload;
                              eid : EntityId)
  let gunEid = evt.gunEid

  var shouldExit = true
  query(gunEid) <| $ [es(REQUIRE=multiStateReloadSystem)] ()
    shouldExit = false
  if shouldExit
    return

  if !human_weap_can_reload(eid, gunEid)
    return

  query(gunEid) <| $ [es] (gun__ammo : int;
                           gun__maxAmmo : int;
                           gun__wishAmmoItemType : int;
                           gun__ammoHolderIds : IntList;
                           var gun_reload__isReloading : bool&)
    // TODO: after reload started we are most likely to get another CmdRequestReload on the next frame
    // we need to redo this somehow so that it reset only after another press
    // if gun_reload__isReloading
    //   // interrupt reload if possible
    //   gun_reload__shouldInterrupt = true
    //   return

    // do not reload full ammo
    if gun__ammo >= gun__maxAmmo && gun__ammo > 0
      return

    // do we have anything to reload with?
    // TODO: is this enough? might need some more checking to avoid reload animatinos without actual reload
    if !has_holder_with_enough_bullets(eid, 1, gun__wishAmmoItemType, gun__ammoHolderIds, gun__maxAmmo)
      return

    // start actual reload
    gun_reload__isReloading = true
    sendEvent(eid, [[EventHumanStartedReload]])


[es(track=gun_reload__isReloading)]
def start_reload(evt : Event; eid : EntityId; gun_reload__isReloading : bool)
  if gun_reload__isReloading
    sendEvent(eid, [[CmdStartNextReloadState]])


[es(tag=gameClient, track=gun_reload__shouldInterrupt)]
def gun_reload_ignore_interrupt_when_not_reloading(evt : Event;
                                                   gun_reload__isReloading : bool;
                                                   var gun_reload__shouldInterrupt : bool&)
  if !gun_reload__isReloading
    gun_reload__shouldInterrupt = false
